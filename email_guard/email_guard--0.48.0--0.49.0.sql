-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('adsjii.xyz'),
('backyr.com'),
('bcnet.store'),
('bcnetlite.xyz'),
('betshubs.com'),
('bilingva-ca.info'),
('blockare.site'),
('bokkor1.cyou'),
('boulkfout.lol'),
('cometlumen.com'),
('damphen.org'),
('darkemail.school'),
('dustmail.net'),
('ensproxy.com'),
('forliion.com'),
('goldlicai.com'),
('juicehour.com'),
('kashre.com'),
('lucktaro.com'),
('mail-burn.com'),
('mail2me.co'),
('minafter.com'),
('monotensor.com'),
('moravita.com'),
('mototoke.click'),
('mygoo.vip'),
('neonorbitx.com'),
('ogzmail.com'),
('ooioo.tech'),
('ozvmail.com'),
('paxeluni.com'),
('proguidex.com'),
('xzcoot.com')
ON CONFLICT (domain) DO NOTHING;
