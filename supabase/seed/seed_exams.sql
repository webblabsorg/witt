-- Catalog Milestone A: 5 initial exams (SAT, GRE, WAEC, JAMB, IELTS)
insert into public.exams (name, slug, description, country_codes, category, scoring_type, score_min, score_max, passing_score, pricing_tier) values
  ('SAT', 'sat', 'Scholastic Assessment Test — US college admissions standardized test', '{"US"}', 'university_entrance', 'scaled', 400, 1600, null, 2),
  ('GRE', 'gre', 'Graduate Record Examinations — graduate school admissions test', '{"US","GB","CA","AU","IN"}', 'graduate', 'scaled', 260, 340, null, 3),
  ('WAEC', 'waec', 'West African Examinations Council — secondary school leaving exam', '{"NG","GH","SL","GM","LR"}', 'k12', 'band', 1, 9, 6, 1),
  ('JAMB', 'jamb', 'Joint Admissions and Matriculation Board — Nigerian university entrance exam', '{"NG"}', 'university_entrance', 'points', 0, 400, 180, 1),
  ('IELTS', 'ielts', 'International English Language Testing System — English proficiency test', '{"GB","AU","CA","NZ","US","IN"}', 'language', 'band', 0, 9, 6.5, 2);
