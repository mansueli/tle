-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('99mail.us'),
('aabkmail.com'),
('aboodbab.com'),
('apple.edu.pl'),
('calmriver.info'),
('clearbeam.pro'),
('denipl.net'),
('dropons.com'),
('dulieu.io.vn'),
('elafans.com'),
('faxzu.com'),
('frostypeak.info'),
('hathitrannhien.edu.vn'),
('inreur.com'),
('itmo.edu.pl'),
('jakarta.io.vn'),
('kynninc.com'),
('lohinja.com'),
('mailer.edu.pl'),
('mailer.io.vn'),
('mailo.edu.pl'),
('mamabood.com'),
('minitts.net'),
('newdelhi.io.vn'),
('newyork.io.vn'),
('nik.edu.pl'),
('sahildash.dev'),
('sixoplus.com')
ON CONFLICT (domain) DO NOTHING;
