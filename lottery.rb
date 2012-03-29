#!/usr/bin/env ruby

require 'date'

$debug = false

@picks = []

# Given a startdate, grab all the dates and drawings that fall between the start date and NOW
def getPreviousDrawings startDate
    @dates = []
    @numbers = []
    @numberprob = {}
    @megas= []
    @megaprob = {}

    lines = IO.readlines 'DownloadAllNumbers.txt'
    lines.each do |line|
        if line =~ /^\d+/
            line =~ /^\d+\s*(.*\d{4})\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
            d = Date.parse($1)
            if startDate < d
                @dates.push(d)
                @numbers.push([$2.to_i,$3.to_i,$4.to_i,$5.to_i,$6.to_i])
                @megas.push [$7.to_i]
            end
        end
    end
    puts @dates if $debug
end

# Given an array of number drawings and a number range, and how many numbers per drawing, fine the probability of being chosen for each number
# E.g. MegaMillion drawing (excluding megaball)
#   numbersDrawn = [[1,2,3,4,5], [2,3,4,5,6], [50,51,52,53,54], ...]
#   range = 56  -- i.e. range is 1..56
#   numPerDraw = 5 -- i.e. each drawing contains 5 numbers for megamillions
#   type = "Numbers" -- this is just for debugging messages
def getNumberDistribution numbersDrawn, range, numPerDraw, type

    numberFrequency = {}
    numberProbabilities = {}

    # maps of numbers 1-56 and their frequency, initialized to 0
    (1..range).each { |x| numberFrequency[x] = 0 }
    numbersDrawn.each do |numarray|
        numarray.each do |n|
            numberFrequency[n] += 1
        end
    end

    puts "#{type} Distribution: " if $debug
    numberFrequency.values.uniq.sort.each do |value|
        # Print the corresponding key
        numberFrequency.keys.sort.each do |key|
            if numberFrequency[key] == value
                probability = (numPerDraw * value) / (range * numbersDrawn.length)
                numberProbabilities[probability] = numberProbabilities[probability] ? numberProbabilities[probability].push(key) : [key]
                puts "#{type}: #{key}  - appeared #{value} times - probability #{probability}" if $debug
            end
        end
    end

    puts "#{type} Probability Map: " if $debug
    numberProbabilities.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end

    return numberProbabilities
end

# Get the number distribution probabilities for both the 5-draw and the megaball
def getNumberDistributions startDate
    getPreviousDrawings startDate

    @numberprob = getNumberDistribution @numbers, 56.0, 5.0, "Numbers"
    @megaprob = getNumberDistribution @megas, 46.0, 1.0, "Mega"
end

# Given a ProbabilityMap, choose 'numberToDraw' numbers randomly in a weighted fashion
# E.g.
#   probabilityMap = { 0.001 => [1,3,5], 0.0025 => [32,33], 0.25 => [2,4,7,8,9,10,21,22,24], ...... }
#   numberToDraw = 5
#
#   return => [2,5,11,21,22]
def pickNumbers probabilityMap, numberToDraw
    # Start with 5 rows of mixtures of most popular numbers picked at random but weighted against their probability
    # 1. Sum the weights, i.e. probabilities
    totalweight = 0
    probabilityMap.keys.each { |key| totalweight += key }

    puts "Picking Numbers...." if $debug
    pick = []
    numberprob = probabilityMap
    for i in 0 .. (numberToDraw-1)
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
    return pick
end

# Pick the MegaMillion Winning numbers, 5 numbers between 1..56 and 1 megaball between 1..46
def pickWinningNumbers
    firstFive = pickNumbers @numberprob, 5
    mega = pickNumbers @megaprob, 1

    @picks.push (firstFive + mega)
end

# Get Hash of 'Lotto Number' => 'Number of weeks since last seen'
def getNumberAgeArray numbersDrawn, range, type
    # initialize the hash of numbers with their number of weeks since seen
    numberAge = {}
    for i in 0 .. (numbersDrawn.length-1)
        numbersDrawn[i].each do |n|
            if !numberAge[n]
                numberAge[n] = i
            end
        end
    end
    # create entries for any numbers that havent been seen
    (1 .. range).each do |i| 
        if !numberAge[i]
            numberAge[i] = @dates.length
        end
    end
    puts "#{type} Age Map" if $debug
    puts numberAge if $debug
    return numberAge
end

def printProbabilityMap probabilityMap
    probabilityMap.each do |key,value|
        puts "#{key} - #{value}" if $debug
    end
end

# Given an alrogithm, apply it to the current probability to weight it differently
def applyProbabilitySkew probabilityMap, numberAge, algorithm
    newnumberprob = {}

    puts "Old Probability Map: " if $debug
    printProbabilityMap probabilityMap

    probabilityMap.keys.each do |key|
        probabilityMap[key].each do |num|
            # for each number in the array, create a new probability matrix with modified probabilities
            newProb = algorithm.call(key, numberAge[num])
            newnumberprob[newProb] = newnumberprob[newProb] ? newnumberprob[newProb].push(num) : [num]
            puts "Number: #{num} - Old prob = #{key} - New Prob = #{key} + (#{key} * #{numberAge[num]}) = #{newProb}" if $debug 
        end
    end

    puts "New Probability Map: " if $debug
    printProbabilityMap newnumberprob

    return newnumberprob
end

##############################################################################################################
## The Number Picking APIs are below
##############################################################################################################

# The basic Number Picking Algorithm: Just uses number distribution
def pickNumbersBasedOnDistribution startDate
    # Initialize
    getNumberDistributions startDate

    pickWinningNumbers
end

def getNumbersThatHaveNotAppearedInAgesLinear startDate
    # Initialize
    getNumberDistributions startDate
    numberAge = getNumberAgeArray @numbers, 56, "Numbers"
    megaAge = getNumberAgeArray @numbers, 46, "Mega"

    # Magic number = weight * number of weeks since seen
    algoritm = lambda {|key,age| key + (key * age)}
    @numberprob = applyProbabilitySkew @numberprob, numberAge, algoritm
    @megaprob = applyProbabilitySkew @megaprob, megaAge, algoritm

    pickWinningNumbers
end

def getNumbersThatHaveNotAppearedInAgesExponential startDate
    # Initialize
    getNumberDistributions startDate
    numberAge = getNumberAgeArray @numbers, 56, "Numbers"
    megaAge = getNumberAgeArray @numbers, 46, "Mega"

    # Magic number = (2 ^ (0.000025 * x) ) -1
    algoritm = lambda {|key,age| key + (2 ** (0.000025 * age) ) -1}
    @numberprob = applyProbabilitySkew @numberprob, numberAge, algoritm
    @megaprob = applyProbabilitySkew @megaprob, megaAge, algoritm

    pickWinningNumbers
end


def getNumbersThatHaveNotAppearedInAgesLogarithmic startDate
    # Initialize
    getNumberDistributions startDate
    numberAge = getNumberAgeArray @numbers, 56, "Numbers"
    megaAge = getNumberAgeArray @numbers, 46, "Mega"

    # Magic number = (log2(x))*0.001
    algoritm = lambda {|key,age| key + (Math.log2(age + 1) * 0.001)}
    @numberprob = applyProbabilitySkew @numberprob, numberAge, algoritm
    @megaprob = applyProbabilitySkew @megaprob, megaAge, algoritm

    pickWinningNumbers
end

(0..0).each { pickNumbersBasedOnDistribution Date.new(2012,3,1) }
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


