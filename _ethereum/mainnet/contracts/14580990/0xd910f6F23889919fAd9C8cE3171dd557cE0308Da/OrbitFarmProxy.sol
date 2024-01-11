// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TransparentUpgradeableProxy.sol";

contract OrbitFarmProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address admin_, bytes memory _data) public TransparentUpgradeableProxy(_logic, admin_, _data){ }

    function getAdmin() public view returns (address) {
        return _admin();
    }
    
    function getImplementation() public view returns (address) {
        return _implementation();
    }

    receive() override external payable {}
}
