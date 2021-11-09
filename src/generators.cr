require "random"
require "./entity"

module Tme
  ALPHABET_FIRST = ('a'..'z').to_a
  ALPHABET_LAST  = ALPHABET_FIRST + ('0'..'9').to_a
  ALPHABET       = ALPHABET_LAST + ['_']
  PROB_TABLE     = [3.341185004830632e-41,
                    1.236238451787334e-39,
                    4.453799611439233e-38,
                    1.603401271968172e-36,
                    5.772247920270425e-35,
                    2.0780092847092026e-33,
                    7.480833428294315e-32,
                    2.6931000342193655e-30,
                    9.695160123193057e-29,
                    3.490257644349534e-27,
                    1.2564927519658324e-25,
                    4.523373907076997e-24,
                    1.628414606547719e-22,
                    5.862292583571788e-21,
                    2.1104253300858436e-19,
                    7.597531188309038e-18,
                    2.7351112277912534e-16,
                    9.846400420048513e-15,
                    3.544704151217464e-13,
                    1.2760934944382872e-11,
                    4.5939365799778334e-10,
                    1.65381716879202e-08,
                    5.953741807651273e-07,
                    2.1433470507544583e-05,
                    0.0007716049382716049,
                    0.027777777777777776,
                    1.0]

  def self.random_entity
    r = Random.rand
    i = 0
    while PROB_TABLE[i] < r
      i += 1
    end
    l = 5 + i
    username : Array(Char) = [ALPHABET_FIRST.sample]
    (l - 2).times {
      username <<= ALPHABET.sample
    }
    username <<= ALPHABET_LAST.sample
    res = username.join
    if res.includes? "__"
      random_entity
    else
      NotChecked.new res
    end
  end

  MUTS = {
    'a' => '4',
    'b' => '6',
    'e' => '3',
    'f' => '8',
    'g' => '9',
    'i' => '1',
    'l' => '1',
    'o' => '0',
    's' => '5',
    't' => '7',
    'z' => '2',
  }

  def self.generate_mutations(s : String, extended : Bool = false, numbers : Bool = false)
    res = _generate_mutations(s)
    res = _generate_mutations_extended(res) if extended
    res.select /^[^0-9_].{3,}[^_]$/
  end

  private def self._generate_mutations(s : String) : Array(String)
    case
    when s == ""
      [""]
    when MUTS.has_key?(s[0])
      res = [] of String
      _generate_mutations(s[1..]).each { |ss|
        res <<= s[0] + ss
        res <<= MUTS[s[0]] + ss
      }
      res
    else
      _generate_mutations(s[1..]).map { |ss| s[0] + ss }
    end
  end

  private def self._generate_mutations_extended(arr) : Array(String)
    res = [] of String
    subres = [] of String
    arr.each { |s|
      subres <<= s
      subres <<= "xxx" + s
      subres <<= "xxx_" + s
    }
    subres.each { |s|
      res <<= s
      res <<= s + "xxx"
      res <<= s + "_xxx"
    }
    res
  end
end
