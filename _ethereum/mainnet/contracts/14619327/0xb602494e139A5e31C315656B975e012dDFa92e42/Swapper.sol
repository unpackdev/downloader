// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./Staker.sol";

contract CollabFaker {
    NftNinjasStaking public stakingContract =
        NftNinjasStaking(0x5A7C2FaF1F08314A1c24F4e09F452D4EB11f6EeC);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.stakedTokens(owner);
    }
}