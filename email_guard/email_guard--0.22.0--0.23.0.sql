-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('bmoar.com'),
('california.edu.pl'),
('cosdas.com'),
('dwseal.com'),
('emailhook.site'),
('epetsoft.com'),
('fanymail.com'),
('firemail.com.br'),
('jbsze.com'),
('kayilo.com'),
('mailshun.com'),
('onldm.net'),
('seduck.com'),
('sendgrid.ovh'),
('strayhood.org'),
('tempmailto.com'),
('urgentmail.ovh'),
('vtmpj.net')
ON CONFLICT (domain) DO NOTHING;
