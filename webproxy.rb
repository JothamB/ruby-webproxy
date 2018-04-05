#!/usr/bin/ruby

# WEBPROXY - Bridge traffic between website and a client
#
# (C) 2018 JothamB
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require "socket"
require "openssl"
require "colorize"
require "optparse"

def run(website, ssl, key, cert, verbose)
	if ssl
		tcpServer = TCPServer.new(443)
		ctx = OpenSSL::SSL::SSLContext.new
		begin
			ctx.key = OpenSSL::PKey::RSA.new(File.open(key))
		rescue
			puts
			puts key + " does not exist"
			puts
			exit 1
		end
		begin
			ctx.cert = OpenSSL::X509::Certificate.new(File.open(cert))
		rescue
			puts
			puts cert + " does not exist"
			puts
			exit 1
		end
		sslServer = OpenSSL::SSL::SSLServer.new(tcpServer, ctx)
		frontSock = sslServer.accept
		backSslSock = TCPSocket.new(website, 443)
		backSock = OpenSSL::SSL::SSLSocket.new(backSslSock)
		backSock.connect
	else
		tcpServer = TCPServer.new(80)
		frontSock = tcpServer.accept
		backSock = TCPSocket.new(website, 80)
	end
	puts
	puts "Connection established".red
	puts
	Signal.trap("INT") {
		frontSock.close
		backSock.close
		sslServer.close if ssl
		tcpServer.close if !ssl
		exit 0
	}
	loop do
        	ready = select([frontSock, backSock])
	        if ready[0].include? frontSock
			begin
	        	        data = frontSock.sysread(65536)
				print data if verbose
				backSock.write(data)
			rescue
				puts
				puts "Connection with client was lost".red
				puts
				exit 0
			end
		end
        	if ready[0].include? backSock
			begin
		                data = backSock.sysread(65536)
				print data if verbose
				frontSock.write(data)
			rescue
				puts
				puts "Connection with website was lost".red
				puts
				exit 0
			end
	        end
	end
end

if ARGV[0] == "-h" || ARGV[0] == nil
	puts
	puts "Web proxy"
	puts "Bridges traffic between website and a client"
	puts "Supprts HTTP as well as HTTPS connections"
	puts "To bridge HTTPS connection you have to provide private key and certificate for the client"
	puts "Use --verbose to print all the routed traffic to standard output"
	puts 
	puts "Usage: ./webproxy.rb --website WebSite [--ssl --key /Path/To/Key --cert /Path/To/Cert] [--verbose]"
	puts
else
	options = {:website => nil, :ssl => false, :key => nil, :cert => nil, :verbose => false}
	parser = OptionParser.new do |opt|
		opt.on("--website website") do |website|
			options[:website] = website
		end
		opt.on("--ssl") do |ssl|
			options[:ssl] = ssl
		end
		opt.on("--key key") do |key|
			options[:key] = key
		end
		opt.on("--cert cert") do |cert|
			options[:cert] = cert
		end
		opt.on("--verbose") do |verbose|
			options[:verbose] = verbose
		end
	end
	parser.parse!
	run(options[:website], options[:ssl], options[:key], options[:cert], options[:verbose])
end
