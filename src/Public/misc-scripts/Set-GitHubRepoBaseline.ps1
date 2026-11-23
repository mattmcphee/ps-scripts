function Set-GitHubRepoBaseline {
    <#
    .SYNOPSIS
        Applies baseline settings and branch protection to a GitHub repository.
    .DESCRIPTION
        Configures the repository's merge options and creates or updates an active
        branch ruleset for the repository's default branch. The baseline disables
        merge commits and rebase merges, enables squash merges, enables deletion of
        head branches after merge, blocks branch deletion and force-pushes, and
        requires pull requests before changes can be pushed to the default branch.
        Pull request approval threads must be resolved before merging.

        If a ruleset named "Baseline: protect default branch" already exists, this
        function updates that ruleset. Other rulesets are left unchanged.
    .PARAMETER Repository
        The GitHub repository to update. Accepts a repository name or the
        owner/repository format.
    .PARAMETER RequiredApprovals
        The number of approving reviews required for pull requests targeting the
        default branch. Valid values range from 0 through 6. The default is 0.
    .EXAMPLE
        Set-GitHubRepoBaseline -Repository "contoso/sample"

        Applies the baseline to the contoso/sample repository without requiring
        pull request approvals.
    .EXAMPLE
        Set-GitHubRepoBaseline -Repository "contoso/sample" -RequiredApprovals 2

        Applies the baseline and requires two approving reviews on pull requests
        targeting the default branch.
    .EXAMPLE
        Set-GitHubRepoBaseline -Repository "contoso/sample" -WhatIf

        Displays whether the repository baseline would be applied without making
        changes.
    .NOTES
        Requires the GitHub CLI (gh) to be installed and authenticated. The
        authenticated account must have permission to administer repository
        settings and rulesets.
    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Repository,

        [ValidateRange(0, 6)]
        [int]$RequiredApprovals = 0
    )

    # Verify repository and discover default branch
    $repoInfoJson = gh repo view $Repository `
        --json nameWithOwner,defaultBranchRef

    if ($LASTEXITCODE -ne 0 -or -not $repoInfoJson) {
        throw "Cannot access repository: $Repository"
    }

    $repoInfo = $repoInfoJson | ConvertFrom-Json
    $Repository = $repoInfo.nameWithOwner
    $branch = $repoInfo.defaultBranchRef.name

    if (-not $Repository -or -not $branch) {
        throw "Cannot determine repository name or default branch: $Repository"
    }

    $ruleName = "Baseline: protect default branch"
    $ruleset = @{
        name = $ruleName
        target = "branch"
        enforcement = "active"
        conditions = @{
            ref_name = @{
                include = @("refs/heads/$branch")
                exclude = @()
            }
        }
        rules = @(
            @{ type = "deletion" }
            @{ type = "non_fast_forward" }
            @{
                type = "pull_request"
                parameters = @{
                    required_approving_review_count = $RequiredApprovals
                    dismiss_stale_reviews_on_push = $true
                    require_code_owner_review = $false
                    require_last_push_approval = $false
                    required_review_thread_resolution = $true
                }
            }
        )
    }

    if ($PSCmdlet.ShouldProcess($Repository, "Apply baseline")) {
        $existingPages = gh api `
            "repos/$Repository/rulesets?includes_parents=false" `
            --paginate `
            --slurp

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to inspect rulesets"
        }

        $existingPages = $existingPages | ConvertFrom-Json
        $existingRuleset = $null
        foreach ($page in $existingPages) {
            foreach ($candidate in $page) {
                if ($candidate.name -eq $ruleName) {
                    $existingRuleset = $candidate
                    break
                }
            }

            if ($existingRuleset) {
                break
            }
        }

        $path = [IO.Path]::GetTempFileName()

        try {
            $json = $ruleset | ConvertTo-Json -Depth 10
            [IO.File]::WriteAllText($path, $json)

            # Repository settings
            gh repo edit $Repository `
                --enable-squash-merge `
                --enable-merge-commit=false `
                --enable-rebase-merge=false | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to configure merge settings"
            }

            gh api -X PATCH "repos/$Repository" `
                -F delete_branch_on_merge=true | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to configure branch cleanup"
            }

            if ($existingRuleset) {
                $method = "PUT"
                $endpoint = "repos/$Repository/rulesets/$($existingRuleset.id)"
                $action = "update"
            }
            else {
                $method = "POST"
                $endpoint = "repos/$Repository/rulesets"
                $action = "create"
            }

            gh api -X $method $endpoint --input $path | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to $action ruleset"
            }
        }
        finally {
            Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue
        }

        Write-Host "Repository baseline applied: $Repository"
    }
}
