// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./UnstructuredStorageWithTimelock.sol";
import "./StorageV1Upgradeable.sol";
import "./Initializable.sol";

contract StorageV1ConsumerUpgradeable is Initializable {
    using UnstructuredStorageWithTimelock for bytes32;
    // bytes32(uint256(keccak256("eip1967.proxy.storage")) - 1
    bytes32 private constant _STORAGE_SLOT =
        0x23bdfa8033717db08b14621917cfe422b93b161b8e3ef1c873d2197616ec0bb2;

    modifier onlyGovernance() {
        require(
            msg.sender == governance(),
            "StorageV1ConsumerUpgradeable: Only governance"
        );
        _;
    }

    modifier adminPriviledged() {
        require(msg.sender == governance() ||
        isAdmin(msg.sender),
        "StorageV1ConsumerUpgradeable: not governance or admin");
        _;
    }

    modifier opsPriviledged() {
        require(msg.sender == governance() ||
        isAdmin(msg.sender) ||
        isOperator(msg.sender),
        "StorageV1ConsumerUpgradeable: not governance or admin or operator");
        _;
    }

    function initialize(address _store) public virtual initializer {
        address curStorage = (_STORAGE_SLOT).fetchAddress();
        require(
            curStorage == address(0),
            "StorageV1ConsumerUpgradeable: Initialized"
        );
        (_STORAGE_SLOT).setAddress(_store);
    }

    function store() public view returns (address) {
        return (_STORAGE_SLOT).fetchAddress();
    }

    function governance() public view returns (address) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.governance();
    }

    function treasury() public view returns (address) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.treasury();
    }

    function swapCenter() public view returns (address) {
         StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.swapCenter();
    }

    function registry() public view returns (address) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.registry();
    }

    function storageFetchAddress(bytes32 key) public view returns (address) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.addressStorage(key);
    }

    function storageFetchAddressInArray(bytes32 key, uint256 index)
        public
        view
        returns (address)
    {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.addressArrayStorage(key, index);
    }

    function storageFetchUint256(bytes32 key) public view returns (uint256) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.uint256Storage(key);
    }

    function storageFetchUint256InArray(bytes32 key, uint256 index)
        public
        view
        returns (uint256)
    {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.uint256ArrayStorage(key, index);
    }

    function storageFetchBool(bytes32 key) public view returns (bool) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.boolStorage(key);
    }

    function storageFetchBoolInArray(bytes32 key, uint256 index)
        public
        view
        returns (bool)
    {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.boolArrayStorage(key, index);
    }

    function isAdmin(address _who) public view returns (bool) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.isAdmin(_who);
    }

    function isOperator(address _who) public view returns (bool) {
        StorageV1Upgradeable storageContract = StorageV1Upgradeable(store());
        return storageContract.isOperator(_who);
    }
}
