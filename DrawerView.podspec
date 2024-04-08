#
#  Be sure to run `pod spec lint DrawerView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "DrawerView"
  spec.version      = "1.3.6"
  spec.summary      = "An iOS 10 Maps.app style drawer to be used anywhere in your app"


  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
DrawerView is a view for iOS that mimics the functionality of the drawer introduced in the Maps (iOS 10 →).
                      DESC

  spec.homepage     = "https://github.com/mkko/DrawerView"
  spec.screenshots  = "https://raw.githubusercontent.com/mkko/DrawerView/master/Resources/search_sample.gif", "https://raw.githubusercontent.com/mkko/DrawerView/master/Resources/dark_sample.gif", "https://raw.githubusercontent.com/mkko/DrawerView/master/Resources/toolbar_sample.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  spec.license      = "MIT"
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }
  

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "Mikko Välimäki" => "mkko1373@gmail.com" }
  spec.social_media_url   = "http://x.com/mkko"


  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  spec.platform     = :ios, "12.0"
  spec.swift_version = '4.2'

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/mkko/DrawerView.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files  = "DrawerView", "DrawerView/**/*.{h,m}"


  # ――― Resource bundles ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  This attribute allows to define the name and the file of the resource bundles 
  #  which should be built for the Pod. 
  #  They are specified as a hash where the keys represent the name of the bundles 
  #  and the values the file patterns that they should include
  #

  spec.resource_bundles = { 'DrawerView' => ['DrawerView/PrivacyInfo.xcprivacy'] }

end
