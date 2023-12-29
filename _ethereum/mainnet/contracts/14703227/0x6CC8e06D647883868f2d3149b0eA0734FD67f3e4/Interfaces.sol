// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

interface IPaw is IERC20 {
    function updateReward(address _address) external;
}

interface IKumaVerse is IERC721 {

}

interface IKumaTracker is IERC1155 {}
