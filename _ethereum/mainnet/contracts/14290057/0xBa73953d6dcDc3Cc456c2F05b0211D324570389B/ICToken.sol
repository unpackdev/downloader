// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC20.sol";
interface ICToken is IERC20 {
    function mint(uint _mintAmount) external returns (uint256);
    function redeem(uint _redeemTokens) external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns(uint256);
}