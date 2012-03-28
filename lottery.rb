#!/usr/bin/env ruby

require 'nokogiri'
require 'date'

$debug = false


def getPreviousDrawings startDate
    @dates = []
    @numbers = []
    @numberfreq = {}
    @numberprob = {}
    @megas= []
    @megafreq = {}
    @megaprob = {}

    file = File.open 'megamillions.html'
    htmldoc = Nokogiri::HTML(file)

    items = htmldoc.css("div#scrollcontent div")

    items.each do |item|
        puts "I: " + item
        dateshtml = item.css("div.num_date")
        puts "A: " + dateshtml.text
        dstr = dateshtml.text.gsub(/^.*>(\d+\/\d+\/\d+).*$/, '\1')
        d = Date.strptime(dstr, "%m/%d/%Y")
        puts d
        if startDate < d
            @dates.push(d)
#            numbershtml = htmldoc.css("div.num_num")
#            megahtml = htmldoc.css("div.num_mb")
        end
    end
#    numbershtml.each {|node| @numbers.push node.text.split('-')}
 #   megahtml.each {|node| @megas.push node.text.split(' ')[2].to_i}

    puts @dates
    file.close
end

def getNumberDistribution startDate
    getPreviousDrawings startDate

    # maps of numbers 1-56 and their frequency
    @numbers.each do |numarray|
        numarray.each do |n|
            n = n.to_i
            @numberfreq[n] = @numberfreq[n] ? @numberfreq[n] += 1 : 1
        end
    end

    puts "Number Distribution: " if $debug
    @numberfreq.values.uniq.sort.each do |value|
        # Print the corresponding key
        @numberfreq.keys.sort.each do |key|
            if @numberfreq[key] == value
                probability = (5.0 * value) / (56.0 * @numbers.length)
                @numberprob[probability] = @numberprob[probability] ? @numberprob[probability].push(key) : @numberprob[probability] = [key]
                puts "Number: #{key}  - appeared #{value} times - probability #{probability}" if $debug
            end
        end
    end

    puts "Probability Map: " if $debug
    @numberprob.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end

    # Do same for MegaBall
    @megas.each do |n|
        @megafreq[n] = @megafreq[n]? @megafreq[n] += 1 : 1
    end
    @megafreq.values.uniq.sort.each do |value|
        # Print the corresponding key
        @megafreq.keys.sort.each do |key|
            if @megafreq[key] == value
                prob = value / (46.0 * @megas.length)
                @megaprob[prob] = key
                puts "Mega Number: #{key}  - appeared #{value} times - probability #{prob}" if $debug
            end
        end
    end
end

def pickNumbersBasedOnDistributionForDateRange startDate
    # Initialize
    getNumberDistribution startDate

    # Start with 5 rows of mixtures of most popular numbers picked at random but weighted against their probability
    # 1. Sum the weights, i.e. probabilities
    totalweight = 0
    @numberprob.keys.each { |key| totalweight += key }

    pick = []
    numberprob = @numberprob
    for i in 0..4
        rnd = rand(0 .. totalweight)
        puts "picked #{rnd} from #{totalweight}" if $debug
        numberprob.keys.sort.reverse.each do |prob|
            if rnd <= prob
                puts "matched prob #{prob} with rnd #{rnd}" if $debug
                # We found the probablility, now match it randomly to the numbers that match that probability
                pick[i] = numberprob[prob][rand(0 .. (numberprob[prob].length-1))]
                # remove this number from being picked in this round, and remove empty arrays form probability hash
                numberprob[prob].delete pick[i]
                if numberprob[prob].length == 0
                    numberprob.delete prob
                    puts "removed empty array, updating weight" if $debug
                    totalweight = 0
                    numberprob.keys.each { |key| totalweight += key }
                end
                break
            end
            rnd -= prob
        end
    end
    puts "Picked: "
    puts pick.sort

    # Pick the Mega
    totalweight = 0.0
    @megaprob.keys.each { |key| totalweight += key }

    rnd = rand(0 .. totalweight)
    puts "picked #{rnd} from #{totalweight}" if $debug
    @megaprob.keys.sort.reverse.each do |prob|
        if rnd <= prob
            puts "matched prob #{prob} with rnd #{rnd}" if $debug
            puts "#{@megaprob[prob]} - Mega\n\n"
            break
        end
        rnd -= prob
    end
end


def getClosestAssoiciations 

end


pickNumbersBasedOnDistributionForDateRange Date.new(2012,3,1)

