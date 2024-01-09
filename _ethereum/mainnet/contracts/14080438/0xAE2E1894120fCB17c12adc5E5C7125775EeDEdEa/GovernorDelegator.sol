// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract GovernorDelegator is TransparentUpgradeableProxy{
    

    // constructor(address _logic, address _admin, address _mrt,uint256 _rewardPerBlock,uint256 _startBlock) 
    // payable 
    // TransparentUpgradeableProxy(_logic, _admin, abi.encodeWithSignature("initialize(address,uint256,uint256)",
    //         _mrt,
    //         _rewardPerBlock,
    //         _startBlock)) {
    // }

    constructor( 
        address _logic,
        address _timelock,
        address _mte,
        address _strategyAdmin,
        address _admin,
        
        uint _votingPeriod,
        uint _votingDelay,
        uint _proposalThreshold )
    payable 
    TransparentUpgradeableProxy(_logic, _admin, abi.encodeWithSignature("initialize(address,address,address,uint256,uint256,uint256)",
                                                            _timelock,
                                                            _mte,
                                                            _strategyAdmin,
                                                            _votingPeriod,
                                                            _votingDelay,
                                                            _proposalThreshold)) {
    }
}
