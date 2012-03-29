#!/usr/bin/env ruby

require 'date'

$debug = true

@picks = []

def getPreviousDrawings startDate
    @dates = []
    @numbers = []
    @numberfreq = {}
    @numberprob = {}
    @megas= []
    @megafreq = {}
    @megaprob = {}

    lines = IO.readlines 'DownloadAllNumbers.txt'
    lines.each do |line|
        if line =~ /^\d+/
            line =~ /^\d+\s*(.*\d{4})\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
            d = Date.parse($1)
            if startDate < d
                @dates.push(d)
                @numbers.push([$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i])
                @megas.push $7.to_i
            end
        end
    end
    puts @dates if $debug
end

def getNumberDistribution startDate
    getPreviousDrawings startDate

    # maps of numbers 1-56 and their frequency, initialized to 0
    (1..56).each { |x| @numberfreq[x] = 0 }
    @numbers.each do |numarray|
        numarray.each do |n|
            n = n.to_i
            @numberfreq[n] += 1
        end
    end

    puts "Number Distribution: " if $debug
    @numberfreq.values.uniq.sort.each do |value|
        # Print the corresponding key
        @numberfreq.keys.sort.each do |key|
            if @numberfreq[key] == value
                probability = (5.0 * value) / (56.0 * @numbers.length)
                @numberprob[probability] = @numberprob[probability] ? @numberprob[probability].push(key) : [key]
                puts "Number: #{key}  - appeared #{value} times - probability #{probability}" if $debug
            end
        end
    end

    puts "Numbers Probability Map: " if $debug
    @numberprob.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end

    # Do same for MegaBall
    # maps of numbers 1-46 and their frequency, initialized to 0
    (1..46).each { |x| @megafreq[x] = 0 }
    @megas.each do |n|
        @megafreq[n] += 1
    end
    @megafreq.values.uniq.sort.each do |value|
        # Print the corresponding key
        @megafreq.keys.sort.each do |key|
            if @megafreq[key] == value
                probability = value / (46.0 * @megas.length)
                @megaprob[probability] = @megaprob[probability] ? @megaprob[probability].push(key) : [key]
                puts "Mega Number: #{key}  - appeared #{value} times - probability #{probability}" if $debug
            end
        end
    end
    puts "Mega Probability Map: " if $debug
    @megaprob.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end
end


def pickNumbers
    # Start with 5 rows of mixtures of most popular numbers picked at random but weighted against their probability
    # 1. Sum the weights, i.e. probabilities
    totalweight = 0
    @numberprob.keys.each { |key| totalweight += key }

    puts "Picking Numbers...." if $debug
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
    print "Picked: " + pick.sort.to_s if $debug
    # Pick the Mega
    totalweight = 0.0
    @megaprob.keys.each { |key| totalweight += key }

    rnd = rand(0 .. totalweight)
    puts "picked #{rnd} from #{totalweight}" if $debug
    @megaprob.keys.sort.reverse.each do |prob|
        if rnd <= prob
            puts "matched prob #{prob} with rnd #{rnd}" if $debug
            puts " - Mega = #{@megaprob[prob]}\n" if $debug
            pick.push @megaprob[prob]
            break
        end
        rnd -= prob
    end
    @picks.push pick
end

def pickWinningNumbers
    firstFive = pickNumbers @numberprob, 5
    mega = pickNumbers @megaprob, 1

    @picks.push (firstFive + mega)
end

def pickNumbersBasedOnDistribution startDate
    # Initialize
    getNumberDistribution startDate

    pickNumbers
end

def getNumberAgeArray
    # initialize the hash of numbers with their number of weeks since seen
    numberAge = {}
    for i in 0 .. (@numbers.length-1)
        @numbers[i].each do |n|
            if !numberAge[n]
                numberAge[n] = i
            end
        end
    end
    # create entries for any numbers that havent been seen
    (0..55).each do |i| 
        if !numberAge[i]
            numberAge[i] = @dates.length
        end
    end
    puts "Age Map" if $debug
    puts numberAge if $debug
    return numberAge
end

def updateNumberProb newnumberprob
    puts "Old Probability Map: " if $debug
    @numberprob.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end

    @numberprob = newnumberprob

    puts "New Probability Map: " if $debug
    @numberprob.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end
end

def getNumbersThatHaveNotAppearedInAgesLinear startDate
    # Initialize
    getNumberDistribution startDate
    numberAge = getNumberAgeArray
    newnumberprob = {}

    @numberprob.keys.each do |key|
        @numberprob[key].each do |num|
            # for each number in the array, create a new probability matrix with modified probabilities
            # Magic number = weight * number of weeks since seen
            newProb = key + (key * numberAge[num])
            newnumberprob[newProb] = newnumberprob[newProb] ? newnumberprob[newProb].push(num) : [num]
            puts "Number: #{num} - Old prob = #{key} - New Prob = #{key} + (#{key} * #{numberAge[num]}) = #{newProb}" if $debug 
        end
    end

    updateNumberProb newnumberprob

    pickNumbers
end

def getNumbersThatHaveNotAppearedInAgesExponential startDate
    # Initialize
    getNumberDistribution startDate
    numberAge = getNumberAgeArray

    newnumberprob = {}

    @numberprob.keys.each do |key|
        @numberprob[key].each do |num|
            # for each number in the array, create a new probability matrix with modified probabilities
            # Magic number = (2 ^ (0.000025 * x) ) -1
            newProb = key + (2 ** (0.000025 * numberAge[num]) ) -1
            newnumberprob[newProb] = newnumberprob[newProb] ? newnumberprob[newProb].push(num) : [num]
            puts "Number: #{num} - Old prob = #{key} - New Prob = #{key} + 2 ^ (0.000025 * #{numberAge[num]}) -1 = #{newProb}" if $debug
        end
    end

    updateNumberProb newnumberprob

    pickNumbers
end


def getNumbersThatHaveNotAppearedInAgesLogarithmic startDate
    # Initialize
    getNumberDistribution startDate
    numberAge = getNumberAgeArray

    newnumberprob = {}

    @numberprob.keys.each do |key|
        @numberprob[key].each do |num|
            # for each number in the array, create a new probability matrix with modified probabilities
            # Magic number = (log2(x))*0.001
            newProb = key + (Math.log2(numberAge[num] + 1) * 0.001)
            newnumberprob[newProb] = newnumberprob[newProb] ? newnumberprob[newProb].push(num) : [num]
            puts "Number: #{num} - Old prob = #{key} - New Prob = #{key} + (log2(#{numberAge[num]}) * 0.001) = #{newProb}" if $debug 
        end
    end

    updateNumberProb newnumberprob

    pickNumbers
end

(0..0).each { pickNumbersBasedOnDistribution Date.new(2012,3,1) }
exit 1
(0..2).each { pickNumbersBasedOnDistribution Date.new(2010,6,1) }
(0..2).each { pickNumbersBasedOnDistribution Date.new(2011,1,1) }

(0..2).each { getNumbersThatHaveNotAppearedInAgesLinear Date.new(2005,1,1) }
(0..2).each { getNumbersThatHaveNotAppearedInAgesLinear Date.new(2010,6,1) }
(0..2).each { getNumbersThatHaveNotAppearedInAgesLinear Date.new(2011,1,1) }

(0..2).each { getNumbersThatHaveNotAppearedInAgesExponential Date.new(2005,1,1) }
(0..2).each { getNumbersThatHaveNotAppearedInAgesExponential Date.new(2010,6,1) }
(0..2).each { getNumbersThatHaveNotAppearedInAgesExponential Date.new(2011,1,1) }

(0..2).each { getNumbersThatHaveNotAppearedInAgesLogarithmic Date.new(2005,1,1) }
(0..2).each { getNumbersThatHaveNotAppearedInAgesLogarithmic Date.new(2010,6,1) }
(0..2).each { getNumbersThatHaveNotAppearedInAgesLogarithmic Date.new(2011,1,1) }


puts "Check for Duplicates..."
for i in 0..@picks.length
    for j in (i+1) .. @picks.length
        if @picks[i] == @picks[j]
            puts "Duplicate Found: #{@picks[i]}"
        end
    end
end

puts "Picked numbers:"
@picks.each do |pick|
    (0..4).each {|x| print "#{pick[x]} : " }
    puts " Mega = #{pick[5]}"
end


