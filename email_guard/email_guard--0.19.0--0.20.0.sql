-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('dumbass.nl'),
('emailboxer.one'),
('exahut.com'),
('exespay.com'),
('fabaos.com'),
('fun4k.com'),
('jsncos.com'),
('laoia.com'),
('muncloud.com'),
('noexpire.top'),
('phmail.site'),
('smkanba.com')
ON CONFLICT (domain) DO NOTHING;
