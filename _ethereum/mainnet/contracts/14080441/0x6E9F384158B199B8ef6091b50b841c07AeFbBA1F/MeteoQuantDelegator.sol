// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract MeteoQuantDelegator is TransparentUpgradeableProxy{

    constructor(address _logic, address _admin, address _martian, address _dao, address _router, address _mte, address _weth, address _governor, address _timelock) 
    payable 
    TransparentUpgradeableProxy(_logic, _admin, abi.encodeWithSignature("initialize(address,address,address,address,address,address,address)",
            _martian,
            _dao,
            _router,
            _mte,
            _weth,
            _governor,
            _timelock
    )) {
    }
}
