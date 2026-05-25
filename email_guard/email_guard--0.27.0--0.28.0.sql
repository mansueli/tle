-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('acanok.com'),
('ameady.com'),
('bitmah.com'),
('bittnex.com'),
('dardr.com'),
('gebrauchtwarencenter.com'),
('getasail.com'),
('gzeos.com'),
('hdiscord.xyz'),
('hidevak.com'),
('hilostar.com'),
('homvela.com'),
('itquoted.com'),
('nghienplus.store'),
('noyavip.com'),
('nriza.com'),
('uki.io.vn')
ON CONFLICT (domain) DO NOTHING;
