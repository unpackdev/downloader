// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./GelatoConditionsStandard.sol";
import "./IStrategyMKRVaultDAIDelegate.sol";


contract ConditionYETHStratRepay is  GelatoConditionsStandard {

    IStrategyMKRVaultDAIDelegate public immutable yETHStrat;
    address public immutable gelatoCore;

    constructor(IStrategyMKRVaultDAIDelegate _yETHStrat, address _gelatoCore) public {
        yETHStrat = _yETHStrat;
        gelatoCore = _gelatoCore;
    }

    /// @dev Will be checked by GelatoCore.sol before execution of Repay Action happens
    /// @dev Returns "OK" if repay action should be executed
    function ok(uint256, bytes calldata, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        return shouldRepay() ? OK : string("ConditionYETHStratRepay: No repay necessary");
    }

    function shouldRepay() public view returns(bool) {
        return yETHStrat.repayAmount() > 0;
    }
}