--
-- PostgreSQL database dump
--

\restrict 8ke4Nd2PHbsQYaBn0L1wxbnSFBAoyy1PcNzK5R2PNMZDHeSqfimfcXh92Y9yCjb

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-05-08 10:24:35

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 221 (class 1259 OID 16711)
-- Name: datatype_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datatype_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.datatype_mapping_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 16733)
-- Name: datatype_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_mapping (
    id integer DEFAULT nextval('public.datatype_mapping_id_seq'::regclass) NOT NULL,
    db_id integer NOT NULL,
    standard_id integer NOT NULL,
    final_type character varying(100) NOT NULL,
    has_length boolean DEFAULT false,
    has_precision boolean DEFAULT false,
    has_scale boolean DEFAULT false,
    notes text
);


ALTER TABLE public.datatype_mapping OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16712)
-- Name: datatype_raw_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datatype_raw_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.datatype_raw_mapping_id_seq OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16758)
-- Name: datatype_raw_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_raw_mapping (
    id integer DEFAULT nextval('public.datatype_raw_mapping_id_seq'::regclass) NOT NULL,
    db_id integer NOT NULL,
    raw_type text NOT NULL,
    logical_type text NOT NULL,
    source_type character varying(50),
    standard_id integer,
    is_default boolean DEFAULT false
);


ALTER TABLE public.datatype_raw_mapping OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16710)
-- Name: datatype_standard_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.datatype_standard_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.datatype_standard_id_seq OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16721)
-- Name: datatype_standard; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.datatype_standard (
    id integer DEFAULT nextval('public.datatype_standard_id_seq'::regclass) NOT NULL,
    standard_type character varying(100) NOT NULL,
    category character varying(50),
    description text
);


ALTER TABLE public.datatype_standard OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16709)
-- Name: db_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.db_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.db_type_id_seq OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16713)
-- Name: db_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.db_type (
    id integer DEFAULT nextval('public.db_type_id_seq'::regclass) NOT NULL,
    db_name character varying(50) NOT NULL
);


ALTER TABLE public.db_type OWNER TO postgres;

--
-- TOC entry 5052 (class 0 OID 16733)
-- Dependencies: 225
-- Data for Name: datatype_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_mapping (id, db_id, standard_id, final_type, has_length, has_precision, has_scale, notes) FROM stdin;
1	1	1	int	f	f	f	\N
2	1	2	bigint	f	f	f	\N
3	1	3	decimal	f	t	t	\N
4	1	4	real	f	f	f	\N
5	1	5	float	f	f	f	\N
6	1	6	bit	f	f	f	\N
7	1	7	char	t	f	f	\N
8	1	8	varchar	t	f	f	\N
9	1	9	text	f	f	f	\N
10	1	10	date	f	f	f	\N
11	1	11	time	f	t	f	\N
12	1	13	varbinary	t	f	f	\N
13	1	14	uniqueidentifier	f	f	f	\N
14	1	16	xml	f	f	f	\N
15	1	17	tinyint	f	f	f	\N
16	1	18	smallint	f	f	f	\N
17	1	19	nvarchar	t	f	f	\N
18	1	20	nchar	t	f	f	\N
19	1	21	ntext	f	f	f	\N
20	1	22	datetime	f	f	f	\N
21	1	23	datetime2	f	t	f	\N
22	1	24	smalldatetime	f	f	f	\N
23	1	25	datetimeoffset	f	t	f	\N
24	2	1	integer	f	f	f	\N
25	2	2	bigint	f	f	f	\N
26	2	3	numeric	f	t	t	\N
27	2	4	real	f	f	f	\N
28	2	5	double precision	f	f	f	\N
29	2	6	boolean	f	f	f	\N
30	2	7	char	t	f	f	\N
31	2	8	varchar	t	f	f	\N
32	2	9	text	f	f	f	\N
33	2	10	date	f	f	f	\N
34	2	11	time	f	t	f	\N
35	2	12	timestamp	f	t	f	\N
36	2	13	bytea	f	f	f	\N
37	2	14	uuid	f	f	f	\N
38	2	15	jsonb	f	f	f	\N
39	2	16	xml	f	f	f	\N
40	3	1	int	f	f	f	\N
41	3	2	bigint	f	f	f	\N
42	3	3	decimal	f	t	t	\N
43	3	4	float	f	f	f	\N
44	3	5	double	f	f	f	\N
45	3	6	tinyint(1)	f	f	f	\N
46	3	7	char	t	f	f	\N
47	3	8	varchar	t	f	f	\N
48	3	9	text	f	f	f	\N
49	3	10	date	f	f	f	\N
50	3	11	time	f	t	f	\N
51	3	12	timestamp	f	t	f	\N
52	3	13	blob	f	f	f	\N
53	3	15	json	f	f	f	\N
54	4	1	number(10)	f	t	f	\N
55	4	2	number(19)	f	t	f	\N
56	4	3	number	f	t	t	\N
57	4	4	binary_float	f	f	f	\N
58	4	5	binary_double	f	f	f	\N
59	4	6	number(1)	f	f	f	\N
60	4	7	char	t	f	f	\N
61	4	8	varchar2	t	f	f	\N
62	4	9	clob	f	f	f	\N
63	4	12	timestamp	f	t	f	\N
64	4	13	blob	f	f	f	\N
65	4	16	xmltype	f	f	f	\N
66	1	12	datetime2	f	t	f	\N
67	1	15	nvarchar(max)	f	f	f	\N
68	2	22	timestamp	f	t	f	\N
69	3	14	char(36)	f	f	f	\N
70	3	16	text	f	f	f	\N
71	3	22	datetime	f	f	f	\N
72	4	14	varchar2(36)	f	f	f	\N
73	4	15	clob	f	f	f	\N
74	4	22	timestamp	f	t	f	\N
77	2	17	smallint	f	f	f	\N
78	2	18	smallint	f	f	f	\N
79	2	19	varchar	t	f	f	\N
80	2	20	char	t	f	f	\N
81	2	21	text	f	f	f	\N
83	2	23	timestamp	f	t	f	\N
84	2	24	timestamp	f	f	f	\N
85	2	25	timestamptz	f	f	f	\N
88	3	17	tinyint	f	f	f	\N
89	3	18	smallint	f	f	f	\N
90	3	19	varchar	t	f	f	\N
91	3	20	char	t	f	f	\N
92	3	21	text	f	f	f	\N
94	3	23	datetime	f	f	f	\N
95	3	24	datetime	f	f	f	\N
96	3	25	varchar(35)	f	f	f	\N
97	4	10	date	f	f	f	\N
98	4	11	timestamp	f	t	f	\N
101	4	17	number(3)	f	f	f	\N
102	4	18	number(5)	f	f	f	\N
103	4	19	nvarchar2	t	f	f	\N
104	4	20	nchar	t	f	f	\N
105	4	21	nclob	f	f	f	\N
107	4	23	timestamp	f	t	f	\N
108	4	24	date	f	f	f	\N
109	4	25	timestamp with time zone	f	f	f	\N
145	1	26	geometry	f	f	f	\N
146	2	26	geometry	f	f	f	\N
147	3	26	geometry	f	f	f	\N
148	4	26	sdo_geometry	f	f	f	\N
149	1	27	varchar	t	f	f	\N
150	2	27	interval	f	f	f	\N
151	3	27	varchar	t	f	f	\N
152	4	27	interval day to second	f	t	f	\N
153	1	28	varchar	t	f	f	\N
154	2	28	inet	f	f	f	\N
155	3	28	varchar	t	f	f	\N
156	4	28	varchar2	t	f	f	\N
157	1	29	varchar	t	f	f	\N
158	2	29	varchar	t	f	f	\N
159	3	29	enum	f	f	f	\N
160	4	29	varchar2	t	f	f	\N
\.


--
-- TOC entry 5053 (class 0 OID 16758)
-- Dependencies: 226
-- Data for Name: datatype_raw_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_raw_mapping (id, db_id, raw_type, logical_type, source_type, standard_id, is_default) FROM stdin;
155	2	int	int	smallint	18	f
156	2	long	timestamp-millis	timestamptz	25	f
17	2	string	json	jsonb	15	f
27	3	string	json	json	15	f
36	4	string	xml	xmltype	16	f
60	2	string	xml	xml	16	f
2	1	long	long	bigint	2	f
3	1	bytes	decimal	decimal	3	f
4	1	float	float	real	4	f
5	1	double	double	float	5	f
6	1	boolean	boolean	bit	6	f
8	1	string	uuid	uniqueidentifier	14	f
9	1	long	timestamp-millis	datetime	22	f
11	2	long	long	bigint	2	f
12	2	bytes	decimal	numeric	3	f
13	2	float	float	real	4	f
14	2	double	double	double precision	5	f
15	2	boolean	boolean	boolean	6	f
18	2	string	uuid	uuid	14	f
21	3	long	long	bigint	2	f
22	3	bytes	decimal	decimal	3	f
23	3	float	float	float	4	f
24	3	double	double	double	5	f
25	3	boolean	boolean	tinyint(1)	6	f
52	1	string	datetime-offset	datetimeoffset	25	f
40	1	int	date	date	10	f
153	4	string	interval	interval day to second	27	f
154	4	string	interval	interval year to month	27	f
57	2	int	date	date	10	f
63	3	int	date	date	10	f
146	3	int	date	year	10	f
41	1	int	time	time	11	f
58	2	long	time	time	11	f
64	3	int	time	time	11	f
44	1	string	xml	xml	16	f
30	4	long	long	number(19)	2	f
31	4	bytes	decimal	number	3	f
32	4	float	float	binary_float	4	f
33	4	double	double	binary_double	5	f
34	4	boolean	boolean	number(1)	6	f
38	1	string	string	char	7	f
39	1	string	string	text	9	f
45	1	int	int	tinyint	17	f
46	1	int	int	smallint	18	f
47	1	string	string	nvarchar	19	f
48	1	string	string	nchar	20	f
49	1	string	string	ntext	21	f
50	1	long	timestamp-micros	datetime2	23	f
51	1	long	timestamp-millis	smalldatetime	24	f
53	1	bytes	decimal	money	3	f
54	1	bytes	decimal	smallmoney	3	f
55	2	string	string	char	7	f
56	2	string	string	text	9	f
61	3	string	string	char	7	f
62	3	string	string	text	9	f
67	4	string	string	char	7	f
68	4	string	string	clob	9	f
70	4	long	timestamp-millis	date	22	f
137	1	string	spatial	geometry	26	f
138	1	string	spatial	geography	26	f
140	2	string	interval	interval	27	f
141	2	string	network	inet	28	f
142	2	string	network	cidr	28	f
143	2	string	network	macaddr	28	f
144	2	string	spatial	geometry	26	f
147	3	string	enum	enum	29	f
148	3	string	enum	set	29	f
151	4	string	string	long	9	f
7	1	string	string	varchar	8	t
16	2	string	string	varchar	8	t
26	3	string	string	varchar	8	t
35	4	string	string	varchar2	8	t
139	1	string	string	hierarchyid	8	t
1	1	int	int	int	1	t
10	2	int	int	integer	1	t
20	3	int	int	int	1	t
29	4	int	int	number(10)	1	t
145	3	int	int	mediumint	1	t
19	2	long	timestamp-micros	timestamp	12	t
28	3	long	timestamp-millis	timestamp	12	t
37	4	long	timestamp-micros	timestamp	12	t
152	4	bytes	bytes	bfile	13	t
42	1	bytes	bytes	binary	13	t
43	1	bytes	bytes	varbinary	13	t
59	2	bytes	bytes	bytea	13	t
65	3	bytes	bytes	binary	13	t
66	3	bytes	bytes	blob	13	t
69	4	bytes	bytes	blob	13	t
149	4	bytes	bytes	raw	13	t
150	4	bytes	bytes	long raw	13	t
\.


--
-- TOC entry 5051 (class 0 OID 16721)
-- Dependencies: 224
-- Data for Name: datatype_standard; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datatype_standard (id, standard_type, category, description) FROM stdin;
1	INTEGER	numeric	\N
2	BIGINT	numeric	\N
3	DECIMAL	numeric	\N
4	FLOAT	numeric	\N
5	DOUBLE PRECISION	numeric	\N
6	BOOLEAN	boolean	\N
7	CHAR	string	\N
8	VARCHAR	string	\N
9	TEXT	string	\N
10	DATE	datetime	\N
11	TIME	datetime	\N
12	TIMESTAMP	datetime	\N
13	BINARY	binary	\N
14	UUID	other	\N
15	JSON	other	\N
16	XML	other	\N
17	TINYINT	numeric	\N
18	SMALLINT	numeric	\N
19	NVARCHAR	string	\N
20	NCHAR	string	\N
21	NTEXT	string	\N
22	DATETIME	datetime	\N
23	DATETIME2	datetime	\N
24	SMALLDATETIME	datetime	\N
25	DATETIMEOFFSET	datetime	\N
26	GEOMETRY	spatial	Spatial and geometry data (e.g., points, polygons)
27	INTERVAL	datetime	Time span or interval
28	NETWORK	other	IP addresses and network types (e.g., INET, CIDR)
29	ENUM	other	Enumerated list of values or sets
\.


--
-- TOC entry 5050 (class 0 OID 16713)
-- Dependencies: 223
-- Data for Name: db_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.db_type (id, db_name) FROM stdin;
1	sqlserver
2	postgresql
3	mysql
4	oracle
\.


--
-- TOC entry 5059 (class 0 OID 0)
-- Dependencies: 221
-- Name: datatype_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_mapping_id_seq', 161, true);


--
-- TOC entry 5060 (class 0 OID 0)
-- Dependencies: 222
-- Name: datatype_raw_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_raw_mapping_id_seq', 156, true);


--
-- TOC entry 5061 (class 0 OID 0)
-- Dependencies: 220
-- Name: datatype_standard_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.datatype_standard_id_seq', 29, true);


--
-- TOC entry 5062 (class 0 OID 0)
-- Dependencies: 219
-- Name: db_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.db_type_id_seq', 4, true);


--
-- TOC entry 4886 (class 2606 OID 16747)
-- Name: datatype_mapping datatype_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT datatype_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4890 (class 2606 OID 16769)
-- Name: datatype_raw_mapping datatype_raw_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT datatype_raw_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4882 (class 2606 OID 16730)
-- Name: datatype_standard datatype_standard_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_pkey PRIMARY KEY (id);


--
-- TOC entry 4884 (class 2606 OID 16732)
-- Name: datatype_standard datatype_standard_standard_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_standard
    ADD CONSTRAINT datatype_standard_standard_type_key UNIQUE (standard_type);


--
-- TOC entry 4880 (class 2606 OID 16720)
-- Name: db_type db_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.db_type
    ADD CONSTRAINT db_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4888 (class 2606 OID 16798)
-- Name: datatype_mapping uniq_final_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT uniq_final_mapping UNIQUE (db_id, standard_id);


--
-- TOC entry 4892 (class 2606 OID 16800)
-- Name: datatype_raw_mapping uniq_raw_mapping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT uniq_raw_mapping UNIQUE (db_id, raw_type, source_type);


--
-- TOC entry 4894 (class 2606 OID 16781)
-- Name: datatype_raw_mapping unique_mapping_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT unique_mapping_idx UNIQUE (db_id, raw_type, logical_type, source_type, standard_id);


--
-- TOC entry 4897 (class 2606 OID 16770)
-- Name: datatype_raw_mapping fk_db; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT fk_db FOREIGN KEY (db_id) REFERENCES public.db_type(id);


--
-- TOC entry 4895 (class 2606 OID 16748)
-- Name: datatype_mapping fk_mapping_db; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT fk_mapping_db FOREIGN KEY (db_id) REFERENCES public.db_type(id);


--
-- TOC entry 4896 (class 2606 OID 16753)
-- Name: datatype_mapping fk_mapping_standard; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_mapping
    ADD CONSTRAINT fk_mapping_standard FOREIGN KEY (standard_id) REFERENCES public.datatype_standard(id);


--
-- TOC entry 4898 (class 2606 OID 16775)
-- Name: datatype_raw_mapping fk_standard; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datatype_raw_mapping
    ADD CONSTRAINT fk_standard FOREIGN KEY (standard_id) REFERENCES public.datatype_standard(id);


-- Completed on 2026-05-08 10:24:35

--
-- PostgreSQL database dump complete
--

\unrestrict 8ke4Nd2PHbsQYaBn0L1wxbnSFBAoyy1PcNzK5R2PNMZDHeSqfimfcXh92Y9yCjb

