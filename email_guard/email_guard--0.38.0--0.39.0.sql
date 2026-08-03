-- Auto-generated upgrade to embed latest disposable domain data

-- Source: https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/main/disposable_email_blocklist.conf

insert into @extschema@.disposable_email_domains(domain) values
('aihubtools.space'),
('cqwbn.com'),
('fbfbs.lol'),
('frive.site'),
('fxt.ink'),
('hualabtech.com'),
('hygle.net'),
('ilcvn.cn'),
('melbourne.edu.pl'),
('mianfeibuluo.com'),
('modolku.store'),
('nabilalo.bond'),
('saddope.lol'),
('skyhopenb.shop'),
('spacexyz.space'),
('sydney.edu.pl'),
('tokyo.edu.pl'),
('vrjxk.com'),
('weeline.fun'),
('wmksuhd.cn'),
('wrgee.com'),
('xswl.xyz')
ON CONFLICT (domain) DO NOTHING;
