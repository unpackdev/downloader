// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
import "./IERC2981.sol";

interface IRoyaltyGovernor is IERC2981 {
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external;
}
