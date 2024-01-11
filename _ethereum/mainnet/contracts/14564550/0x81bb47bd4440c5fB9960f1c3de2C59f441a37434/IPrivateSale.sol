//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPrivateSale {
    struct UserInfo {
        bool isWhitelisted;
        uint248 amount;
        uint248 amountBought;
        bool isComplient;
    }

    function factory() external view returns (address);

    function name() external view returns (string memory);

    function maxSupply() external view returns (uint256);

    function amountSold() external view returns (uint256);

    function minAmount() external view returns (uint256);

    function price() external view returns (uint256);

    function claimableAmount() external view returns (uint256);

    function isOver() external view returns (bool);

    function userInfo(address user) external view returns (UserInfo memory);

    function initialize(
        string calldata name,
        uint256 price,
        uint256 maxSupply,
        uint256 minAmount
    ) external;

    function participate() external payable;

    function addToWhitelist(address[] calldata addresses) external;

    function removeFromWhitelist(address[] calldata addresses) external;

    function validateUsers(address[] calldata addresses) external;

    function claim() external;

    function endSale() external;

    function emergencyWithdraw() external;
}
