// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./Context.sol";

import "./BPTStakingPool.sol";

import "./Pause.sol";

contract BPTStakingPoolFactory is Context, Pause {
    BPTStakingPool[] public _bptStakingPools;

    event BPTStakingPoolCreated(BPTStakingPool bptStakingPool);

    constructor() Roles([_msgSender(), address(this), address(0)]) {}

    function createBPTStakingPool(address bpt, address renBTCAddress)
        external
        onlySuperAdminOrAdmin
    {
        require(bpt != address(0), "Can not be zero address");
        require(bpt != address(this), "Can not be current contract address");

        BPTStakingPool bptStakingPool =
            new BPTStakingPool(bpt, renBTCAddress, owner());
        _bptStakingPools.push(bptStakingPool);

        emit BPTStakingPoolCreated(bptStakingPool);
    }

    function getBPTStakingPools()
        external
        view
        returns (BPTStakingPool[] memory)
    {
        return _bptStakingPools;
    }
}
