// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IStateManager.sol";
import "./LazyInitCapableElement.sol";
import "./GeneralUtilities.sol";

contract StateManager is IStateManager, LazyInitCapableElement {
    using StringUtilities for string;

    mapping(uint256 => StateEntry) private _storage;
    mapping(string => uint256) private _index;
    uint256 public override size;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns(bytes memory) {
        if(lazyInitData.length == 0) {
            return "";
        }
        StateEntry[] memory newValues = abi.decode(lazyInitData, (StateEntry[]));
        for (uint256 i = 0; i < newValues.length; i++) {
            _set(newValues[i]);
        }
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IStateManager).interfaceId ||
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
            interfaceId == this.removeByIndices.selector;
    }

    function all() override external view returns (StateEntry[] memory) {
        return partialList(0, size);
    }

    function partialList(uint256 start, uint256 offset) override public view returns (StateEntry[] memory values) {
        (uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) = BehaviorUtilities.calculateProjectedArraySizeAndLoopUpperBound(size, start, offset);
        if(projectedArraySize > 0) {
            values = new StateEntry[](projectedArraySize);
            uint256 cursor = 0;
            for(uint256 i = start; i < projectedArrayLoopUpperBound; i++) {
                values[cursor++] = _storage[i];
            }
        }
    }

    function list(string[] calldata keys) override external view returns (StateEntry[] memory values) {
        values = new StateEntry[](keys.length);
        for(uint256 i = 0; i < values.length; i++) {
            values[i] = get(keys[i]);
        }
    }

    function listByIndices(uint256[] calldata indices) override external view returns (StateEntry[] memory values) {
        values = new StateEntry[](indices.length);
        for(uint256 i = 0; i < values.length; i++) {
            values[i] = getByIndex(indices[i]);
        }
    }

    function exists(string memory key) public override view returns(bool result, uint256 index) {
        result = !key.isEmpty() && key.equals(_storage[index = _index[key]].key);
    }

    function get(string calldata key) public override view returns(StateEntry memory value) {
        (bool result, uint256 index) = exists(key);
        value = result ? _storage[index] : value;
    }

    function getByIndex(uint256 index) public override view returns(StateEntry memory value) {
        value = index < size ? _storage[index] : value;
    }

    function set(StateEntry calldata newValue) external authorizedOnly override returns(bytes memory replacedValue) {
        replacedValue = _set(newValue);
    }

    function batchSet(StateEntry[] calldata newValues) external override authorizedOnly returns(bytes[] memory replacedValues) {
        replacedValues = new bytes[](newValues.length);
        for (uint256 i = 0; i < replacedValues.length; i++) {
            replacedValues[i] = _set(newValues[i]);
        }
    }

    function remove(string calldata key) external override authorizedOnly returns(bytes32 removedType, bytes memory removedValue) {
        (removedType, removedValue) = _remove(key);
    }

    function batchRemove(string[] calldata keys) external override authorizedOnly returns(bytes32[] memory removedTypes, bytes[] memory removedValues) {
        removedTypes = new bytes32[](keys.length);
        removedValues = new bytes[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            (removedTypes[i], removedValues[i]) = _remove(keys[i]);
        }
    }

    function removeByIndices(uint256[] calldata indices) external override authorizedOnly returns(bytes32[] memory removedTypes, bytes[] memory removedValues) {
        removedTypes = new bytes32[](indices.length);
        removedValues = new bytes[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            require(i == 0 || indices[i - 1] >= indices[i], "DESC");
            (removedTypes[i], removedValues[i]) = _remove(indices[i]);
        }
    }

    function _set(StateEntry memory newValueInput) private returns(bytes memory replacedValue) {

        (bool alreadyExists,, StateEntry memory newValue, StateEntry storage oldValue) = _validateInput(newValueInput);

        if (alreadyExists) {
            replacedValue = oldValue.value;
            oldValue.value = newValue.value;
        } else {
            _storage[_index[newValue.key] = size++] = newValue;
        }
    }

    function _validateInput(StateEntry memory newValueInput) private view returns(bool alreadyExists, uint256 index, StateEntry memory newValue, StateEntry storage oldValue) {
        require(!newValueInput.key.isEmpty(), "key");
        require(newValueInput.entryType != bytes32(0), "type");
        (alreadyExists, index) = exists((newValue = newValueInput).key);
        oldValue = alreadyExists ? _storage[index] : oldValue;
        require(!alreadyExists || newValue.entryType == oldValue.entryType, "type");
    }

    function _remove(string memory key) private returns(bytes32 removedType, bytes memory removedValue) {
        (bool result, uint256 index) = exists(key);
        (removedType, removedValue) = result ? _remove(index) : (removedType, removedValue);
    }

    function _remove(uint256 index) private returns(bytes32 removedType, bytes memory removedValue) {
        if(index >= size) {
            return (removedType, removedValue);
        }
        StateEntry memory removedEntry = _storage[index];
        delete _index[removedEntry.key];
        removedType = removedEntry.entryType;
        removedValue = removedEntry.value;
        if(index != --size) {
            StateEntry memory lastValue = _storage[size];
            _storage[_index[lastValue.key] = index] = lastValue;
        }
    }
}