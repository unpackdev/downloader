// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IKaijuMartRedeemable {
    function kmartRedeem(uint256 lotId, uint32 amount, address to) external;
}