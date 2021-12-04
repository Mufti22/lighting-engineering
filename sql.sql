--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: avg_cost(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.avg_cost() RETURNS double precision
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (
    SELECT AVG(plumbing.product_price) AS price FROM plumbing
    );
END;
$$;


ALTER FUNCTION public.avg_cost() OWNER TO postgres;

--
-- Name: avg_interval(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.avg_interval(date, date) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN (
SELECT AVG(product_price) from plumbing p
INNER JOIN supply s ON s.id = p.id_supply_date
WHERE s.supply_date between $1 AND $2
);
END;
$_$;


ALTER FUNCTION public.avg_interval(date, date) OWNER TO postgres;

--
-- Name: c_pl(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.c_pl(integer) RETURNS TABLE(count bigint, avg double precision, max real, min real)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY
SELECT COUNT(p.id), AVG(product_price), MAX(product_price), MIN(product_price) FROM plumbing p WHERE NOW() - p.product_date <= $1 * interval '1 month';
END;
$_$;


ALTER FUNCTION public.c_pl(integer) OWNER TO postgres;

--
-- Name: general_table(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.general_table() RETURNS TABLE(id integer, product_name character varying, product_type character varying, product_date date, product_price real, vendor character varying, country character varying, city character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, plumbing.product_date, plumbing.Product_price, vendor.name AS vendor, place_of_manufacturing.counry, place_of_manufacturing.city FROM plumbing
    INNER JOIN vendor ON vendor.id = id_vendor 
    INNER JOIN (
        SELECT manufacturing.id, country.name AS counry, manufacturing.name AS city FROM manufacturing
        INNER JOIN country ON country.id = id_country
    ) AS place_of_manufacturing ON place_of_manufacturing.id = id_manufacturing;
END;
$$;


ALTER FUNCTION public.general_table() OWNER TO postgres;

--
-- Name: manu_price(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.manu_price(character varying) RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_date date, product_price real, name character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY
        SELECT p.id, p.name_of_product, p.type_of_product, p.product_date, p.product_price, m.name FROM plumbing p 
        INNER JOIN manufacturing m ON m.id = p.id_manufacturing 
        WHERE p.product_price > avg_price($1);
END;
$_$;


ALTER FUNCTION public.manu_price(character varying) OWNER TO postgres;

--
-- Name: max_cost(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.max_cost() RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_price real)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, plumbing.product_price FROM plumbing WHERE plumbing.product_price=(SELECT MAX(plumbing.product_price) FROM plumbing);
END;
$$;


ALTER FUNCTION public.max_cost() OWNER TO postgres;

--
-- Name: min_cost(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.min_cost() RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_price real)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, plumbing.product_price FROM plumbing WHERE plumbing.product_price=(SELECT MIN(plumbing.product_price) FROM plumbing);
END;
$$;


ALTER FUNCTION public.min_cost() OWNER TO postgres;

--
-- Name: most_cost(real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.most_cost(a real) RETURNS TABLE(id integer, name_of_product character varying, product_price real)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
        SELECT plumbing.id, plumbing.name_of_product, plumbing.product_price FROM plumbing GROUP BY plumbing.id HAVING plumbing.product_price > a
        ORDER BY plumbing.product_price;
END;
$$;


ALTER FUNCTION public.most_cost(a real) OWNER TO postgres;

--
-- Name: per_country(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.per_country(character varying) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN (
SELECT (
SELECT COUNT(*)::float FROM plumbing p
INNER JOIN (
SELECT m.id, c.name FROM manufacturing m
INNER JOIN country c ON m.id_country = c.id
) AS Countries ON p.id_manufacturing = Countries.id
WHERE Countries.name = $1
) / (SELECT COUNT(*)::float FROM plumbing) * 100
);
END;
$_$;


ALTER FUNCTION public.per_country(character varying) OWNER TO postgres;

--
-- Name: per_high_price(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.per_high_price(integer, character varying) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
a float;
b float;
BEGIN
SELECT COUNT(*) into a AS Client FROM plumbing p
INNER JOIN supply s ON p.id_supply_date = s.id
INNER JOIN clients c ON s.id_clients = c.id
WHERE (product_price > $1) AND (c.name = $2);
SELECT COUNT(*) into b from plumbing p;
RETURN a/b;
END;
$_$;


ALTER FUNCTION public.per_high_price(integer, character varying) OWNER TO postgres;

--
-- Name: per_vendor(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.per_vendor(character varying) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
a float;
b float;
BEGIN
SELECT COUNT(*) INTO a FROM plumbing p
INNER JOIN vendor v ON v.id = p.id_vendor

WHERE v.name = $1;
SELECT COUNT(*) INTO b FROM vendor;
RETURN a/b;
END;
$_$;


ALTER FUNCTION public.per_vendor(character varying) OWNER TO postgres;

--
-- Name: pl_date(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pl_date(date) RETURNS TABLE(id integer, name_of_product character varying, product_date date)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY
        SELECT plumbing.id, plumbing.name_of_product, plumbing.product_date FROM plumbing WHERE plumbing.product_date = $1;
END;
$_$;


ALTER FUNCTION public.pl_date(date) OWNER TO postgres;

--
-- Name: pl_date_cost(date, real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pl_date_cost(date, real) RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_date date, product_price real)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY
SELECT p.id, p.name_of_product, p.type_of_product, p.product_date, p.product_price FROM plumbing p
WHERE (p.product_date = $1) AND (p.product_price > $2);
END;
$_$;


ALTER FUNCTION public.pl_date_cost(date, real) OWNER TO postgres;

--
-- Name: pl_manu(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pl_manu(character varying) RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_price real, manufacturing character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY
        SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, plumbing.product_price, manufacturing.name AS vendor FROM plumbing
        INNER JOIN manufacturing ON manufacturing.id = id_manufacturing
        WHERE manufacturing.name = $1;
END;
$_$;


ALTER FUNCTION public.pl_manu(character varying) OWNER TO postgres;

--
-- Name: pl_vendor_cost_country(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pl_vendor_cost_country(character varying, character varying) RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_date date, product_price real, name character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY
SELECT p.id, p.name_of_product, p.type_of_product, p.product_date, p.product_price, v.name FROM plumbing p
INNER JOIN manufacturing m ON m.id = p.id_manufacturing
INNER JOIN vendor v ON v.id = p.id_vendor
INNER JOIN supply s ON s.id = p.id_supply_date
INNER JOIN country c ON c.id = m.id_country
WHERE (v.name = $1 AND (p.product_price > (SELECT AVG(product_price) FROM plumbing)) AND (c.name = $2));
END;
$_$;


ALTER FUNCTION public.pl_vendor_cost_country(character varying, character varying) OWNER TO postgres;

--
-- Name: sort_by_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sort_by_date() RETURNS TABLE(id integer, product_name character varying, product_type character varying, product_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, plumbing.product_date FROM plumbing WHERE plumbing.type_of_product = type_of_product ORDER BY plumbing.product_date;
END;
$$;


ALTER FUNCTION public.sort_by_date() OWNER TO postgres;

--
-- Name: sort_by_price(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sort_by_price() RETURNS TABLE(id integer, product_name character varying, product_type character varying, product_price real)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, plumbing.product_price FROM plumbing WHERE plumbing.type_of_product = type_of_product ORDER BY plumbing.product_price;
END;
$$;


ALTER FUNCTION public.sort_by_price() OWNER TO postgres;

--
-- Name: sort_by_vendor(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sort_by_vendor() RETURNS TABLE(id integer, product_name character varying, product_type character varying, vendor character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT plumbing.id, plumbing.name_of_product, plumbing.type_of_product, vendor.name AS vendor FROM plumbing 
    INNER JOIN vendor ON vendor.id = id_vendor 
    WHERE plumbing.type_of_product = type_of_product ORDER BY vendor.name;
END;
$$;


ALTER FUNCTION public.sort_by_vendor() OWNER TO postgres;

--
-- Name: supply_share(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.supply_share(date, date) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
a float;
b float;
BEGIN
SELECT COUNT(*) INTO a FROM plumbing p
INNER JOIN supply s ON s.id = p.id_supply_date
WHERE s.supply_date between $1 and $2;
SELECT COUNT(*) INTO b FROM plumbing;
RETURN a/b;
END;
$_$;


ALTER FUNCTION public.supply_share(date, date) OWNER TO postgres;

--
-- Name: vendor_price(date, date, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.vendor_price(date, date, character varying) RETURNS TABLE(id integer, name_of_product character varying, product_type character varying, product_date date, product_price real, name character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY
SELECT p.id, p.name_of_product, p.type_of_product, p.product_date, p.product_price, v.name FROM plumbing p
INNER JOIN vendor v ON v.id = id_vendor
WHERE (p.product_date > $1) AND (p.product_date < $2) AND v.name = $3;
END;
$_$;


ALTER FUNCTION public.vendor_price(date, date, character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: b; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.b (
    count bigint
);


ALTER TABLE public.b OWNER TO postgres;

--
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clients_id_seq OWNER TO postgres;

--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: country; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.country OWNER TO postgres;

--
-- Name: country_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.country_id_seq OWNER TO postgres;

--
-- Name: country_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.country_id_seq OWNED BY public.country.id;


--
-- Name: manufacturing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manufacturing (
    id integer NOT NULL,
    name character varying(255),
    id_country integer
);


ALTER TABLE public.manufacturing OWNER TO postgres;

--
-- Name: manufacturing_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manufacturing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manufacturing_id_seq OWNER TO postgres;

--
-- Name: manufacturing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manufacturing_id_seq OWNED BY public.manufacturing.id;


--
-- Name: plumbing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plumbing (
    id integer NOT NULL,
    name_of_product character varying(255),
    type_of_product character varying(255),
    product_date date,
    id_manufacturing integer,
    id_vendor integer,
    product_price real,
    id_supply_date integer
);


ALTER TABLE public.plumbing OWNER TO postgres;

--
-- Name: plumbing_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.plumbing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.plumbing_id_seq OWNER TO postgres;

--
-- Name: plumbing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plumbing_id_seq OWNED BY public.plumbing.id;


--
-- Name: supply; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.supply (
    id integer NOT NULL,
    id_vendor integer,
    id_plumb integer,
    id_clients integer,
    supply_date date
);


ALTER TABLE public.supply OWNER TO postgres;

--
-- Name: supply_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.supply_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.supply_id_seq OWNER TO postgres;

--
-- Name: supply_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.supply_id_seq OWNED BY public.supply.id;


--
-- Name: vendor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendor (
    id integer NOT NULL,
    name character varying(255)
);


ALTER TABLE public.vendor OWNER TO postgres;

--
-- Name: vendor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vendor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vendor_id_seq OWNER TO postgres;

--
-- Name: vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vendor_id_seq OWNED BY public.vendor.id;


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: country id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country ALTER COLUMN id SET DEFAULT nextval('public.country_id_seq'::regclass);


--
-- Name: manufacturing id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manufacturing ALTER COLUMN id SET DEFAULT nextval('public.manufacturing_id_seq'::regclass);


--
-- Name: plumbing id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plumbing ALTER COLUMN id SET DEFAULT nextval('public.plumbing_id_seq'::regclass);


--
-- Name: supply id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supply ALTER COLUMN id SET DEFAULT nextval('public.supply_id_seq'::regclass);


--
-- Name: vendor id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor ALTER COLUMN id SET DEFAULT nextval('public.vendor_id_seq'::regclass);


--
-- Data for Name: b; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.b (count) FROM stdin;
10
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (id, name) FROM stdin;
0	Baharov A.N
1	Gustavo L.E
2	Sosa E.H
3	Szalai A.A
4	Ozil M.D
5	Tufan O.E
6	Aziz S.S
7	Celikler S.A
8	Kim M.J
9	Kahveci I.C
\.


--
-- Data for Name: country; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.country (id, name) FROM stdin;
0	Russia
1	US
2	Canada
3	Austria
4	Azerbaijan
5	UAE
\.


--
-- Data for Name: manufacturing; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.manufacturing (id, name, id_country) FROM stdin;
0	Moscow	0
1	St-Peterburg	0
2	Novosibirsk	0
3	Kazan	0
4	Dubai	5
5	Denver	1
6	Atlanta	2
7	Washington	1
8	Salzburg	3
9	Baku	4
\.


--
-- Data for Name: plumbing; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.plumbing (id, name_of_product, type_of_product, product_date, id_manufacturing, id_vendor, product_price, id_supply_date) FROM stdin;
8	White hose	hose	2021-06-17	6	4	254	2
6	Orange hose	hose	2021-12-10	2	8	35	1
4	Dark tube	tube	2021-11-01	9	8	321	1
3	Yellow tube	tube	2021-11-12	7	6	160	2
1	Red tube	tube	2021-11-02	3	2	123	1
5	Green hose	hose	2021-11-06	0	0	95	0
7	Black hose	hose	2021-11-01	4	6	142	2
0	Orange tube	tube	2021-10-23	1	0	140	0
9	Big hose	hose	2021-11-03	8	2	312	0
2	Blue tube	tube	2021-10-04	5	4	152	2
\.


--
-- Data for Name: supply; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.supply (id, id_vendor, id_plumb, id_clients, supply_date) FROM stdin;
0	9	9	0	2021-11-30
1	8	8	1	2021-11-29
2	7	1	2	2021-12-01
\.


--
-- Data for Name: vendor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vendor (id, name) FROM stdin;
0	Aliexpress
1	Alibaba
2	Dinodirect
3	Taobao
4	Tmart
5	Supl
6	Optlist
7	shell
8	Amazon
9	Webtekno
\.


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clients_id_seq', 1, false);


--
-- Name: country_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.country_id_seq', 1, false);


--
-- Name: manufacturing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.manufacturing_id_seq', 1, false);


--
-- Name: plumbing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.plumbing_id_seq', 1, false);


--
-- Name: supply_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.supply_id_seq', 1, false);


--
-- Name: vendor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vendor_id_seq', 1, false);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: country country_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);


--
-- Name: manufacturing manufacturing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manufacturing
    ADD CONSTRAINT manufacturing_pkey PRIMARY KEY (id);


--
-- Name: plumbing plumbing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plumbing
    ADD CONSTRAINT plumbing_pkey PRIMARY KEY (id);


--
-- Name: supply supply_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supply
    ADD CONSTRAINT supply_pkey PRIMARY KEY (id);


--
-- Name: vendor vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_pkey PRIMARY KEY (id);


--
-- Name: manufacturing manufacturing_id_country_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manufacturing
    ADD CONSTRAINT manufacturing_id_country_fkey FOREIGN KEY (id_country) REFERENCES public.country(id);


--
-- Name: plumbing plumbing_id_manufacturing_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plumbing
    ADD CONSTRAINT plumbing_id_manufacturing_fkey FOREIGN KEY (id_manufacturing) REFERENCES public.manufacturing(id);


--
-- Name: plumbing plumbing_id_supply_date_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plumbing
    ADD CONSTRAINT plumbing_id_supply_date_fkey FOREIGN KEY (id_supply_date) REFERENCES public.supply(id);


--
-- Name: plumbing plumbing_id_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plumbing
    ADD CONSTRAINT plumbing_id_vendor_fkey FOREIGN KEY (id_vendor) REFERENCES public.vendor(id);


--
-- Name: supply supply_id_clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supply
    ADD CONSTRAINT supply_id_clients_fkey FOREIGN KEY (id_clients) REFERENCES public.clients(id);


--
-- Name: supply supply_id_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supply
    ADD CONSTRAINT supply_id_vendor_fkey FOREIGN KEY (id_vendor) REFERENCES public.vendor(id);


--
-- Name: TABLE clients; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clients TO operator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clients TO user_db;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.clients TO admin;


--
-- Name: TABLE country; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.country TO operator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.country TO admin;


--
-- Name: TABLE manufacturing; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.manufacturing TO operator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.manufacturing TO user_db;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.manufacturing TO admin;


--
-- Name: TABLE plumbing; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.plumbing TO operator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.plumbing TO user_db;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.plumbing TO admin;


--
-- Name: TABLE supply; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.supply TO operator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.supply TO user_db;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.supply TO admin;


--
-- Name: TABLE vendor; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.vendor TO operator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.vendor TO user_db;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.vendor TO admin;


--
-- PostgreSQL database dump complete
--

