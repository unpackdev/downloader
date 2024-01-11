// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./Strings.sol";
import "./Counters.sol";
import "./IAccessControl.sol";
import "./ERC165Checker.sol";

import "./ValidatorLibrary.sol";

import "./IOrderer.sol";
import "./IPhutureJob.sol";
import "./IIndexRegistry.sol";
import "./IKeep3r.sol";

/// @title Phuture job
/// @notice Contains signature verification and order execution logic
contract PhutureJob is IPhutureJob {
    using ERC165Checker for address;
    using Counters for Counters.Counter;
    using ValidatorLibrary for ValidatorLibrary.Sign;

    /// @notice Validator role
    bytes32 internal immutable VALIDATOR_ROLE;
    /// @notice Order executor role
    bytes32 internal immutable ORDER_EXECUTOR_ROLE;
    /// @notice Role allows configure ordering related data/components
    bytes32 internal immutable ORDERING_MANAGER_ROLE;

    /// @notice Nonces of signers
    mapping(address => Counters.Counter) internal _nonces;

    /// @notice Keep3r address
    address public immutable keep3r;
    /// @inheritdoc IPhutureJob
    address public immutable override registry;

    /// @inheritdoc IPhutureJob
    uint256 public override minAmountOfSigners = 1;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "PhutureJob: FORBIDDEN");
        _;
    }

    /// @notice Pays keeper for work
    modifier payKeeper(address _keeper) {
        require(IKeep3r(keep3r).isKeeper(_keeper), "PhutureJob: !KEEP3R");
        _;
        IKeep3r(keep3r).worked(_keeper);
    }

    constructor(address _keep3r, address _registry) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "PhutureJob: INTERFACE");

        VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
        ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
        ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

        keep3r = _keep3r;
        registry = _registry;
    }

    /// @inheritdoc IPhutureJob
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_minAmountOfSigners != 0, "PhutureJob: INVALID");

        minAmountOfSigners = _minAmountOfSigners;
    }

    /// @inheritdoc IPhutureJob
    function reweight(address _index) external override onlyRole(ORDER_EXECUTOR_ROLE) payKeeper(msg.sender) {
        IOrderer(IIndexRegistry(registry).orderer()).reweight(_index);
    }

    /// @inheritdoc IPhutureJob
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrderer.InternalSwap calldata _info)
        external
        override
        onlyRole(ORDER_EXECUTOR_ROLE)
        payKeeper(msg.sender)
    {
        IOrderer orderer = IOrderer(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrderer.ExternalSwap calldata _info)
        external
        override
        onlyRole(ORDER_EXECUTOR_ROLE)
        payKeeper(msg.sender)
    {
        IOrderer orderer = IOrderer(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function nonces(address _signer) external view override returns (uint256) {
        return _nonces[_signer].current();
    }

    /// @notice Verifies that list of signatures provided by validator have signed given `_data` object
    /// @param _signs List of signatures
    /// @param _data Data object to verify signature
    function _validate(ValidatorLibrary.Sign[] calldata _signs, bytes memory _data) internal {
        uint signsCount = _signs.length;
        require(signsCount >= minAmountOfSigners, "PhutureJob: !ENOUGH_SIGNERS");

        address lastAddress = address(0);
        for (uint i; i < signsCount; ) {
            address signer = _signs[i].signer;
            require(uint160(signer) > uint160(lastAddress), "PhutureJob: UNSORTED");
            require(
                _signs[i].verify(_data, _useNonce(signer)) && IAccessControl(registry).hasRole(VALIDATOR_ROLE, signer),
                string.concat("PhutureJob: SIGN ", Strings.toHexString(uint160(signer), 20))
            );

            lastAddress = signer;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Return the current value of nonce and increment
    /// @param _signer Address of signer
    /// @return current Current nonce of signer
    function _useNonce(address _signer) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[_signer];
        current = nonce.current();
        nonce.increment();
    }
}
