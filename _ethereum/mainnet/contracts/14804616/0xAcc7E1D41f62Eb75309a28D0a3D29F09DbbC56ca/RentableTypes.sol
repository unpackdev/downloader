// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/// @title Rentable Types
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
library RentableTypes {
    struct RentalConditions {
        uint256 minTimeDuration; // min duration allowed for the rental
        uint256 maxTimeDuration; // max duration allowed for the rental
        uint256 pricePerSecond; // price per second in payment token units
        uint256 paymentTokenId; // payment token id allowed for the rental (0 for ETH and ERC20)
        address paymentTokenAddress; // payment token address allowed for the rental
        address privateRenter; // restrict rent only to this address
    }
}
