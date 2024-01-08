// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./AccessControl.sol";

import "./IOilerOptionBaseFactory.sol";

contract OilerOptionFactoryOwnershipProxy is AccessControl {
    bytes32 public constant OWNER_ROLE = "OWNER";
    bytes32 public constant DEPLOYER_ROLE = "DEPLOYER";

    constructor(address _owner) public {
        _setupRole(OWNER_ROLE, _owner);
        _setRoleAdmin(DEPLOYER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    function createOption(
        IOilerOptionBaseFactory _factory,
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateral,
        uint256 _collateralToPushIntoAmount,
        uint256 _optionsToPushIntoPool
    ) external {
        require(hasRole(DEPLOYER_ROLE, msg.sender), "OilerOptionFactoryOwnershipProxy.createOption, not a deployer");
        _factory.createOption(
            _strikePrice,
            _expiryTS,
            _put,
            _collateral,
            _collateralToPushIntoAmount,
            _optionsToPushIntoPool
        );
    }

    function transact(
        address _to,
        bytes calldata _data,
        uint256 value
    ) external {
        require(hasRole(OWNER_ROLE, msg.sender), "OilerOptionFactoryOwnershipProxy.transact, not the owner");
        _to.call{value: value}(_data);
    }
}
