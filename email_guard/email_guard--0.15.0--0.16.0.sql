-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('bultoc.com'),
('creteanu.com'),
('dimalk.com'),
('dolofan.com'),
('firstlawyer.org'),
('free-temp-mail.eu.org'),
('hutudns.com'),
('kaoing.com'),
('minuteafter.com'),
('netoiu.com'),
('onetopclick.online'),
('sam1.eu.org'),
('tempmail.cc'),
('temporaryemail.dpdns.org')
ON CONFLICT (domain) DO NOTHING;
