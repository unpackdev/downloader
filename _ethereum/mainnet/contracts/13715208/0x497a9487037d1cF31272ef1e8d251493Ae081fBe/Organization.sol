// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganization.sol";
import "./DynamicMetadataCapableElement.sol";
import "./GeneralUtilities.sol";

contract Organization is IOrganization, DynamicMetadataCapableElement {
    using ReflectionUtilities for address;

    mapping(bytes32 => address[]) private _history;
    mapping(address => bytes32) public override keyOf;

    mapping(bytes32 => address) public override get;
    mapping(bytes32 => bool) public override keyIsActive;

    constructor(bytes memory lazyInitData) DynamicMetadataCapableElement(lazyInitData) {
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal virtual override returns(bytes memory) {
        require(host == address(0));
        return abi.encode(_set(abi.decode(lazyInitData, (Component[]))));
    }

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal virtual override pure returns(bool) {
        return
            interfaceId == type(IOrganization).interfaceId ||
            interfaceId == this.keyOf.selector ||
            interfaceId == this.history.selector ||
            interfaceId == this.batchHistory.selector ||
            interfaceId == this.get.selector ||
            interfaceId == this.list.selector ||
            interfaceId == this.isActive.selector ||
            interfaceId == this.keyIsActive.selector ||
            interfaceId == this.set.selector ||
            interfaceId == this.batchSet.selector ||
            interfaceId == this.submit.selector;
    }

    function history(bytes32 key) override external view returns(address[] memory componentsAddresses) {
        return _history[key];
    }

    function batchHistory(bytes32[] calldata keys) override external view returns(address[][] memory componentsAddresses) {
        componentsAddresses = new address[][](keys.length);
        for(uint256 i = 0; i < componentsAddresses.length; i++) {
            componentsAddresses[i] = _history[keys[i]];
        }
    }

    function list(bytes32[] calldata keys) override external view returns(address[] memory componentsAddresses) {
        componentsAddresses = new address[](keys.length);
        for(uint256 i = 0; i < componentsAddresses.length; i++) {
            componentsAddresses[i] = get[keys[i]];
        }
    }

    function isActive(address componentAddress) override public view returns(bool) {
        return get[keyOf[componentAddress]] == componentAddress && keyIsActive[keyOf[componentAddress]];
    }

    function set(Component calldata component) override authorizedOnly external returns(address replacedComponentAddress) {
        replacedComponentAddress = _set(component);
    }

    function batchSet(Component[] calldata components) override authorizedOnly external returns (address[] memory replacedComponentAddresses) {
        replacedComponentAddresses =  _set(components);
    }

    function submit(address location, bytes calldata payload, address restReceiver) override authorizedOnly external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function _subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata, uint256) internal virtual override view returns(bool, bool) {
        if(location == address(this) && selector == this.setHost.selector) {
            return (true, false);
        }
        return (true, isActive(subject));
    }

    function _set(Component[] memory components) internal returns(address[] memory replacedComponentAddresses) {
        replacedComponentAddresses = new address[](components.length);
        for(uint256 i = 0; i < components.length; i++) {
            replacedComponentAddresses[i] = _set(components[i]);
        }
    }

    function _set(Component memory component) internal returns(address replacedComponentAddress) {
        require(component.key != bytes32(0), "key");
        if(!component.active || component.location == address(0)) {
            delete keyIsActive[component.key];
        }
        replacedComponentAddress = get[component.key];
        get[component.key] = component.location;
        if(component.location != address(0)) {
            address location = component.location;
            uint256 codeSize;
            assembly {
                codeSize := extcodesize(location)
            }
            require(codeSize != 0, "address");
            keyIsActive[keyOf[component.location] = component.key] = component.active;
            if(component.log) {
                _history[component.key].push(component.location);
            }
        }
        if(component.log) {
            emit ComponentSet(component.key, replacedComponentAddress, component.location, component.active);
        }
    }
}