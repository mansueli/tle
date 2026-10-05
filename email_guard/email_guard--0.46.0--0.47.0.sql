-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('abowned.com'),
('aminavin.com'),
('bitproy.com'),
('caps7.com'),
('cecizie.web.id'),
('cwsgear.com'),
('dasf.bid'),
('deertees.com'),
('factoryuk.org.uk'),
('flakeian.com'),
('gcphanter.skin'),
('goodjzy.art'),
('hellodns.site'),
('hudzer.com'),
('johorulcloud.space'),
('maxxspace.com'),
('meitu.io.vn'),
('premiumcrome.site'),
('tanpony.com'),
('uvicone.in')
ON CONFLICT (domain) DO NOTHING;
