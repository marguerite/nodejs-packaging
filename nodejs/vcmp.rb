module Vcmp

	# first: 1.0.0-1.2.3
	# second: 1.0.0-beta.2
	# first < second in nodejs

	def to_arr(str="")

		if str.index("-")
		    maj,min = [],[]
		    a = str.split("-") # ["1.0.0","beta.2"]
		    maj = a[0].split(".") # ["1","0","0"]
		    if a[1].index(".")
		    	min = a[1].split(".") # ["beta","2"]
		    else
			min = [a[1]] #["beta"]
		    end
		    return [maj,min]
		else
		    return [str.split(".")]
		end

	end

	def majcomp(fi=[],se=[])
		# first: ["1","0","0"]
		# second: ["1","0","1"]
		result = 0
		3.times do |i|
			expr = fi[i].to_i - se[i].to_i
			if expr > 0
				result = 1
				break
			elsif expr == 0
				if i == 3
					result = 0
				else
					next
				end
			else
				result = -1
				break
			end
		end
		return result
	end

	def is_beta(arr=[])

		str = arr.to_s
		if str.index(/alpha|beta|rc|ga/)
			return 1
		else
			return -1
		end

	end

	def betacomp(fi=[],se=[])
		#fi: ["beta","1"]
		#se: ["alpha","2"]
		# alpha < beta < rc < ga
		fif,sef = "",""
		result = 0

		if fi[0][0] != "g"
			fif = fi[0][0]
		else
			fif = "q"
		end

		if se[0][0] != "g"
			sef = se[0][0]
		else
			sef = "q"
		end

		if fif > sef
			result = 1
		elsif fif == sef
			result = majcomp(fi[1],se[1])
		else
			result = -1
		end

	end

	def arr_fix(arr=[])

		size = arr.size
		gap = 3 - size

		if gap > 0
			gap.times { arr << "0" }
		end

		return arr

	end

	def mincomp(fi=[],se=[])
		#fi: ["1","2","3"]
		#se: ["beta","2"]
		result = 0
		if fi.empty? && ! se.empty?
			result = 1
		elsif ! fi.empty? && se.empty?
			result = -1
		elsif fi.empty? && se.empty?
			result = 0
		else
			fi,se = arr_fix(fi),arr_fix(se)
			fib,seb = is_beta(fi),is_beta(se)

			if fib > 0 && seb > 0
				result = betacomp(fi,se)
			elsif fib > 0 && seb < 0
				result = 1
			elsif fib < 0 && seb > 0
				result = -1
			else
				result = majcomp(fi,se)	
			end
		end
		return result
	end

	def comp(first="",op="",second="")

		fa,sa = to_arr(first),to_arr(second)
		#fa: [["1", "0", "0"], ["1", "2", "3"]]
		#sa: [["1", "0", "0"], ["beta", "2"]]
		fa_maj = fa[0]
		sa_maj = sa[0]
		fa_min,sa_min = [],[]
		fa_min = fa[1] if fa.size > 1
		sa_min = sa[1] if sa.size > 1
		maj_result = majcomp(fa_maj,sa_maj)
		min_result = mincomp(fa_min,sa_min)

		case op
		when "<"
		   if maj_result < 0
			return true 
		   elsif maj_result == 0
			if min_result > 0
				return false
			elsif min_result < 0
				return true
			else
				return false
			end
		   else
			return false
		   end
		when "<="
                   if maj_result < 0
                        return true
                   elsif maj_result == 0
                        if min_result > 0
                                return false
                        elsif min_result < 0
                                return true
                        else
                                return true
                        end
                   else
                        return false
                   end
		when "="
                   if maj_result < 0
                        return false
                   elsif maj_result == 0
                        if min_result > 0
                                return false
                        elsif min_result < 0
                                return false
                        else
                                return true
                        end
                   else
                        return false
                   end
		when ">="
		   if maj_result < 0
                        return false
                   elsif maj_result == 0
                        if min_result > 0
                                return true
                        elsif min_result < 0
                                return false
                        else
                                return false
                        end
                   else
                        return true
                   end
		when ">"
                   if maj_result < 0
                        return false
                   elsif maj_result == 0
                        if min_result > 0
                                return true
                        elsif min_result < 0
                                return false
                        else
                                return false
                        end
                   else
                        return true
                   end
		end

	end

	module_function :to_arr,:is_beta,:arr_fix,:majcomp,:mincomp,:betacomp,:comp

end

