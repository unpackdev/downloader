// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import "./Initializable.sol";
import "./UnifarmCohort.sol";
import "./IUnifarmCohortFactoryUpgradeable.sol";

/// @title UnifarmCohortFactoryUpgradeable Contract
/// @author UNIFARM
/// @notice deployer of unifarm cohort contracts

contract UnifarmCohortFactoryUpgradeable is IUnifarmCohortFactoryUpgradeable, Initializable {
    /// @dev hold all the storage contract addresses for unifarm cohort
    struct StorageContract {
        // registry address
        address registry;
        // nft manager address
        address nftManager;
        // reward registry
        address rewardRegistry;
    }

    /// @dev factory owner address
    address private _owner;

    /// @notice pointer of StorageContract
    StorageContract internal storageContracts;

    /// @notice all deployed cohorts will push on this array
    address[] public cohorts;

    /// @notice emit on each cohort deployment
    event CohortConstructed(address cohortId);

    /// @notice emit on each ownership transfers
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, 'ONA');
        _;
    }

    /**
     * @notice initialize the cohort factory
     */

    function __UnifarmCohortFactoryUpgradeable_init() external initializer {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`)
     * @dev can only be called by the current owner
     * @param newOwner - new owner
     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'NOIA');
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`)
     * @dev Internal function without access restriction
     * @param newOwner new owner
     */

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function setStorageContracts(
        address registry_,
        address nftManager_,
        address rewardRegistry_
    ) external onlyOwner {
        storageContracts = StorageContract({registry: registry_, nftManager: nftManager_, rewardRegistry: rewardRegistry_});
    }

    /**
     * @dev Returns the address of the current owner of the factory
     * @return _owner owner address
     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function createUnifarmCohort(bytes32 salt) external override onlyOwner returns (address cohortId) {
        bytes memory bytecode = abi.encodePacked(type(UnifarmCohort).creationCode, abi.encode(address(this)));
        assembly {
            cohortId := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        cohorts.push(cohortId);
        emit CohortConstructed(cohortId);
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function computeCohortAddress(bytes32 salt) public view override returns (address) {
        bytes memory bytecode = abi.encodePacked(type(UnifarmCohort).creationCode, abi.encode(address(this)));
        bytes32 initCode = keccak256(bytecode);
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCode)))));
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function obtainNumberOfCohorts() public view override returns (uint256) {
        return cohorts.length;
    }

    /**
     * @inheritdoc IUnifarmCohortFactoryUpgradeable
     */

    function getStorageContracts()
        public
        view
        override
        returns (
            address,
            address,
            address
        )
    {
        return (storageContracts.registry, storageContracts.nftManager, storageContracts.rewardRegistry);
    }

    uint256[49] private __gap;
}
