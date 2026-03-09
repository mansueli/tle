-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('7novels.com'),
('botnet.my.id'),
('cslua.com'),
('daerdy.com'),
('feriwor.com'),
('him6.com'),
('icmans.com'),
('keecs.com'),
('medevsa.com'),
('ostahie.com'),
('pazuric.com'),
('pckage.com')
ON CONFLICT (domain) DO NOTHING;
