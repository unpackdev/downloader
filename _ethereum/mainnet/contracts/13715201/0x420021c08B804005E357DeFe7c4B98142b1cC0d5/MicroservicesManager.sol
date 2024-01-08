// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IMicroservicesManager.sol";
import "./IOrganization.sol";
import "./LazyInitCapableElement.sol";
import "./GeneralUtilities.sol";
import "./KnowledgeBase.sol";

contract MicroservicesManager is IMicroservicesManager, LazyInitCapableElement {
    using StringUtilities for string;
    using Treasury for IOrganization;
    using ReflectionUtilities for address;

    mapping(uint256 => Microservice) private _storage;
    mapping(string => uint256) private _index;
    uint256 public override size;

    uint256 private _keyIndex;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IMicroservicesManager).interfaceId ||
            interfaceId == this.size.selector ||
            interfaceId == this.all.selector ||
            interfaceId == this.partialList.selector ||
            interfaceId == this.list.selector ||
            interfaceId == this.listByIndices.selector ||
            interfaceId == this.exists.selector ||
            interfaceId == this.get.selector ||
            interfaceId == this.getByIndex.selector ||
            interfaceId == this.set.selector ||
            interfaceId == this.batchSet.selector ||
            interfaceId == this.remove.selector ||
            interfaceId == this.batchRemove.selector ||
            interfaceId == this.removeByIndices.selector||
            interfaceId == this.read.selector ||
            interfaceId == this.submit.selector;
    }

    function all() override external view returns (Microservice[] memory) {
        return partialList(0, size);
    }

    function partialList(uint256 start, uint256 offset) override public view returns (Microservice[] memory values) {
        (uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) = BehaviorUtilities.calculateProjectedArraySizeAndLoopUpperBound(size, start, offset);
        if(projectedArraySize > 0) {
            values = new Microservice[](projectedArraySize);
            uint256 cursor = 0;
            for(uint256 i = start; i < projectedArrayLoopUpperBound; i++) {
                values[cursor++] = _storage[i];
            }
        }
    }

    function list(string[] calldata keys) override external view returns (Microservice[] memory values) {
        values = new Microservice[](keys.length);
        for(uint256 i = 0; i < values.length; i++) {
            values[i] = get(keys[i]);
        }
    }

    function listByIndices(uint256[] calldata indices) override external view returns (Microservice[] memory values) {
        values = new Microservice[](indices.length);
        for(uint256 i = 0; i < values.length; i++) {
            values[i] = getByIndex(indices[i]);
        }
    }

    function exists(string memory key) public override view returns(bool result, uint256 index) {
        result = !key.isEmpty() && key.equals(_storage[index = _index[key]].key);
    }

    function get(string calldata key) public override view returns(Microservice memory value) {
        (bool result, uint256 index) = exists(key);
        value = result ? _storage[index] : value;
    }

    function getByIndex(uint256 index) public override view returns(Microservice memory value) {
        value = index < size ? _storage[index] : value;
    }

    function set(Microservice calldata newValue) external authorizedOnly override returns(Microservice memory replacedValue) {
        replacedValue = _set(newValue);
    }

    function batchSet(Microservice[] calldata newValues) external override authorizedOnly returns(Microservice[] memory replacedValues) {
        replacedValues = new Microservice[](newValues.length);
        for (uint256 i = 0; i < replacedValues.length; i++) {
            replacedValues[i] = _set(newValues[i]);
        }
    }

    function remove(string calldata key) external override authorizedOnly returns(Microservice memory removedValue) {
        removedValue = _remove(key);
    }

    function batchRemove(string[] calldata keys) external override authorizedOnly returns(Microservice[] memory removedValues) {
        removedValues = new Microservice[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            removedValues[i] = _remove(keys[i]);
        }
    }

    function removeByIndices(uint256[] calldata indices) external override authorizedOnly returns(Microservice[] memory removedValues) {
        removedValues = new Microservice[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            require(i == 0 || indices[i - 1] >= indices[i], "DESC");
            removedValues[i] = _remove(indices[i]);
        }
    }

    function read(string calldata key, bytes calldata data) external override view returns(bytes memory returnData) {
        (address location, bytes memory payload) = _runCheck(key, data, 0, msg.sender, 0);
        returnData = location.read(payload);
    }

    function submit(string calldata key, bytes calldata data) external override payable returns(bytes memory returnData) {
        IOrganization organization = IOrganization(host);
        organization.storeETH(msg.value);
        (address location, bytes memory payload) = _runCheck(key, data, 1, msg.sender, msg.value);
        bytes32 randomKey = BehaviorUtilities.randomKey(_keyIndex++);
        organization.set(IOrganization.Component(randomKey, location, true, false));
        returnData = location.submit(0, payload);
        organization.set(IOrganization.Component(randomKey, address(0), false, false));
    }

    function _set(Microservice memory newValueInput) private returns(Microservice memory replacedValue) {
        (bool alreadyExists, uint256 index, Microservice memory newValue,) = _validateInput(newValueInput);

        if (alreadyExists) {
            replacedValue = _remove(index);
        }
        _storage[_index[newValue.key] = size++] = newValue;
        emit MicroserviceAdded(msg.sender, keccak256(bytes(newValue.key)), newValue.key, newValue.location, newValue.methodSignature, newValue.submittable, newValue.returnAbiParametersArray, newValue.isInternal, newValue.needsSender);
    }

    function _validateInput(Microservice memory newValueInput) private view returns(bool alreadyExists, uint256 index, Microservice memory newValue, Microservice storage oldValue) {
        require(!newValueInput.key.isEmpty(), "key");
        require(newValueInput.location != address(0), "location");
        require(!newValueInput.methodSignature.isEmpty(), "methodSignature");
        require(!newValueInput.isInternal || newValueInput.submittable, "internal view");
        (alreadyExists, index) = exists((newValue = newValueInput).key);
        oldValue = alreadyExists ? _storage[index] : oldValue;
    }

    function _remove(string memory key) private returns(Microservice memory removedValue) {
        (bool result, uint256 index) = exists(key);
        removedValue = result ? _remove(index) : removedValue;
    }

    function _remove(uint256 index) private returns(Microservice memory removedValue) {
        if(index >= size) {
            return removedValue;
        }
        delete _index[(removedValue = _storage[index]).key];
        if(index != --size) {
            Microservice memory lastValue = _storage[size];
            _storage[_index[lastValue.key] = index] = lastValue;
        }
        emit MicroserviceRemoved(msg.sender, keccak256(bytes(removedValue.key)), removedValue.key, removedValue.location, removedValue.methodSignature, removedValue.submittable, removedValue.returnAbiParametersArray, removedValue.isInternal, removedValue.needsSender);
    }

    function _runCheck(string memory key, bytes memory data, uint8 submittable, address sender, uint256 value) internal view returns(address location, bytes memory payload) {
        Microservice memory microservice = _storage[_index[key]];
        require(!key.isEmpty() && key.equals(microservice.key), "Invalid");

        require(submittable == (microservice.submittable ? 1 : 0), "Type");

        require(!microservice.isInternal || IOrganization(host).isActive(msg.sender), "Internal");

        location = microservice.location;

        if (microservice.needsSender) {
            require(data.length >= (submittable == 1 ? 64 : 32), "Payload");
            assembly {
                mstore(add(data, 0x20), sender)
                switch iszero(submittable) case 0 {
                    mstore(add(data, 0x40), value)
                }
            }
        }

        payload = abi.encodePacked(bytes4(keccak256(bytes(microservice.methodSignature))), data);
    }
}