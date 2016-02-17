module Semver

    def self.range2comp(range="")

        comparators = []

        # '1.2.3 || 4.5.6'
        if range.index('||')
            # "RPM can't handle 'or' conditional, by default we use the longest conditional
            # which usually the best
            temp = range.split("||")
            sa = []
            temp.each_index do |i|
               sa[i] = temp[i].size
            end
            big = 0
            sa.each_index {|i| big = i if sa[i] >= sa[big] }
            longest = temp[big].strip!
            comparators = range2comp(longest)
        elsif range.index(/\s-\s/)
            # 1.2.3 - 4.5.6, temp = ['1.2.3 ',' 4.5.6']
            temp = range.split('-')
            if temp[1].index('.')
               va = temp[1].strip!.split('.')
               if va.size < 3
                   comparators = [">=" + temp[0].strip!,"<" + va[0] + '.' + (va[1].to_i + 1).to_s +    '.0']
               else
                   comparators = [">=" + temp[0].strip!,"<=" + temp[1]]
               end
            else
               # 1.2.3 - 4
               comparators = [">=" + temp[0].strip!,"<" + (temp[1].strip!.to_i + 1).to_s + '.0.0']
            end
        elsif range.index(/\s/)
            tmp = range.split(/\s/)
	    if tmp.include?('>') || tmp.include?('>=') || tmp.include?('<') || tmp.include?('<=')
		tmp.each_slice(2) do |s|
		    comparators << s[0] + s[1]
		end
	    else
	        comparators = tmp
	    end
        else
            comparators = [range]
        end

        return comparators

    end

    def self.parse(name="",range="")

        comparators = range2comp(range)
        dep = {}
	
        comparators.each do |comparator|

                # the leading '=' or 'v' character is stripped
                comparator = comparator.gsub(/^=/,'') if comparator.index(/^=[0-9]/)
                comparator = comparator.gsub('v','') if comparator.index(/v[0-9]/)

                # deal with prerelease tag, eg '1.2.3-alpha.1', OBS doesn't know '-'
                comparator = comparator.gsub('-','.') if comparator.index(/-(alpha|beta|rc)/)
		# 1.0.2-1.2.3
                # operator, version string, version array
                op = comparator.gsub(/[0-9].*$/,'')
                vs = comparator.gsub(op,'') # if comparator = [], meaning no version, then vs is ""
                va = []

                # autocomplete version array
		# do the most weird case first
                # dateformat "1.0.2-1.2.3"
                if vs.index("-")
		    va = [vs,"0","0"]
                elsif vs.index(".")
                    #["1","0","7"]
                    vap = vs.split(".")
                    #["1","0"]
                    vap.push '0' if vap.size < 3
                    va = vap
                else
                    # no "." means version like "1"
                    vs = "0" if vs.empty?
                    va = [vs,'0','0']
                end

                # from now on, version_array.size = 3

                default_op = ["~","^","*",
                            ">",">=","<","<="]

                if default_op.include?(op)

                    case op
                    when ">"
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        
                        if dep.has_key?(name)
                            dep[name] << ">#{va[0]}.#{va[1]}.#{va[2]}"
                        else
                            dep[name] = [">#{va[0]}.#{va[1]}.#{va[2]}"]
                        end
                        
                    when ">="
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        
                        if dep.has_key?(name)
                            dep[name] << ">=#{va[0]}.#{va[1]}.#{va[2]}"
                        else
                            dep[name] = [">=#{va[0]}.#{va[1]}.#{va[2]}"]
                        end
                        
                    when "<"
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        
                        if dep.has_key?(name)
                            dep[name] << "<#{va[0]}.#{va[1]}.#{va[2]}"
                        else
                            dep[name] = ["<#{va[0]}.#{va[1]}.#{va[2]}"]
                        end
                        
                    when "<="
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        
                        if dep.has_key?(name)
                            dep[name] << "<=#{va[0]}.#{va[1]}.#{va[2]}"
                        else
                            dep[name] = ["<=#{va[0]}.#{va[1]}.#{va[2]}"]
                        end
                        
                    when "~"
                        if va[0] == '0'
                            if va[1].index(/x|X/)
                                high = "1.0.0"
                            else
                                high = '0.' + (va[1].to_i + 1).to_s + '.0'
                            end
                        else
                            if va[1].index(/x|X/) || va[1] == '0' && va[2] == '0'
                                high = (va[0].to_i + 1).to_s + '.0.0'
                            else
                                high = va[0] + '.' + (va[1].to_i + 1).to_s + '.0'
                            end
                        end
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        low = va[0] + '.' + va[1] + '.' + va[2]
                        
                        if dep.has_key?(name)
                            dep[name] << ">=#{low}"
                            dep[name] << "<#{high}"
                        else
                            dep[name] = [">=#{low}","<#{high}"]
                        end
                        
                    when "^"
                        if va[0] == '0'
                            if va[1] == '0'
                                if va[2].index(/x|X/)
                                    high = "0.1.0"
                                else
                                    high = "0.0." + (va[2].to_i + 1).to_s
                                end
                            else
                                high = '0.' + (va[1].to_i + 1).to_s + '.0'
                            end
                        else
                            high = (va[0].to_i + 1).to_s + '.0.0'
                        end
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        low = va[0] + '.' + va[1] + '.' + va[2]
                        
                        if dep.has_key?(name)
                            dep[name] << ">=#{low}"
                            dep[name] << "<#{high}"
                        else
                            dep[name] = [">=#{low}","<#{high}"]
                        end
                        
                    when "*"
                        
                        if dep.has_key?(name)
                            dep[name] << ">=0.0.0"
                        else
                            dep[name] = [">=0.0.0"]
                        end
                        
                    end

                else
                    if va[1].index(/x|X/)
                        
                        if dep.has_key?(name)
                            dep[name] << ">=#{va[0]}.0.0"
                            dep[name] << "<#{(va[0].to_i + 1)}.0.0"
                        else
                            dep[name] = [">=#{va[0]}.0.0","<#{(va[0].to_i + 1)}.0.0"]
                        end
                        
                    elsif va[2].index(/x|X/)
                        
                        if dep.has_key?(name)
                            dep[name] << ">=#{va[0]}.#{va[1]}.0"
                            dep[name] << "<#{va[0]}.#{(va[1].to_i + 1)}.0"
                        else
                            dep[name] = [">=#{va[0]}.#{va[1]}.0","<#{va[0]}.#{(va[1].to_i + 1)}.0"]
                        end    
                            
                    elsif va == ["0","0","0"]        
                        if dep.has_key?(name)
                            dep[name] << ">=0.0.0"
                        else
                            dep[name] = [">=0.0.0"]
                        end
                        
                    else
                      if va[0].index('-')
			if dep.has_key?(name)
			    dep[name] << ["=#{va[0]}"]
                        else
			    dep[name] = ["=#{va[0]}"]
			end
                      else
                        if dep.has_key?(name)
                            dep[name] << "=#{va[0]}.#{va[1]}.#{va[2]}"
                        else
                            dep[name] = ["=#{va[0]}.#{va[1]}.#{va[2]}"]
                        end
                      end
                    end
                end

        end

        return dep

    end
    
end

