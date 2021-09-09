# 【名  称】JRA-VAN POG 指名者数抽出スクリプト
# 【仕  様】JRA-VAN POG ページで馬名を指定し、指名者の数を抽出する
# 【目  的】JRA-VAN POG 対策
# 【履  歴】試作

# Capybara + selenium-webdriver
require 'capybara'
require 'selenium-webdriver'
require 'webdrivers'
require 'csv'

# Capybaraの初期設定
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
      chrome_options: {
        args: %w[headless disable-gpu window-size=1280,800],
        w3c: false
      }
    )
  )
end
Capybara.javascript_driver = :selenium

# スクレイピングのフレーム
def start_scraping(url, &block)
  Capybara::Session.new(:selenium).tap do |session|
    session.visit url
    session.instance_eval(&block)
  end
end

# スクレイピング内容
start_scraping 'https://app.jra-van.jp/pog/MyPage.do?command=disp' do
  sleep 1

  # login
  puts 'ログイン中...'
  fill_in 'login_id', with: ENV['JRAVAN_ID']
  fill_in 'login_password', with: ENV['JRAVAN_PW']
  click_on 'ログインして次へ進む'
  sleep 1

  # 指名馬追加ページを開く
  puts '指名馬追加ページを開く...'
  execute_script 'addHorse();'
  sleep 1

  # 指名者数の取得
  puts '馬リスト読み込み...'
  horses_list = CSV.read('horses_list.csv').flatten # 馬リスト読み込み

  puts '指名者数を検索中...'
  horses_list.each do |horse_name|
    # 馬名で検索
    fill_in 'bamei', with: horse_name
    click_on '検索'
    sleep 1

    # 検索した馬の詳細ページを開く
    click_on horse_name
    sleep 1

    # windowの切換え
    switch_to_window(windows.last)

    # 指名者数の取得し、windowを閉じる
    owners = all('.formTitle_L')[3].text
    click_on '閉じる'
    sleep 1

    # windowの切換え
    switch_to_window(windows.first)

    # 馬名検索ページに戻る
    click_on '戻る'
    sleep 1

    # 馬名と指名者数の出力
    puts "#{horse_name}: #{owners}"
  end
end
