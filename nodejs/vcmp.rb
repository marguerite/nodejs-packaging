module Vcmp

    def self.comp(first="",op="",second="")

	fa,sa = [],[]
	fap = first.split(".")
	sap = second.split(".")
	fap.each_index {|i| fa[i] = fap[i].to_i}
	sap.each_index {|i| sa[i] = sap[i].to_i}

	case op
	when ">="
		if fa[0] > sa[0]
			return true
		elsif fa[0] == sa[0]
			if fa[1] > sa[1]
				return true
			elsif fa[1] == sa[1]
				if fa[2] > sa[2]
					return true
				elsif fa[2] == sa[2]
					return true
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	when ">"
                if fa[0] > sa[0]
                        return true
                elsif fa[0] == sa[0]
                        if fa[1] > sa[1]
                                return true
                        elsif fa[1] == sa[1]
                                if fa[2] > sa[2]
                                        return true
                                elsif fa[2] == sa[2]
                                        return false
                                else
                                        return false
                                end
                        else
                                return false
                        end
                else
                        return false
                end
	when "="
                if fa[0] > sa[0]
                        return false
                elsif fa[0] == sa[0]
                        if fa[1] > sa[1]
                                return false
                        elsif fa[1] == sa[1]
                                if fa[2] > sa[2]
                                        return false
                                elsif fa[2] == sa[2]
                                        return true
                                else
                                        return false
                                end
                        else
                                return false
                        end
                else
                        return false
                end
	when "<"
                if fa[0] > sa[0]
                        return false
                elsif fa[0] == sa[0]
                        if fa[1] > sa[1]
                                return false
                        elsif fa[1] == sa[1]
                                if fa[2] > sa[2]
                                        return false
                                elsif fa[2] == sa[2]
                                        return false
                                else
                                        return true
                                end
                        else
                                return true
                        end
                else
                        return true
                end
	when "<="
                if fa[0] > sa[0]
                        return false
                elsif fa[0] == sa[0]
                        if fa[1] > sa[1]
                                return false
                        elsif fa[1] == sa[1]
                                if fa[2] > sa[2]
                                        return false
                                elsif fa[2] == sa[2]
                                        return true
                                else
                                        return true
                                end
                        else
                                return true
                        end
                else
                        return true
                end
	end

    end

end

