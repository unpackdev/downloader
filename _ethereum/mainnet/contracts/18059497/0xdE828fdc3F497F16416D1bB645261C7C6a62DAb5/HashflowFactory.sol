/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import "./Address.sol";
import "./Ownable2Step.sol";
import "./Clones.sol";
import "./Initializable.sol";

import "./IHashflowFactory.sol";
import "./IHashflowPool.sol";
import "./IHashflowRouter.sol";

/// @title HashflowFactory
/// @author Victor Ionescu
/// @notice Implementation of IHashflowFactory.
contract HashflowFactory is IHashflowFactory, Ownable2Step, Initializable {
    using Address for address;

    address public router;

    address public _poolImpl;

    mapping(address => bool) public allowedPoolCreators;

    /// @inheritdoc IHashflowFactory
    function initialize(address _router)
        external
        override
        initializer
        onlyOwner
    {
        require(
            _router != address(0),
            'HashflowFactory::initialize Router cannot be 0 address.'
        );
        router = _router;
    }

    /// @inheritdoc IHashflowFactory
    function updatePoolCreatorAuthorization(address poolCreator, bool status)
        external
        override
        onlyOwner
    {
        require(
            poolCreator != address(0),
            'HashflowFactory::updatePoolCreatorAuthorization Pool creator cannot be 0 address.'
        );
        allowedPoolCreators[poolCreator] = status;
        emit UpdatePoolCreatorAuthorization(poolCreator, status);
    }

    /// @inheritdoc IHashflowFactory
    function createPool(string calldata name, address signer)
        external
        override
    {
        require(
            allowedPoolCreators[_msgSender()],
            'HashflowFactory::createPool Not authorized.'
        );

        require(
            router != address(0),
            'HashflowFactory::createPool Router has not been initialized.'
        );

        address newPool = _createPoolInternal(name, signer, _msgSender());

        IHashflowRouter(router).updatePoolAuthorization(newPool, true);

        emit CreatePool(newPool, _msgSender());
    }

    function _createPoolInternal(
        string memory name,
        address signer,
        address operations
    ) internal virtual returns (address) {
        require(
            bytes(name).length > 0,
            'HashflowFactory::_createPoolInternal Name cannot be empty.'
        );
        require(
            _poolImpl != address(0),
            'HasflowFactory::_createPoolInternal Pool implementation not set.'
        );

        address newPool = Clones.clone(_poolImpl);
        IHashflowPool(newPool).initialize(name, signer, operations, router);

        require(
            newPool != address(0),
            'HashflowFactory: new pool is 0 address'
        );

        return newPool;
    }

    /// @inheritdoc IHashflowFactory
    function updatePoolImpl(address poolImpl) external override onlyOwner {
        require(
            poolImpl.isContract(),
            'HashflowFactory::updatePoolImpl Pool Implementation must be a contract.'
        );
        require(
            _poolImpl == address(0),
            'HashflowFactory::updatePoolImpl Pool Implementation cannot be re-initialized.'
        );

        emit UpdatePoolImplementation(poolImpl, _poolImpl);

        _poolImpl = poolImpl;
    }

    /// @dev We do not allow owner to renounce ownership.
    function renounceOwnership() public view override onlyOwner {
        revert('HashflowFactory: Renouncing ownership not allowed.');
    }
}
