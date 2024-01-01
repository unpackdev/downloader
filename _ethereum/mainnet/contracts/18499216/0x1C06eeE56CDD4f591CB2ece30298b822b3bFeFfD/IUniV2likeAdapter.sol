// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAdapter.sol";

interface IUniV2likeAdapter is IAdapter {
    function factory() external view returns (address);
}
