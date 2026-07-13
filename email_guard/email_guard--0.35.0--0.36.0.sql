-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('ahmadfamily.net'),
('autommo.net'),
('diplom-voronesh.ru'),
('dvaren.online'),
('edshol.net'),
('ezimb.com'),
('gentleinfopath.com'),
('habitnestguide.com'),
('higogoya.com'),
('homewiseleaf.com'),
('jojomedia.store'),
('jzlvoei.cn'),
('mtnewtoy.us'),
('nexarsh.store'),
('productmm.shop'),
('ronghsng.buzz'),
('samaltour.site'),
('skyhope666.icu'),
('thueotp.net'),
('tmail.lt'),
('tmail.mx'),
('trieuhao.site'),
('twskyhope.top'),
('xlcsh.icu'),
('zauxpbp.cn')
ON CONFLICT (domain) DO NOTHING;
