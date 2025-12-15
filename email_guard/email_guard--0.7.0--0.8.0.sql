-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('exile.my.id'),
('flyovertrees.com'),
('lnovic.com'),
('mixmail.site'),
('paxlys.com'),
('pepamail.com'),
('protectsmail.net'),
('pxlys.com'),
('yzcalo.com')
ON CONFLICT (domain) DO NOTHING;
