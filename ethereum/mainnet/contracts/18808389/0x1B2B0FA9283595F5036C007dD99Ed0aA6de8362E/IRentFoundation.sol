// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRentFoundation {
    function initialRentApplied(uint256 tokenID) external view returns (bool);

    function spentSecurityDeposit(uint256 tokenID) external view returns (bool);

    function payInitialRent(uint256 tokenID, uint256 amount) external;

    function buyOutPreview(uint256 tokenID) external view returns(bool, uint256);

    function buyOut(uint256 tokenID) external returns(uint256);

     function sellCToken(address account, uint256 amount) external;
}