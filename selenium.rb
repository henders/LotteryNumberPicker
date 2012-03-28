require 'rubygems'
require 'selenium-webdriver'

ACCOUNT_EMAIL = 'off@intuit.com'
PASSWORD = 'tester'

@username = 'test_user_0224_5@intuit.com'
@randomNumber = Random.rand.to_s
wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds


driver = Selenium::WebDriver.for :chrome
driver.get "https://ttoqa25.turbotaxonline.intuit.com/open/registration/authtest.htm"

product = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "productid"))
product.select_by(:value, "TTO Basic Free(512)")
driver.find_element(:css, "#answerLayer span").click

# Select 'Create account' and accept license agreement
driver.find_element(:css, ".AuthNewUser a span").click
driver.find_element(:id, "legal2").click
driver.find_element(:css, ".LicAgModalContentContBtn a span").click

# Fill in new user details
driver.find_element(:id, "email").send_keys(ACCOUNT_EMAIL)
driver.find_element(:id, "email2").send_keys(ACCOUNT_EMAIL)
driver.find_element(:id, "userid").send_keys(@username)
driver.find_element(:id, "password").send_keys(PASSWORD)
driver.find_element(:id, "password2").send_keys(PASSWORD)

securityquestion = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "question"))
securityquestion.select_by(:index, 1)
driver.find_element(:id, "answer").send_keys("test")
# Click the create your user id button
driver.find_element(:css, "#answerLayer td[align=\"right\"] a span").click

# Click the start my 2010 return button
wait.until { driver.find_element(:id, 'titleLayer').text =~ /Let's Print Your User ID Info/ }
driver.find_element(:css, "#answerLayer a[tabindex=\"2\"] span").click


wait.until { driver.find_element(:id, "cat1") }
driver.find_element(:id, "cat1").click                # Click personal info navbar button


wait.until {driver.find_element(:id, 'titleLayer').text =~ /You & Your Familyasd/ }
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Tell Us What Happened to You Last Year/ }
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Work on Your Personal Info/ }

driver.find_element(:id, "edt~00").send_keys("first" + @randomNumber)
driver.find_element(:id, "edt~02").send_keys("last" + @randomNumber)
driver.find_element(:id, "edt~04").send_keys("321-36-7928")
driver.find_element(:id, "edt~05").send_keys("01/01/1977")
driver.find_element(:id, "edt~06").send_keys("worker bee")
driver.find_element(:id, "edt~07").send_keys("(858) 431-2155")
# Select California State
stateSelect = Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "combo~00"))
stateSelect.select_by(:text, 'California')
driver.find_element(:id, "Continue~00").click


wait.until { driver.find_element(:id, 'titleLayer').text =~ /Were You Married/ }
driver.find_element(:id, 'radio~00:0').click
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Do You Have Any Children or Other Dependents/ }
driver.find_element(:id, 'radio~01:0').click
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Where Do You Receive Your Mail/ }
driver.findElement(:id, "edt~00").send_keys("7535 Torrey Santa Fe Rd")
driver.findElement(:id, "edt~02").send_keys("San Diego")
driver.findElement(:id, "edt~03").send_keys("92129")
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Did You Live in Another State/ }
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Did You Make Money in Any Other States/ }
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /We've Chosen a Filing Status for You/ }
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Your Personal Info/ }
driver.find_element(:id, "cat2").click  # Click on "Federal Taxes'

wait.until { driver.find_element(:id, 'sub0') }
driver.find_element(:id, 'sub0').click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Let's Work on Your W-2/ }
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:id, 'titleLayer').text =~ /Let's Start With a Bit of Info From Your W-2/ }
driver.find_element(:id, "edt~00").send_keys("11111111111111")
driver.find_element(:id, "Continue~00").click

wait.until { driver.find_element(:name, "__upsell__") }
driver.switch_to.frame('__upsell__')
driver.find_element(:css, '#FORWARD_LAYER a span').click



