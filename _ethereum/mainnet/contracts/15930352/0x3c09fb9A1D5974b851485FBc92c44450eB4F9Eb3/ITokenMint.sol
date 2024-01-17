// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;


interface ITokenMint {
    function mint(address _to, uint256 _amount) external returns (bool);
}
