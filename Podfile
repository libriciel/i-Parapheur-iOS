#
# i-Parapheur iOS
# Copyright (C) 2012-2020 Libriciel-SCOP
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/
#

target "iParapheur" do
  platform :ios, '12.0'
  inhibit_all_warnings!
  use_frameworks!

  pod 'AEXML', '4.6.0'
  pod 'Alamofire', '5.2.2'
  pod 'CryptoSwift', '1.3.2'
  pod 'Floaty', '4.2.0'
  pod 'OpenSSL-Universal', '1.0.2.20'
  pod 'SCNetworkReachability', '2.0.6'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '4.4.0'
  pod 'SSZipArchive', '2.2.3'
  pod 'SwiftMessages', '8.0.2'

  target 'iParapheurTests' do
    inherit! :search_paths
  end

end
