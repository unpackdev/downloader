pragma solidity ^0.5.2;

import "./UpgradableProxy.sol";
import "./Registry.sol";

contract ValidatorShareProxy is UpgradableProxy {
    constructor(address _registry) public UpgradableProxy(_registry) {}

    function loadImplementation() internal view returns (address) {
        return Registry(super.loadImplementation()).getValidatorShareAddress();
    }
}
