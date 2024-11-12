$emails = @(
    'Yew.Soh@tgalliance.com.au',
    'Vishva.Asokan@tgalliance.com.au',
    'Vincent.Killeen@tgalliance.com.au',
    'Stephen.Lim@tgalliance.com.au',
    'Philip.Reynolds@tgalliance.com.au',
    'Nishkul.Varsani@tgalliance.com.au',
    'Nibin.Raj@tgalliance.com.au',
    'Nathan.Mills@tgalliance.com.au',
    'Monica.Diaz@tgalliance.com.au',
    "Martin.O'Connor@tgalliance.com.au",
    'Liam.Spiers@tgalliance.com.au',
    'Jimmy.Lim@tgalliance.com.au',
    'Jawad.Azimi@tgalliance.com.au',
    'Giri.Kandel@tgalliance.com.au',
    'Dee.Main@tgalliance.com.au',
    'Declan.Hanley@tgalliance.com.au',
    'Cosmo.Brzusk@tgalliance.com.au',
    'Arzan.Pestonji@tgalliance.com.au',
    'Andrew.Reynalds@tgalliance.com.au',
    'Andre.Thomas@tgalliance.com.au',
    'Abdul.Qureshi@tgalliance.com.au'
)

foreach ($email in $emails) {
    Set-RemoteMailbox -Identity $email -CustomAttribute1 'bmd.com.au'
}
