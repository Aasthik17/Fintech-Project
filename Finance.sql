PGDMP                      }            FINANCE    17.4    17.4 ;    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    16524    FINANCE    DATABASE     o   CREATE DATABASE "FINANCE" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en-US';
    DROP DATABASE "FINANCE";
                     postgres    false                        3079    17021    pgcrypto 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
    DROP EXTENSION pgcrypto;
                        false            �           0    0    EXTENSION pgcrypto    COMMENT     <   COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
                             false    2            �            1259    17071    accounts    TABLE     �   CREATE TABLE public.accounts (
    account_id integer NOT NULL,
    user_id integer,
    account_name character varying(255) NOT NULL,
    balance numeric(15,2) DEFAULT 0.00 NOT NULL,
    currency character varying(10) DEFAULT 'USD'::character varying
);
    DROP TABLE public.accounts;
       public         heap r       postgres    false            �           0    0    TABLE accounts    ACL     8   GRANT SELECT ON TABLE public.accounts TO readonly_user;
          public               postgres    false    221            �            1259    17070    accounts_account_id_seq    SEQUENCE     �   CREATE SEQUENCE public.accounts_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.accounts_account_id_seq;
       public               postgres    false    221            �           0    0    accounts_account_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.accounts_account_id_seq OWNED BY public.accounts.account_id;
          public               postgres    false    220            �            1259    17126    budget    TABLE     �   CREATE TABLE public.budget (
    budget_id integer NOT NULL,
    user_id integer,
    category_id integer,
    amount numeric(15,2) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL
);
    DROP TABLE public.budget;
       public         heap r       postgres    false            �           0    0    TABLE budget    ACL     6   GRANT SELECT ON TABLE public.budget TO readonly_user;
          public               postgres    false    227            �            1259    17125    budget_budget_id_seq    SEQUENCE     �   CREATE SEQUENCE public.budget_budget_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.budget_budget_id_seq;
       public               postgres    false    227            �           0    0    budget_budget_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.budget_budget_id_seq OWNED BY public.budget.budget_id;
          public               postgres    false    226            �            1259    17085 
   categories    TABLE     �   CREATE TABLE public.categories (
    category_id integer NOT NULL,
    user_id integer,
    category_name character varying(255) NOT NULL
);
    DROP TABLE public.categories;
       public         heap r       postgres    false            �           0    0    TABLE categories    ACL     :   GRANT SELECT ON TABLE public.categories TO readonly_user;
          public               postgres    false    223            �            1259    17084    categories_category_id_seq    SEQUENCE     �   CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.categories_category_id_seq;
       public               postgres    false    223            �           0    0    categories_category_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;
          public               postgres    false    222            �            1259    17099    transactions    TABLE       CREATE TABLE public.transactions (
    transaction_id integer NOT NULL,
    user_id integer,
    account_id integer,
    category_id integer,
    amount numeric(15,2) NOT NULL,
    transaction_type character varying(10),
    description text,
    transaction_date timestamp without time zone DEFAULT now(),
    metadata jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT transactions_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['income'::character varying, 'expense'::character varying])::text[])))
);
     DROP TABLE public.transactions;
       public         heap r       postgres    false            �           0    0    TABLE transactions    ACL     <   GRANT SELECT ON TABLE public.transactions TO readonly_user;
          public               postgres    false    225            �            1259    17098    transactions_transaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.transactions_transaction_id_seq;
       public               postgres    false    225            �           0    0    transactions_transaction_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;
          public               postgres    false    224            �            1259    17059    users    TABLE     �   CREATE TABLE public.users (
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);
    DROP TABLE public.users;
       public         heap r       postgres    false            �           0    0    TABLE users    ACL     5   GRANT SELECT ON TABLE public.users TO readonly_user;
          public               postgres    false    219            �            1259    17058    users_user_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.users_user_id_seq;
       public               postgres    false    219            �           0    0    users_user_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;
          public               postgres    false    218            �           2604    17074    accounts account_id    DEFAULT     z   ALTER TABLE ONLY public.accounts ALTER COLUMN account_id SET DEFAULT nextval('public.accounts_account_id_seq'::regclass);
 B   ALTER TABLE public.accounts ALTER COLUMN account_id DROP DEFAULT;
       public               postgres    false    221    220    221            �           2604    17129    budget budget_id    DEFAULT     t   ALTER TABLE ONLY public.budget ALTER COLUMN budget_id SET DEFAULT nextval('public.budget_budget_id_seq'::regclass);
 ?   ALTER TABLE public.budget ALTER COLUMN budget_id DROP DEFAULT;
       public               postgres    false    227    226    227            �           2604    17088    categories category_id    DEFAULT     �   ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);
 E   ALTER TABLE public.categories ALTER COLUMN category_id DROP DEFAULT;
       public               postgres    false    223    222    223            �           2604    17102    transactions transaction_id    DEFAULT     �   ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);
 J   ALTER TABLE public.transactions ALTER COLUMN transaction_id DROP DEFAULT;
       public               postgres    false    224    225    225            �           2604    17062    users user_id    DEFAULT     n   ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);
 <   ALTER TABLE public.users ALTER COLUMN user_id DROP DEFAULT;
       public               postgres    false    218    219    219            w          0    17071    accounts 
   TABLE DATA           X   COPY public.accounts (account_id, user_id, account_name, balance, currency) FROM stdin;
    public               postgres    false    221   F       }          0    17126    budget 
   TABLE DATA           _   COPY public.budget (budget_id, user_id, category_id, amount, start_date, end_date) FROM stdin;
    public               postgres    false    227   -F       y          0    17085 
   categories 
   TABLE DATA           I   COPY public.categories (category_id, user_id, category_name) FROM stdin;
    public               postgres    false    223   JF       {          0    17099    transactions 
   TABLE DATA           �   COPY public.transactions (transaction_id, user_id, account_id, category_id, amount, transaction_type, description, transaction_date, metadata) FROM stdin;
    public               postgres    false    225   gF       u          0    17059    users 
   TABLE DATA           P   COPY public.users (user_id, name, email, password_hash, created_at) FROM stdin;
    public               postgres    false    219   �F       �           0    0    accounts_account_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.accounts_account_id_seq', 1, false);
          public               postgres    false    220            �           0    0    budget_budget_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.budget_budget_id_seq', 1, false);
          public               postgres    false    226            �           0    0    categories_category_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.categories_category_id_seq', 1, false);
          public               postgres    false    222            �           0    0    transactions_transaction_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 1, false);
          public               postgres    false    224            �           0    0    users_user_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.users_user_id_seq', 1, false);
          public               postgres    false    218            �           2606    17078    accounts accounts_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);
 @   ALTER TABLE ONLY public.accounts DROP CONSTRAINT accounts_pkey;
       public                 postgres    false    221            �           2606    17131    budget budget_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_pkey PRIMARY KEY (budget_id);
 <   ALTER TABLE ONLY public.budget DROP CONSTRAINT budget_pkey;
       public                 postgres    false    227            �           2606    17092 '   categories categories_category_name_key 
   CONSTRAINT     k   ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_category_name_key UNIQUE (category_name);
 Q   ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_category_name_key;
       public                 postgres    false    223            �           2606    17090    categories categories_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);
 D   ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_pkey;
       public                 postgres    false    223            �           2606    17109    transactions transactions_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);
 H   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_pkey;
       public                 postgres    false    225            �           2606    17069    users users_email_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT users_email_key;
       public                 postgres    false    219            �           2606    17067    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public                 postgres    false    219            �           1259    17144    idx_metadata_jsonb    INDEX     M   CREATE INDEX idx_metadata_jsonb ON public.transactions USING gin (metadata);
 &   DROP INDEX public.idx_metadata_jsonb;
       public                 postgres    false    225            �           1259    17142    idx_transaction_date    INDEX     Y   CREATE INDEX idx_transaction_date ON public.transactions USING btree (transaction_date);
 (   DROP INDEX public.idx_transaction_date;
       public                 postgres    false    225            �           1259    17143    idx_user_transactions    INDEX     c   CREATE INDEX idx_user_transactions ON public.transactions USING btree (user_id, transaction_date);
 )   DROP INDEX public.idx_user_transactions;
       public                 postgres    false    225    225            �           2606    17079    accounts accounts_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.accounts DROP CONSTRAINT accounts_user_id_fkey;
       public               postgres    false    4814    219    221            �           2606    17137    budget budget_category_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.budget DROP CONSTRAINT budget_category_id_fkey;
       public               postgres    false    227    4820    223            �           2606    17132    budget budget_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.budget
    ADD CONSTRAINT budget_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.budget DROP CONSTRAINT budget_user_id_fkey;
       public               postgres    false    4814    219    227            �           2606    17093 "   categories categories_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.categories DROP CONSTRAINT categories_user_id_fkey;
       public               postgres    false    4814    223    219            �           2606    17115 )   transactions transactions_account_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(account_id) ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_account_id_fkey;
       public               postgres    false    225    4816    221            �           2606    17120 *   transactions transactions_category_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id);
 T   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_category_id_fkey;
       public               postgres    false    225    223    4820            �           2606    17110 &   transactions transactions_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
 P   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_user_id_fkey;
       public               postgres    false    225    219    4814            5           826    17145    DEFAULT PRIVILEGES FOR TABLES    DEFAULT ACL     e   ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;
          public               postgres    false            w      x������ � �      }      x������ � �      y      x������ � �      {      x������ � �      u      x������ � �     