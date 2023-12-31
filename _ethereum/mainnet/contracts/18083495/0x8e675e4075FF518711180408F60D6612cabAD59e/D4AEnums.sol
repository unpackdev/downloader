// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum PriceTemplateType {
    EXPONENTIAL_PRICE_VARIATION,
    LINEAR_PRICE_VARIATION
}

enum RewardTemplateType {
    LINEAR_REWARD_ISSUANCE,
    EXPONENTIAL_REWARD_ISSUANCE
}

enum TemplateChoice {
    PRICE,
    REWARD
}
