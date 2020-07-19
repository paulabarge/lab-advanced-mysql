USE publications; 

-- CHALLENGE 1: TOP 3 MOST PROFITING AUTHORS USING DERIVED TABLES 

use publications;

 select a.au_id, a.au_fname, a.au_lname ,round(total_advance+total_royalty_title,0) as total_profit from (select au_id, title_id, avg(advance_per_au) as total_advance, sum(royalty_per_sale) as total_royalty_title from (
	SELECT s.title_id, 
    ta.au_id,
    t.advance, 
    ta.royaltyper, 
    round(t.advance * (ta.royaltyper / 100),0) as advance_per_au,
    t.price, s.qty, t.royalty,  round(t.price * s.qty * (t.royalty / 100 )* (ta.royaltyper / 100), 0) as royalty_per_sale

		from sales as s
		join titles as t
		on t.title_id=s.title_id
		join titleauthor as ta
		on ta.title_id=s.title_id) as step2


group by  au_id, title_id) as step3
join authors as a
on a.au_id=step3.au_id
group by au_id
order by total_profit DESC
limit 3

-- CHALLENGE 2: TOP 3 MOST PROFITING AUTHORS USING TEMPORARY TABLES 

-- Step 1: Calculate the royalty of each sale for each author
--  and the advance for each author and publication
CREATE TEMPORARY TABLE royalties_per_sale
SELECT 
    t.title_id,
    ta.au_id,
    ROUND((t.advance * ta.royaltyper / 100), 2) AS advance,
    ROUND((t.price * s.qty * t.royalty / 100 * ta.royaltyper / 100),
            2) AS sales_royalty
FROM
    sales s
        LEFT JOIN
    titles t ON s.title_id = t.title_id
        LEFT JOIN
    titleauthor ta ON t.title_id = ta.title_id;

-- Step 2: Aggregate the total royalties for each title and author
CREATE TEMPORARY TABLE roy_adv_per_title_author
SELECT 
    title_id,
    au_id,
    SUM(sales_royalty) AS total_roy,
    ROUND(AVG(advance)) AS advance -- mysql allows non-aggregated, non-grouped fields, but other sql dbms don't!
FROM
	royalties_per_sale
GROUP BY 
	title_id , au_id;

SELECT * from roy_adv_per_title_author;

-- Step 3: Calculate the total profits of each author
CREATE TEMPORARY TABLE total_profit_per_author
SELECT
	au_id,
    SUM(total_roy + advance) AS total_profit_author
FROM
    roy_adv_per_title_author
GROUP BY au_id;

-- CHALLENGE 3: CREATE A TABLE FROM OUR TEMPORARY TABLE 

CREATE TABLE most_profiting_author(author_id VARCHAR(70), total_profit INT );
SELECT * into most_profiting_author  from  total_profit_per_author; 