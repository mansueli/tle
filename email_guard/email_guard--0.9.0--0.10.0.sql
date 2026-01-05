-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

delete from @extschema@.disposable_email_domains
where domain in (
  'asso.st',
  'fr.nf',
  'infos.st'
);

insert into @extschema@.disposable_email_domains(domain) values
('24faw.com'),
('blinkmail.space'),
('cameltok.com'),
('colurmish.com'),
('cotyinc.com'),
('cucadas.com'),
('dlapiper.com'),
('donemail.my.id'),
('dubokutv.com'),
('dustbinmail.de'),
('emaxasp.com'),
('fakemailbox.tech'),
('faybetsy.com'),
('fiallaspares.com'),
('gavrom.com'),
('ghostinbox.pro'),
('heydamail.xyz'),
('heydayfm.nl'),
('hudisk.com'),
('icousd.com'),
('ihnpo.food'),
('lilpup.shop'),
('mail.gw'),
('mailjunkie.fun'),
('mailnoop.store'),
('meomo.store'),
('muetop.store'),
('mynoop.store'),
('mypup.nl'),
('nomailhero.com'),
('nooploop.store'),
('pup.yachts'),
('pupno.xyz'),
('pushcom.store'),
('quickdrop.site'),
('sihanoma.store'),
('spamfig.xyz'),
('taohucom.store'),
('tempflux.nl'),
('trashcan.email'),
('vandorp.eu'),
('xopmail.fun')
ON CONFLICT (domain) DO NOTHING;
