pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract RelayerDAOProxy is TransparentUpgradeableProxy {

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, admin_, _data) { }

    receive() override external payable  {
        //_fallback();
    }
}
