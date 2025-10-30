-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('inwagit.com'),
('muonwhila.com'),
('mycreativeinbox.com'),
('suftwari.com')
ON CONFLICT (domain) DO NOTHING;
