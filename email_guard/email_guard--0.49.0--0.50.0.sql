-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('agaexpress.com'),
('asdasdasd.cfd'),
('haadishah.co.uk'),
('hiringview.com'),
('hopefunder.com'),
('hyproxy.lol'),
('iconcubic.com'),
('moblha.com'),
('ofags.com'),
('playfine.com'),
('shitty.email'),
('tempmail.au'),
('tempmailnow.io'),
('tmpkit.com')
ON CONFLICT (domain) DO NOTHING;
