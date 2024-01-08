// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./UniswapV2Factory.sol";
import "./IWithIncentivesPool.sol";
import "./GovernanceOwnable.sol";

contract PactSwapFactory is UniswapV2Factory, IWithIncentivesPool, GovernanceOwnable {

    constructor(address governor_, address incentivesPool_) GovernanceOwnable(governor_) public {
        _incentivesPoolAddress = incentivesPool_;
    }

    address private _incentivesPoolAddress;
    event IncentivesPoolSetTransferred(address indexed previousIncentivesPool, address indexed newIncentivesPool);
    function incentivesPool() public view override returns (address) {
        return _incentivesPoolAddress;
    }
    function setIncentivesPool(address newIncentivesPool) public override virtual onlyGovernance {
        emit IncentivesPoolSetTransferred(_incentivesPoolAddress, newIncentivesPool);
        _incentivesPoolAddress = newIncentivesPool;
    }
}
