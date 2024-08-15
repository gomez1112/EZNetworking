//
//  User.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

struct User: Codable {
    struct Result: Codable {
        struct Name: Codable {
            let title: String
            let first: String
            let last: String
        }
        
        struct Location: Codable {
            struct Street: Codable {
                let number: Int
                let name: String
            }
            
            struct Coordinate: Codable {
                let latitude: String
                let longitude: String
            }
            
            struct Timezone: Codable {
                let offset: String
                let description: String
            }
            
            let street: Street
            let city: String
            let state: String
            let country: String
            let postcode: Int
            let coordinates: Coordinate
            let timezone: Timezone
        }
        
        struct Login: Codable {
            let uuid: String
            let username: String
            let password: String
            let salt: String
            let md5: String
            let sha1: String
            let sha256: String
        }
        
        struct Dob: Codable {
            let date: String
            let age: Int
        }
        
        struct Registered: Codable {
            let date: String
            let age: Int
        }
        
        struct ID: Codable {
            let name: String
            let value: String
        }
        
        struct Picture: Codable {
            let large: URL
            let medium: URL
            let thumbnail: URL
        }
        
        let gender: String
        let name: Name
        let location: Location
        let email: String
        let login: Login
        let dob: Dob
        let registered: Registered
        let phone: String
        let cell: String
        let id: ID
        let picture: Picture
        let nat: String
    }
    
    struct Info: Codable {
        let seed: String
        let results: Int
        let page: Int
        let version: String
    }
    
    let results: [Result]
    let info: Info
}
