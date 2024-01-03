// SPDX-License-Identifier: MIT
// Welcome To Rebase World ^_^ 
// Please Visit App: https://app.mstable.cash

pragma solidity ^0.6.0;

import "./IDistributor.sol";

contract Distributor {
    IDistributor[] public distributors;

    constructor(IDistributor[] memory _distributors) public {
        distributors = _distributors;
    }

    function distribute() public {
        for (uint256 i = 0; i < distributors.length; i++) {
            distributors[i].distribute();
        }
    }
}
