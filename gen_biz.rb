require "date"

DAY = 86400.0

TODAY = DateTime.now

FILE_OFFSET = 180

CSV_HEADERS = %w(
  order_id
  owner
  order_date
  ship_date
  customer_name
  customer_company
  customer_industry
  product_name  
  parent_sku
  sku
  unit_price
  quantity
  total
  order_status
)

SKU_BASE = %w(
  ES
  KB
  FB
  LS
)

OWNER_NAME = %w(
  山崎
  森
  池田
  橋本
  安倍
  石川
)

CUSTOMER_NAME = %w(
  佐藤
  鈴木
  田中
  高橋
  伊藤
  渡辺
  山本
  中村
  小林
  加藤
  吉田
  山田
  佐々木
  山口
  松本
  井上
  木村
  林
  斎藤
  清水
)


PRODUCT = [
]

COMPANY = [
  {
    name: "株式会社ABC",
    industry: "it"
  },
  {
    name: "ログサーチ株式会社",
    industry: "it"
  },
  {
    name: "ファイルスタッシュ合同会社",
    industry: "it"
  },
  {
    name: "エラス株式会社",
    industry: "it"
  },
  {
    name: "全国大学",
    industry: "education"
  },
  {
    name: "近所大学",
    industry: "education"
  },
  {
    name: "財務省",
    industry: "publicsector"
  },
  {
    name: "財務省",
    industry: "publicsector"
  },
  {
    name: "株式会社ケミカルティック",
    industry: "material"
  },
  {
    name: "ウィンログ製紙",
    industry: "material"
  },
  {
    name: "メトリック製薬",
    industry: "medical"
  },
  {
    name: "ビート製菓",
    industry: "food"
  },
  {
    name: "エージェント航空",
    industry: "transportation"
  },
  {
    name: "ログスタッシュ電鉄",
    industry: "transportation"
  },
  {
    name: "ハート通信",
    industry: "telco"
  },
  {
    name: "ジャーナル電機",
    industry: "manufacturing"
  }
]

# DB data generators
def gen_product_db
  SKU_BASE.each do |sb|
    10.times do |indx|
      product = {}
      product[:parent_sku] = "%s" % sb
      product[:sku] = "%s%#05d" % [sb, indx + 1]
      product[:name] = 'product-' + product[:sku]
      product[:unit_price] = rand(1..100) * 10000

      PRODUCT << product
    end
  end
end
def gen_company_db
  COMPANY.each do |c|
    c[:employee] = CUSTOMER_NAME.sample(rand(2..5))
  end
end

# CSV data generators
def gen_order_id(id)
  "%#08d" % id
end

def gen_owner(customer_industry)
  owner = case customer_industry
  when "it" then
    OWNER_NAME[0]
  when "education", "publicsector" then
    OWNER_NAME[1]
  when "material", "manufacturing" then
    OWNER_NAME[2]
  when "telco" then
    OWNER_NAME[3]
  when "food", "medical" then
    OWNER_NAME[4]
  when "transportation" then
    OWNER_NAME[5]
  else
    OWNER_NAME[5]
  end

  owner
end

def gen_order_date(current_date)
  order_date = current_date.strftime("%FT%T%:z")
  ship_date = current_date + [7, 14, 30, 45, 60, 120].sample

  [order_date, ship_date]
end

def gen_customer
  target = COMPANY.sample

  name = target[:employee].sample
  company = target[:name]
  industry = target[:industry]

  [name, company, industry]
end

def gen_product(customer_industry, id)
  offset_weight = id / 30
  target = if ["it", "telco"].include?(customer_industry)
             PRODUCT.select{|p| p[:sku].start_with?("ES")}.sample
           else
             PRODUCT.sample
           end
  product = target[:name]
  parent_sku = target[:parent_sku]
  sku = target[:sku]
  unit_price = target[:unit_price]
  quantity = if ["it", "telco"].include?(customer_industry)
               rand(5..100)
             else
               rand(1..50)
             end
  quantity = quantity * ( 1 + ( offset_weight / 10000.0 ) )
  total = unit_price * quantity

  [product, parent_sku, sku, unit_price, quantity, total]
end

def gen_order_status(order_date, ship_date)
  status = if TODAY >= ship_date
    "shipped"
  else
    "ordered"
  end
end

def gen_csv_row(id, time)
  csv_row = []

  order_id = gen_order_id(id)
  order_date, ship_date = gen_order_date(time)
  customer_name, customer_company, customer_industry = gen_customer
  owner = gen_owner(customer_industry)
  product_name, parent_sku, sku, unit_price, quantity, total = gen_product(customer_industry, id)
  order_status = gen_order_status(order_date, ship_date)

  CSV_HEADERS.each do |ch| csv_row << eval(ch)
  end

  csv_row.join(',')
end

################
# # # MAIN # # #
################

gen_product_db
gen_company_db

init_time = TODAY - 365
current_time = init_time
day_offset = current_time

ind = 0

f = nil

while true
  if day_offset <= current_time
    day_offset = day_offset + FILE_OFFSET
    f.close unless f.nil?
    f = File.open("businessdata#{sprintf("%04d", (current_time - init_time).to_i)}.csv", 'w') 
    f << CSV_HEADERS.join(',')
    f << "\n"
  end

  f << gen_csv_row(ind, current_time)
  f << "\n"

  if current_time.day < 6 
    current_time += (rand(1..1000) / DAY)
  elsif current_time.day < 13
    current_time += (rand(1..800) / DAY)
  elsif current_time.day < 20
    current_time += (rand(1..600) / DAY)
  elsif current_time.day < 26
    current_time += (rand(1..500) / DAY)
  else
    current_time += (rand(1..450) / DAY)
  end
  # # Check for weekend or Friday after 5pm
  # while current_time.hour >= 19 || [0, 6].include?(current_time.wday)
  #   current_time = DateTime.new(current_time.year, current_time.month, current_time.day, 9, 0, 0, current_time.zone).next_day
  # end

  ind += 1
  break if current_time > (TODAY + 365)
end

#################
# # # /MAIN # # #
#################

f.close
