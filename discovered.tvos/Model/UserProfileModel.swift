//
//  UserProfileModel.swift
//  discovered.tvos
//
//  Created by mac mini on 07/09/26.
//

import Foundation

// MARK: - User Profile Response

struct UserProfileResponse: Codable {
    let userDetail: [UserDetailResponse]
    let sub_catname: String?
    let cover_video: CoverVideoResponse?
    let publish_images: [String]?
    let publish_videos: [String]?
    let icon_fan: [FanResponse]?
    let emerging_fan: [FanResponse]?
    let brand_fan: [FanResponse]?
    let fans: [FanResponse]?
    let CreatorsYouEndorsing: [FanResponse]?
    let BrandsYouEndorsing: [FanResponse]?
    let CreatorsEndorsingYou: [FanResponse]?
    let BrandsEndorsingYou: [FanResponse]?
    let ivs_data: IVSDataResponse?
    let publish_post: [PublishPostResponse]?
    let post_count: String?
    let notification_count: String?
    let status: Int?
    let type: String?
    let message: String?
}

// MARK: - User Detail

struct UserDetailResponse: Codable {
    let user_id: String?
    let user_uname: String?
    let user_name: String?
    let category_name: String?
    let user_regdate: String?
    let uc_pic: String?
    let uc_city: String?
    let uc_gender: String?
    let user_address: String?
    let country_name: String?
    let uc_about: String?
    let name: String?
    let user_phone: String?
    let isfan: Int?
    let CanIMakeFan: Int?
}

// MARK: - Cover Video

struct CoverVideoResponse: Codable {
    let url: String?
    let cover_image: String?
}

// MARK: - Fan

struct FanResponse: Codable {
    let following_id: String?
    let user_id: String?
    let user_name: String?
    let user_uname: String?
    let user_pic: String?
}

// MARK: - IVS Data

struct IVSDataResponse: Codable {
    let id: String?
    let user_id: String?
    let channel_arn: String?
    let ivs_info: String?
    let status: String?
    let is_live: String?
    let is_scheduled: String?
    let stream_info: String?
}

// MARK: - Publish Post

struct PublishPostResponse: Codable {
    let pub_id: String?
    let pub_uid: String?
    let pub_content: String?
    let pub_media: String?
    let user_name: String?
    let user_pic: String?
    let ThumbImage: String?
    let display_content: String?
    let pub_format: String?
}

// MARK: - Simplified User Profile Model

struct UserProfile {
    let userId: String
    let userName: String
    let userFullName: String
    let category: String
    let subCategory: String?
    let profilePicture: String?
    let coverImage: String?
    let about: String?
    let location: String?
    let gender: String?
    let joinDate: String?
    let followersCount: Int
    let postCount: String?
    let name : String?
    let country_name : String?
    
    init(from response: UserProfileResponse) {
        guard let user = response.userDetail.first else {
            self.userId = ""
            self.userName = ""
            self.userFullName = ""
            self.category = ""
            self.subCategory = response.sub_catname
            self.profilePicture = nil
            self.coverImage = response.cover_video?.cover_image
            self.about = nil
            self.location = nil
            self.gender = nil
            self.joinDate = nil
            self.followersCount = 0
            self.postCount = response.post_count
            self.name = ""
            self.country_name = ""
            return
        }
        
        self.userId = user.user_id ?? ""
        self.userName = user.user_uname ?? ""
        self.userFullName = user.user_name ?? ""
        self.category = user.category_name ?? ""
        self.subCategory = response.sub_catname
        self.profilePicture = user.uc_pic
        self.coverImage = response.cover_video?.cover_image
        self.about = user.uc_about
        self.location = user.uc_city ?? ""
        self.gender = user.uc_gender
        self.joinDate = user.user_regdate
        self.followersCount = response.icon_fan?.count ?? 0
        self.postCount = response.post_count
        self.name = user.name
        self.country_name = user.country_name
    }
}
