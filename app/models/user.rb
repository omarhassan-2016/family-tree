class User < ApplicationRecord
  has_secure_password

  enum :role, { admin: 0, contributor: 1, viewer: 2 }

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  has_many :comments, dependent: :destroy
end
