//
//  testUser.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public let testUser: Data = """
{
"results":[
{"gender":"female","name":{"title":"Miss","first":"Evelia","last":"Holguín"},"location":{"street":{"number":9473,"name":"Viaducto Norte Gamboa"},"city":"El Tajuelo","state":"Quintana Roo","country":"Mexico","postcode":33552,"coordinates":{"latitude":"22.5570","longitude":"169.1198"},"timezone":{"offset":"+8:00","description":"Beijing, Perth, Singapore, Hong Kong"}},"email":"evelia.holguin@example.com","login":{"uuid":"664dff4b-42cf-4cca-92a0-7b8cdf6bc29e","username":"angryladybug744","password":"novifarm","salt":"iX9XWMwi","md5":"a5ec796e7672f8398c78b0c1ec3c615f","sha1":"2818516198abe98837d3e81faa2622dc9c45d0a1","sha256":"a769acc97fac7d7cc96d5e83f0dd46dafffe0343d69cc8d3765c9a47152b75f6"},"dob":{"date":"1973-06-23T17:02:52.963Z","age":51},"registered":{"date":"2017-10-05T19:27:03.445Z","age":6},"phone":"(694) 771 5964","cell":"(609) 456 3320","id":{"name":"NSS","value":"95 36 84 9198 3"},"picture":{"large":"https://randomuser.me/api/portraits/women/84.jpg","medium":"https://randomuser.me/api/portraits/med/women/84.jpg","thumbnail":"https://randomuser.me/api/portraits/thumb/women/84.jpg"},"nat":"MX"}]
,"info":{"seed":"eb48de21c5ae9f94","results":1,"page":1,"version":"1.4"}
}
""".data(using: .utf8)!
