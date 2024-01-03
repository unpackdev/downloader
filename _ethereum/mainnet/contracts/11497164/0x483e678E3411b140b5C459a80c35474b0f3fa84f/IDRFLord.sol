// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

interface IDRFLord {

    function depositFromSDRFFarm(address sender, uint256 amount) external;

    function redeemFromSDRFFarm(address recipient, uint256 amount) external;

}
