//
//  LoginResponseModel.swift
//  discovered.tvos
//
//  Created by mac mini on 04/09/26.
//

import Foundation

struct LoginResponse: Codable {
    let userData: UserData?
    let status: Int?
    let type: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case userData
        case status, type, message
    }
}

struct UserData: Codable {
    let userLoginId: String?
    let userName: String?
    let userUname: String?
    let userLogin: Bool?
    let userStatus: String?
    let userAccessLevel: String?
    let userCategory: String?
    let isIva: String?
    let userPrimaryType: String?
    let ucCountry: String?
    let userEmail: String?
    let iat: Int?
    let userPic: String?
    let sigupAccType: String?
    let playfabId: String?
    let sub: String?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case userLoginId = "user_login_id"
        case userName = "user_name"
        case userUname = "user_uname"
        case userLogin = "user_login"
        case userStatus = "user_status"
        case userAccessLevel = "user_accesslevel"
        case userCategory = "user_category"
        case isIva = "is_iva"
        case userPrimaryType = "user_primaryType"
        case ucCountry = "uc_country"
        case userEmail = "user_email"
        case iat
        case userPic = "user_pic"
        case sigupAccType = "sigup_acc_type"
        case playfabId = "playfab_id"
        case sub
        case token
    }
}
