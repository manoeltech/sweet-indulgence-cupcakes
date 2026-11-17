-- Projeto físico do banco (PostgreSQL), gerado com pg_dump a partir das migrations do Rails.
-- Para criar do zero: bin/rails db:prepare

CREATE TABLE public.addresses (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    street character varying(160) NOT NULL,
    number character varying(10) NOT NULL,
    district character varying(80) NOT NULL,
    zip_code character varying(9) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE SEQUENCE public.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying(60) NOT NULL,
    slug character varying(60) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;

CREATE TABLE public.contact_logs (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    courier_id bigint NOT NULL,
    channel character varying(10) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE SEQUENCE public.contact_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.contact_logs_id_seq OWNED BY public.contact_logs.id;

CREATE TABLE public.coupons (
    id bigint NOT NULL,
    code character varying(30) NOT NULL,
    description character varying(120) DEFAULT ''::character varying NOT NULL,
    percentage integer NOT NULL,
    valid_until date NOT NULL,
    usage_limit integer,
    uses_count integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT coupons_percentage_range CHECK (((percentage >= 1) AND (percentage <= 90)))
);

CREATE SEQUENCE public.coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;

CREATE TABLE public.cupcakes (
    id bigint NOT NULL,
    category_id bigint NOT NULL,
    name character varying(80) NOT NULL,
    description text NOT NULL,
    ingredients text DEFAULT ''::text NOT NULL,
    price numeric(8,2) NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    min_stock integer DEFAULT 5 NOT NULL,
    calories integer,
    fat_grams numeric(5,1),
    sugar_grams numeric(5,1),
    allergens character varying(200) DEFAULT ''::character varying NOT NULL,
    color character varying(7) DEFAULT '#f9a8d4'::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT cupcakes_price_positive CHECK ((price > (0)::numeric)),
    CONSTRAINT cupcakes_stock_not_negative CHECK ((stock >= 0))
);

CREATE SEQUENCE public.cupcakes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.cupcakes_id_seq OWNED BY public.cupcakes.id;

CREATE TABLE public.delivery_zones (
    id bigint NOT NULL,
    name character varying(80) NOT NULL,
    fee numeric(6,2) NOT NULL,
    eta_minutes integer DEFAULT 45 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT delivery_zones_fee_not_negative CHECK ((fee >= (0)::numeric))
);

CREATE SEQUENCE public.delivery_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.delivery_zones_id_seq OWNED BY public.delivery_zones.id;

CREATE TABLE public.favorites (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    cupcake_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE SEQUENCE public.favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.favorites_id_seq OWNED BY public.favorites.id;

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    order_id bigint,
    message character varying(255) NOT NULL,
    read boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;

CREATE TABLE public.order_items (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    cupcake_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(8,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT order_items_quantity_positive CHECK ((quantity > 0))
);

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;

CREATE TABLE public.orders (
    id bigint NOT NULL,
    code character varying(12) NOT NULL,
    customer_id bigint NOT NULL,
    courier_id bigint,
    coupon_id bigint,
    delivery_zone_id bigint,
    status character varying(30) DEFAULT 'paid'::character varying NOT NULL,
    fulfillment character varying(10) NOT NULL,
    delivery_address character varying(255),
    payment_method character varying(10) NOT NULL,
    card_last4 character varying(4),
    pix_code character varying(255),
    subtotal numeric(10,2) NOT NULL,
    discount numeric(10,2) DEFAULT 0.0 NOT NULL,
    shipping_fee numeric(10,2) DEFAULT 0.0 NOT NULL,
    total numeric(10,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT orders_total_not_negative CHECK ((total >= (0)::numeric))
);

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    order_id bigint NOT NULL,
    cupcake_id bigint NOT NULL,
    rating integer NOT NULL,
    delivery_rating integer NOT NULL,
    comment text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT reviews_delivery_rating_range CHECK (((delivery_rating >= 1) AND (delivery_rating <= 5))),
    CONSTRAINT reviews_rating_range CHECK (((rating >= 1) AND (rating <= 5)))
);

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(120) NOT NULL,
    email character varying(160) NOT NULL,
    phone character varying(20),
    password_digest character varying NOT NULL,
    role character varying(20) DEFAULT 'customer'::character varying NOT NULL,
    notifications_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT users_role_valid CHECK (((role)::text = ANY (ARRAY[('customer'::character varying)::text, ('admin'::character varying)::text, ('courier'::character varying)::text])))
);

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);

ALTER TABLE ONLY public.contact_logs ALTER COLUMN id SET DEFAULT nextval('public.contact_logs_id_seq'::regclass);

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);

ALTER TABLE ONLY public.cupcakes ALTER COLUMN id SET DEFAULT nextval('public.cupcakes_id_seq'::regclass);

ALTER TABLE ONLY public.delivery_zones ALTER COLUMN id SET DEFAULT nextval('public.delivery_zones_id_seq'::regclass);

ALTER TABLE ONLY public.favorites ALTER COLUMN id SET DEFAULT nextval('public.favorites_id_seq'::regclass);

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.contact_logs
    ADD CONSTRAINT contact_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.cupcakes
    ADD CONSTRAINT cupcakes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.delivery_zones
    ADD CONSTRAINT delivery_zones_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

CREATE INDEX index_addresses_on_user_id ON public.addresses USING btree (user_id);

CREATE UNIQUE INDEX index_categories_on_name ON public.categories USING btree (name);

CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);

CREATE INDEX index_contact_logs_on_courier_id ON public.contact_logs USING btree (courier_id);

CREATE INDEX index_contact_logs_on_order_id ON public.contact_logs USING btree (order_id);

CREATE UNIQUE INDEX index_coupons_on_code ON public.coupons USING btree (code);

CREATE INDEX index_cupcakes_on_category_id ON public.cupcakes USING btree (category_id);

CREATE UNIQUE INDEX index_delivery_zones_on_name ON public.delivery_zones USING btree (name);

CREATE INDEX index_favorites_on_cupcake_id ON public.favorites USING btree (cupcake_id);

CREATE UNIQUE INDEX index_favorites_on_user_id_and_cupcake_id ON public.favorites USING btree (user_id, cupcake_id);

CREATE INDEX index_notifications_on_order_id ON public.notifications USING btree (order_id);

CREATE INDEX index_notifications_on_user_id ON public.notifications USING btree (user_id);

CREATE INDEX index_order_items_on_cupcake_id ON public.order_items USING btree (cupcake_id);

CREATE INDEX index_order_items_on_order_id ON public.order_items USING btree (order_id);

CREATE UNIQUE INDEX index_orders_on_code ON public.orders USING btree (code);

CREATE INDEX index_orders_on_coupon_id ON public.orders USING btree (coupon_id);

CREATE INDEX index_orders_on_courier_id ON public.orders USING btree (courier_id);

CREATE INDEX index_orders_on_created_at ON public.orders USING btree (created_at);

CREATE INDEX index_orders_on_customer_id ON public.orders USING btree (customer_id);

CREATE INDEX index_orders_on_delivery_zone_id ON public.orders USING btree (delivery_zone_id);

CREATE INDEX index_orders_on_status ON public.orders USING btree (status);

CREATE INDEX index_reviews_on_cupcake_id ON public.reviews USING btree (cupcake_id);

CREATE UNIQUE INDEX index_reviews_on_order_id_and_cupcake_id ON public.reviews USING btree (order_id, cupcake_id);

CREATE INDEX index_reviews_on_user_id ON public.reviews USING btree (user_id);

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_19aaeaff7c FOREIGN KEY (cupcake_id) REFERENCES public.cupcakes(id);

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_2540dc0df6 FOREIGN KEY (delivery_zone_id) REFERENCES public.delivery_zones(id);

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_3dad120da9 FOREIGN KEY (customer_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_56bfd737ed FOREIGN KEY (courier_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.contact_logs
    ADD CONSTRAINT fk_rails_571486b730 FOREIGN KEY (order_id) REFERENCES public.orders(id);

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_69840110e1 FOREIGN KEY (cupcake_id) REFERENCES public.cupcakes(id);

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_74a66bd6c5 FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_rails_907a5e9f62 FOREIGN KEY (coupon_id) REFERENCES public.coupons(id);

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT fk_rails_a0bd012b8a FOREIGN KEY (cupcake_id) REFERENCES public.cupcakes(id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_b080fb4855 FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.cupcakes
    ADD CONSTRAINT fk_rails_c0d3fd6122 FOREIGN KEY (category_id) REFERENCES public.categories(id);

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT fk_rails_d15744e438 FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_rails_e3cb28f071 FOREIGN KEY (order_id) REFERENCES public.orders(id);

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_rails_eadb6874f1 FOREIGN KEY (order_id) REFERENCES public.orders(id);

ALTER TABLE ONLY public.contact_logs
    ADD CONSTRAINT fk_rails_f3f2a8edf7 FOREIGN KEY (courier_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_fd5a31cf2f FOREIGN KEY (order_id) REFERENCES public.orders(id);

