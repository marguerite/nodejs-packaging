module Semver

    def range2comp(range="")

        comparators = []

        # '1.2.3 || 4.5.6'
        if range.index('||')
            p "RPM can't handle 'or' conditional, please check manually: #{range}"
        elsif range.index(/\s-\s/)
            # 1.2.3 - 4.5.6, comptemp = ['1.2.3 ',' 4.5.6']
            comptemp = range.split('-')
            if comptemp[1].index('.')
               va = comptemp[1].strip!.split('.')
               if va.size < 3
                   comparators = [">=" + comptemp[0].strip!,"<" + va[0] + '.' + (va[1].to_i + 1).to_s +    '.0']
               else
                   comparators = [">=" + comptemp[0].strip!,"<=" + comptemp[1]]
               end
            else
               # 1.2.3 - 4
               comparators = [">=" + comptemp[0].strip!,"<" + (comptemp[1].strip!.to_i + 1).to_s + '.0.0']
            end
        elsif range.index(/\s/)
            comparators = range.split(/\s/)
        else
            comparators = [range]
        end

        return comparators

    end

    def self.parse(name="",range="")

        comparators = range2comp(range)
        dep = []

        comparators.each do |comparator|

                # the leading '=' or 'v' character is stripped
                comparator = comparator.gsub(/^=/,'') if comparator.index(/^=[0-9]/)
                comparator = comparator.gsub('v','') if comparator.index(/v[0-9]/)

                # deal with prerelease tag, eg '1.2.3-alpha.1', OBS doesn't know '-'
                comparator = comparator.gsub('-','.') if comparator.index(/-(alpha|beta|rc)/)
                
                # operator, version string, version array
                op = comparator.gsub(/[0-9].*$/,'')
                vs = comparator.gsub(op,'') # if comparator = [], meaning no version, then vs is ""
                va = []
                
                # autocomplete version array
                if vs.index(".")
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
                        dep << ["npm(" + name + ") > " + va[0] + "." + va[1] + "." + va[2]]
                    when ">="
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        dep << ["npm(" + name + ") >= " + va[0] + "." + va[1] + "." + va[2]]
                    when "<"
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        dep << ["npm(" + name + ") < " + va[0] + "." + va[1] + "." + va[2]]
                    when "<="
                        va[1] = "0" if va[1].index(/x|X/)
                        va[2] = "0" if va[2].index(/x|X/)
                        dep << ["npm(" + name + ") <= " + va[0] + "." + va[1] + "." + va[2]]
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
                        
                        dep << "npm(" + name + ") >= " + low
                        dep << "npm(" + name + ") < " + high
                        
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
                        
                        dep << "npm(" + name + ") >= " + low
                        dep << "npm(" + name + ") < " + high
                    when "*"
                        dep << "npm(" + name + ") >= 0.0.0"
                    end

                else
                    if va[1].index(/x|X/)
                        dep << "npm(" + name + ") >= " + va[0] + ".0.0"
                        dep << "npm(" + name + ") < " + (va[0].to_i + 1).to_s + ".0.0"
                    elsif va[2].index(/x|X/)
                        dep << "npm(" + name + ") >= " + va[0] + '.' + va[1] + '.0'
                        dep << "npm(" + name + ") < " + va[0] + '.' + (va[1].to_i + 1).to_s + '.0'
                    elsif va == ["0","0","0"]
                        dep << "npm(" + name + ") >= 0.0.0"
                    else
                        dep << "npm(" + name + ") = " + va[0] + "." + va[1] + "." + va[2]
                    end
		end

            end
            
        return dep

    end
    
end
