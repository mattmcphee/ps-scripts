function Set-GitHubRepoBaseline {
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
