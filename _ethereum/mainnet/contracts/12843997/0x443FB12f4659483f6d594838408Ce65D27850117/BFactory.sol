// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

import "./ProxyFactory.sol";
import "./BPool.sol";

// Core contract; can't be changed. So disable solhint (reminder for v2)

/* solhint-disable func-order */
/* solhint-disable event-name-camelcase */

contract BFactory is BBronze, ProxyFactory {
    event LOG_NEW_POOL(address indexed caller, address indexed pool);

    event LOG_BLABS(address indexed caller, address indexed blabs);

    mapping(address => bool) private _isBPool;

    function isBPool(address b) external view returns (bool) {
        return _isBPool[b];
    }

    function newBPool() external returns (BPool) {
        address bpool = createClone(_bPoolLogic);
        BPool(bpool).init();
        _isBPool[bpool] = true;
        emit LOG_NEW_POOL(msg.sender, bpool);
        BPool(bpool).setController(msg.sender);
        return BPool(bpool);
    }

    address private _blabs;
    address private _bPoolLogic;

    constructor(address bPoolLogic) public {
        _blabs = msg.sender;
        _bPoolLogic = bPoolLogic;
    }

    function getBLabs() external view returns (address) {
        return _blabs;
    }

    function setBLabs(address b) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function collect(BPool pool) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        uint256 collected = IERC20(pool).balanceOf(address(this));
        bool xfer = pool.transfer(_blabs, collected);
        require(xfer, "ERR_ERC20_FAILED");
    }
}
