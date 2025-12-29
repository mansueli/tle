-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

delete from @extschema@.disposable_email_domains
where domain in (
  'gmal.com'
);

insert into @extschema@.disposable_email_domains(domain) values
('aikunkun.com'),
('airsworld.net'),
('atomicmail.io'),
('bipochub.com'),
('chuan.info'),
('comfythings.com'),
('feralrex.com'),
('gamepec.com'),
('ilove4.skin'),
('junk4.me'),
('love4.skin'),
('mailmask.cc'),
('merumart.com'),
('minuteinbox.com'),
('moondyal.com'),
('moonfee.com'),
('okcdeals.com'),
('zenthranet.com')
ON CONFLICT (domain) DO NOTHING;
