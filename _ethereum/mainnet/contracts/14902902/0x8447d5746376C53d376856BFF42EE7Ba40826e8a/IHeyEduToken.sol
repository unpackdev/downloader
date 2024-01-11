// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IL2StandardERC20.sol";

interface IHeyEduToken is IL2StandardERC20 {
    function mint(address _to, uint256 _value) external;

    function claimOwnership() external;

    function setMinter(address newMinter) external;
}
