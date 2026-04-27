-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('aachendate.de'),
('babyeat.food'),
('chatgptmail.shop'),
('cimario.com'),
('contactbox.work'),
('deltajohnsons.com'),
('digibeast.my'),
('digibeast.store'),
('draughtier.com'),
('e-postkasten.de'),
('emailmuaqat.shop'),
('gob.re'),
('hidingmail.net'),
('hopesx.com'),
('icubik.com'),
('kakator.com'),
('mooo.com'),
('narsub.online'),
('narsub.shop'),
('route64.de'),
('sharebot.net'),
('tbr.fr.nf'),
('thebest73.shop'),
('these.cc'),
('vpn64.de'),
('ydns.eu')
ON CONFLICT (domain) DO NOTHING;
