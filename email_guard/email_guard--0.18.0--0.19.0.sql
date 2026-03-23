-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

delete from @extschema@.disposable_email_domains
where domain in (
  'atomicmail.io'
);

insert into @extschema@.disposable_email_domains(domain) values
('01022.hk'),
('01130.hk'),
('binsh.kro.kr'),
('ipaddressforme.com'),
('isfew.com'),
('javaemail.com'),
('lxbeta.com'),
('onbap.com'),
('paylaar.com'),
('pazard.com'),
('porsilapongo.cl'),
('qvmao.com'),
('soco7.com'),
('studyhub.edu.pl')
ON CONFLICT (domain) DO NOTHING;
