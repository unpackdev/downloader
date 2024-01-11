// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
}
