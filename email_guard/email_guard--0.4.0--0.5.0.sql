-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

delete from @extschema@.disposable_email_domains
where domain in (
  'kro.kr'
);

insert into @extschema@.disposable_email_domains(domain) values
('1337.care'),
('1nom.org'),
('2200freefonts.com'),
('azame.pw'),
('badopsec.lol'),
('burangir.com'),
('doj.one'),
('don.edu.pl'),
('dona.one'),
('dona.pw'),
('dona.rip'),
('drugsellers.com'),
('egirl.help'),
('emocan.name.tr'),
('fandoe.com'),
('fantastu.com'),
('farah.rip'),
('fbi.one'),
('hh7f.com'),
('indianahorsecouncil.org'),
('love-your.mom'),
('ma1l.duckdns.org'),
('n8.gs'),
('nyfhk.com'),
('pochtac.ru'),
('pooo.ooguy.com'),
('super.lgbt'),
('tivo.camdvr.org'),
('tshirtsavvy.com'),
('vbv.cards'),
('wacold.com'),
('wivstore.com'),
('x0q.net')
ON CONFLICT (domain) DO NOTHING;
