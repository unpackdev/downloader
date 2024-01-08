// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IOptionChef {
    function isDelegated(uint _tokenId) external view returns (bool);
}
