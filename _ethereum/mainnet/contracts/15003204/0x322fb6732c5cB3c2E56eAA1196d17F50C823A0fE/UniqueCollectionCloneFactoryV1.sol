// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Clones.sol";
import "./AccessControl.sol";
import "./UniqueCollectionInitializableV1.sol";

/**
 * @title A Factory contract that can create new clones of `UniqueCollectionInitializableV1`
 * @author https://www.onfuel.io
 * @dev This contract should only be deployed once.
 * `DEFAULT_ADMIN_ROLE` is given to the `roleAdmin` account which must be
 * a secure cold wallet, DAO or Safe contract with secure confirmation parameters.
 *
 * The fuel-core backend should have `MANAGER_ROLE` through `manager` account
 * that allows to create new clones of the `UniqueCollectionInitializableV1` contract.
 *
 * On calling the {createUniqueCollection} new clones of `UniqueCollectionInitializableV1`
 * are created on behalve of a creator. All parameters are forwared to the initializer
 * of `UniqueCollectionInitializableV1`
 * The clones are not upgradeable because the implementation contracts address is hardcoded
 * in the bytecode of the clone.
 */
contract UniqueCollectionCloneFactoryV1 is AccessControl{
    UniqueCollectionInitializableV1[] private uniqueCollections;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public immutable uniqueCollectionImplementation;

    /**
     * @dev Emitted when a `manager` created a new `UniqueCollectionInitializableV1` through
     * a call to {createUniqueCollection}.
     * `uniqueCollection` is the address of the new `UniqueCollectionInitializableV1`.
     * been created.
     */
    event UniqueCollectionCreated (
        address indexed uniqueCollection
    );


    /**
     * @notice Constructs the `UniqueCollectionCloneFactoryV1`.
     * @dev This contract should only be deployed once.
     * @param _roleAdmin address of account that will have `DEFAULT_ADMIN_ROLE`.
     * Can update all roles for all accounts. She will essentially will be the
     * owner of the contract.
     * @param _manager address of account that will have `MANAGER_ROLE`.
     * Can create new `UniqueCollectionInitializableV1` through {createUniqueCollection}
     */
    constructor(
        address _roleAdmin,
        address _manager
    ) {
        require(_roleAdmin != address(0), "RoleAdmin is address(0)");
        require(_manager != address(0), "Manager is address(0)");
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(MANAGER_ROLE, _manager);
        uniqueCollectionImplementation = address(new UniqueCollectionInitializableV1());
    }

    // External functions

    /**
     * @notice Create a new clone of `UniqueCollectionInitializableV1`
     * @dev clones of `UniqueCollectionInitializableV1` are created by the `manager`
     * account of fuel-core through this contract and are not meant to be
     * created directly through an individual deployment.
     */
    function createUniqueCollection(
        UniqueCollectionInitializableV1.InitializeData calldata _init
    ) external onlyRole(MANAGER_ROLE) returns (address) {
        address clone = Clones.clone(uniqueCollectionImplementation);
        UniqueCollectionInitializableV1(clone).initialize(_init);
        uniqueCollections.push(UniqueCollectionInitializableV1(clone));
        emit UniqueCollectionCreated(clone);
        return clone;
    }

    // External view functions

    /**
     * @notice Get address of previously created `UniqueCollectionInitializableV1` clones
     * @dev this function is used for the fuel-blockchain-listner
     * event handler get all created `UniqueCollectionInitializableV1` in order to
     * register event handlers.
     * @param _i index in the collection
     * @return the address of UniqueCollectionInitializableV1
     */
    function getCollection(uint256 _i) external view returns(address) {
        return address(uniqueCollections[_i]);
    }

    /**
     * @notice Get how many `UniqueCollectionInitializableV1` clones have previously been created.
     * @dev this function is used for the fuel-blockchain-listner
     * event handler to get all created `UniqueCollectionInitializableV1` in order to
     * register event handlers.
     * @return length of the `uniqueCollections` array
     */
    function collectionsLength() external view returns(uint256) {
        return uniqueCollections.length;
    }
}
