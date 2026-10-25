/*
HealthConnect Rwanda — Week 6 Healthcare Analytics SQL Starter
Track: Data Analytics | PostgreSQL


*/

-- 0. Inspect tables/columns in PostgreSQL
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog','information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 1. Patient totals
SELECT COUNT(*) AS total_registered_patients FROM patients;

-- 2. Patient counts by gender
SELECT gender, COUNT(*) AS patient_count
FROM patients GROUP BY gender ORDER BY patient_count DESC;

-- 3. Patient counts by province (adjust joins/columns to your schema)
SELECT pr.province_name, COUNT(DISTINCT p.patient_id) AS patient_count
FROM patients p
JOIN districts d ON p.district_id = d.district_id
JOIN provinces pr ON d.province_id = pr.province_id
GROUP BY pr.province_name ORDER BY patient_count DESC;

-- 4. Patients older than 65
SELECT patient_id, date_of_birth
FROM patients
WHERE date_of_birth <= CURRENT_DATE - INTERVAL '65 years';

-- 5. Patients with chronic diagnoses (confirm diagnosis taxonomy)
SELECT DISTINCT p.patient_id
FROM patients p
JOIN diagnoses dg ON dg.patient_id = p.patient_id
WHERE COALESCE(dg.is_chronic, FALSE) = TRUE;

-- 6. Patients with insurance coverage
SELECT COUNT(DISTINCT patient_id) AS insured_patients
FROM insurance_claims;

-- 7. Blood group distribution
SELECT blood_group, COUNT(*) AS patient_count
FROM patients GROUP BY blood_group ORDER BY patient_count DESC;

-- 8. Youngest and oldest patients (age from date of birth)
SELECT MIN(age_years) AS youngest_age, MAX(age_years) AS oldest_age
FROM (
  SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))::int AS age_years
  FROM patients WHERE date_of_birth IS NOT NULL
) a;

-- 9. Duplicate phone numbers
SELECT phone_number, COUNT(*) AS records
FROM patients
WHERE phone_number IS NOT NULL AND BTRIM(phone_number) <> ''
GROUP BY phone_number HAVING COUNT(*) > 1
ORDER BY records DESC;

-- 10. Average patient age
SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth)))::numeric, 1) AS average_age
FROM patients WHERE date_of_birth IS NOT NULL;

-- 11. Appointments by month
SELECT DATE_TRUNC('month', appointment_datetime)::date AS appointment_month,
       COUNT(*) AS appointment_count
FROM appointments
GROUP BY 1 ORDER BY 1;

-- 12. Busiest hospitals
SELECT hf.facility_name, COUNT(*) AS appointment_count
FROM appointments a JOIN health_facilities hf ON a.facility_id = hf.facility_id
GROUP BY hf.facility_name ORDER BY appointment_count DESC;

-- 13. Busiest departments
SELECT dep.department_name, COUNT(*) AS appointment_count
FROM appointments a JOIN departments dep ON a.department_id = dep.department_id
GROUP BY dep.department_name ORDER BY appointment_count DESC;

-- 14. Doctors with highest appointment workload
SELECT d.doctor_id, COUNT(*) AS appointment_count
FROM appointments a JOIN doctors d ON a.doctor_id = d.doctor_id
GROUP BY d.doctor_id ORDER BY appointment_count DESC;

-- 15. Referral patterns
SELECT referral_type, COUNT(*) AS referral_count
FROM referrals GROUP BY referral_type ORDER BY referral_count DESC;

-- 16. Emergency appointments
SELECT COUNT(*) AS emergency_appointments
FROM appointments WHERE LOWER(appointment_type) = 'emergency';

-- 17. Average appointments per doctor
SELECT ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT doctor_id),0), 2) AS average_appointments_per_doctor
FROM appointments WHERE doctor_id IS NOT NULL;

-- 18. Appointments by province
SELECT pr.province_name, COUNT(*) AS appointment_count
FROM appointments a
JOIN health_facilities hf ON a.facility_id = hf.facility_id
JOIN districts d ON hf.district_id = d.district_id
JOIN provinces pr ON d.province_id = pr.province_id
GROUP BY pr.province_name ORDER BY appointment_count DESC;

-- 19. Facility patient volume
SELECT hf.facility_name, COUNT(DISTINCT a.patient_id) AS unique_patients
FROM appointments a JOIN health_facilities hf ON a.facility_id = hf.facility_id
GROUP BY hf.facility_name ORDER BY unique_patients DESC;

-- 20. Peak consultation periods
SELECT EXTRACT(HOUR FROM appointment_datetime)::int AS hour_of_day,
       COUNT(*) AS appointment_count
FROM appointments GROUP BY 1 ORDER BY appointment_count DESC;

-- 21. Top diagnoses
SELECT diagnosis_name, COUNT(*) AS diagnosis_count
FROM diagnoses GROUP BY diagnosis_name ORDER BY diagnosis_count DESC LIMIT 20;

-- 22. Most requested laboratory tests
SELECT test_name, COUNT(*) AS test_count
FROM laboratory_tests GROUP BY test_name ORDER BY test_count DESC;

-- 23. Most prescribed medications
SELECT medication_name, COUNT(*) AS prescription_count
FROM prescriptions GROUP BY medication_name ORDER BY prescription_count DESC;

-- 24. Average admission duration
SELECT ROUND(AVG(discharge_datetime - admission_datetime) / INTERVAL '1 day', 2) AS avg_length_of_stay_days
FROM admissions
WHERE discharge_datetime IS NOT NULL AND admission_datetime IS NOT NULL
  AND discharge_datetime >= admission_datetime;

-- 25. Disease severity distribution
SELECT severity, COUNT(*) AS case_count
FROM diagnoses GROUP BY severity ORDER BY case_count DESC;

-- 26. Laboratory test utilization by month
SELECT DATE_TRUNC('month', test_datetime)::date AS test_month, COUNT(*) AS tests
FROM laboratory_tests GROUP BY 1 ORDER BY 1;

-- 27. Prescription trends by month
SELECT DATE_TRUNC('month', prescription_datetime)::date AS prescription_month, COUNT(*) AS prescriptions
FROM prescriptions GROUP BY 1 ORDER BY 1;

-- 28. Referral destinations
SELECT destination_facility_id, COUNT(*) AS referrals
FROM referrals GROUP BY destination_facility_id ORDER BY referrals DESC;

-- 29. Admission rate by diagnosis (define denominator explicitly; here diagnosis-linked patients)
SELECT dg.diagnosis_name,
       COUNT(DISTINCT ad.admission_id) AS admissions,
       COUNT(DISTINCT dg.patient_id) AS diagnosed_patients,
       ROUND(100.0 * COUNT(DISTINCT ad.admission_id) /
         NULLIF(COUNT(DISTINCT dg.patient_id),0), 2) AS admissions_per_100_diagnosed_patients
FROM diagnoses dg
LEFT JOIN admissions ad ON ad.patient_id = dg.patient_id
GROUP BY dg.diagnosis_name ORDER BY admissions DESC;

-- 30. Clinical workload by department
SELECT dep.department_name,
       COUNT(DISTINCT a.appointment_id) AS appointments,
       COUNT(DISTINCT dg.diagnosis_id) AS diagnoses,
       COUNT(DISTINCT lt.test_id) AS lab_tests
FROM departments dep
LEFT JOIN appointments a ON a.department_id = dep.department_id
LEFT JOIN diagnoses dg ON dg.department_id = dep.department_id
LEFT JOIN laboratory_tests lt ON lt.department_id = dep.department_id
GROUP BY dep.department_name ORDER BY appointments DESC;

-- 31. Revenue by facility
SELECT hf.facility_name, SUM(rs.revenue_amount) AS revenue
FROM revenue_summary rs JOIN health_facilities hf ON rs.facility_id = hf.facility_id
GROUP BY hf.facility_name ORDER BY revenue DESC;

-- 32. Revenue by department (only if billing has department_id)
SELECT dep.department_name, SUM(b.total_amount) AS billed_amount
FROM billing b JOIN departments dep ON b.department_id = dep.department_id
GROUP BY dep.department_name ORDER BY billed_amount DESC;

-- 33. Revenue by healthcare service (requires service_id on billing/clinical transaction)
SELECT hs.service_name, SUM(b.total_amount) AS billed_amount
FROM billing b JOIN healthcare_services hs ON b.service_id = hs.service_id
GROUP BY hs.service_name ORDER BY billed_amount DESC;

-- 34. Insurance claims by provider
SELECT ic.insurance_provider, COUNT(*) AS claims,
       SUM(ic.claim_amount) AS claimed_amount,
       SUM(CASE WHEN LOWER(ic.status) = 'approved' THEN ic.claim_amount ELSE 0 END) AS approved_amount
FROM insurance_claims ic GROUP BY ic.insurance_provider ORDER BY claimed_amount DESC;

-- 35. Outstanding bills
SELECT SUM(GREATEST(COALESCE(b.total_amount,0)-COALESCE(p.paid_amount,0),0)) AS outstanding_amount
FROM billing b LEFT JOIN (
  SELECT billing_id, SUM(payment_amount) AS paid_amount
  FROM payments GROUP BY billing_id
) p ON p.billing_id = b.billing_id;

-- 36. Average billing amount
SELECT ROUND(AVG(total_amount)::numeric,2) AS average_billing_amount FROM billing;

-- 37. Monthly revenue trend
SELECT DATE_TRUNC('month', revenue_month)::date AS month,
       SUM(revenue_amount) AS revenue
FROM revenue_summary GROUP BY 1 ORDER BY 1;

-- 38. Payment methods
SELECT payment_method, COUNT(*) AS payments, SUM(payment_amount) AS amount
FROM payments GROUP BY payment_method ORDER BY amount DESC;

-- 39. Top revenue-generating hospitals
SELECT hf.facility_name, SUM(rs.revenue_amount) AS revenue
FROM revenue_summary rs JOIN health_facilities hf ON rs.facility_id=hf.facility_id
GROUP BY hf.facility_name ORDER BY revenue DESC LIMIT 10;

-- 40. Financial performance ranking
SELECT hf.facility_name, SUM(rs.revenue_amount) AS revenue,
       RANK() OVER (ORDER BY SUM(rs.revenue_amount) DESC) AS revenue_rank
FROM revenue_summary rs JOIN health_facilities hf ON rs.facility_id=hf.facility_id
GROUP BY hf.facility_name ORDER BY revenue_rank;
