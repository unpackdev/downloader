/// SPDX-License-Identifier: BUSL-1.1

/// Copyright (C) 2023 Brahma.fi

pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./AddressProviderService.sol";
import "./WalletRegistry.sol";
import "./PolicyRegistry.sol";
import "./ISafeProxyFactory.sol";
import "./ISafeWallet.sol";
import "./SafeHelper.sol";
import "./ISafeMultiSend.sol";

/**
 * @title SafeDeployer
 * @author Brahma.fi
 * @notice Deploys new brahma console accounts and sub accounts
 */
contract SafeDeployer is AddressProviderService, ReentrancyGuard {
    /// @notice version of safe deployer
    string public constant VERSION = "1";

    /**
     * @notice hash of safe create2 failure reason
     * @dev keccak256("Create2 call failed");
     */
    bytes32 internal constant _SAFE_CREATION_FAILURE_REASON =
        0xd7c71a0bdd2eb2834ad042153c811dd478e4ee2324e3003b9522e03e7b3735dc;

    event SafeProxyCreationFailure(address indexed singleton, uint256 indexed nonce, bytes initializer);
    event ConsoleAccountDeployed(address indexed consoleAddress);
    event SubAccountDeployed(address indexed subAccountAddress, address indexed consoleAddress);
    event PreComputeAccount(address[] indexed owners, uint256 indexed threshold);

    error InvalidCommitment();
    error NotWallet();
    error PreComputedAccount(address addr);
    error SafeProxyCreationFailed();

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /// @notice owners nonce
    mapping(bytes32 ownersHash => uint256 count) public ownerSafeCount;

    /**
     * @notice Deploys a new console account with or without policy commit and registers it
     * @dev _owners list should contain addresses in the same order to generate same console address on all chains
     * @param _owners list of safe owners
     * @param _threshold safe threshold
     * @param _policyCommit commitment
     * @param _salt salt to be used during creation of safe
     * @return _safe deployed console account address
     */
    function deployConsoleAccount(address[] calldata _owners, uint256 _threshold, bytes32 _policyCommit, bytes32 _salt)
        external
        nonReentrant
        returns (address _safe)
    {
        bool _policyHashValid = _policyCommit != bytes32(0);

        _safe = _createSafe(_owners, _setupConsoleAccount(_owners, _threshold, _policyHashValid), _salt);

        if (_policyHashValid) {
            PolicyRegistry(policyRegistry).updatePolicy(_safe, _policyCommit);
        }
        emit ConsoleAccountDeployed(_safe);
    }

    /**
     * @notice Deploys a new sub-account with policy commit and registers it
     * @dev ConsoleAccount is enabled as module
     * @param _owners list of safe owners
     * @param _threshold safe threshold
     * @param _policyCommit commitment
     * @param _salt salt to be used during creation of safe, to generate nonce
     * @return _subAcc deployed sub-account address
     */
    function deploySubAccount(address[] calldata _owners, uint256 _threshold, bytes32 _policyCommit, bytes32 _salt)
        external
        nonReentrant
        returns (address _subAcc)
    {
        // Policy commit is required for sub account
        if (_policyCommit == bytes32(0)) revert InvalidCommitment();

        // Check if msg.sender is a registered wallet
        if (!WalletRegistry(walletRegistry).isWallet(msg.sender)) revert NotWallet();

        // Deploy sub account
        _subAcc = _createSafe(_owners, _setupSubAccount(_owners, _threshold), _salt);

        // Register sub account to wallet
        WalletRegistry(walletRegistry).registerSubAccount(msg.sender, _subAcc);

        // Update policy commit for sub account
        PolicyRegistry(policyRegistry).updatePolicy(_subAcc, _policyCommit);
        emit SubAccountDeployed(_subAcc, msg.sender);
    }

    /**
     * @notice Private helper function to setup Console account with setUp transactions
     * @param _owners list of owners addresses
     * @param _threshold safe threshold
     */
    function _setupConsoleAccount(address[] memory _owners, uint256 _threshold, bool _policyHashValid)
        private
        view
        returns (bytes memory)
    {
        address fallbackHandler;
        Types.Executable[] memory txns;

        if (_policyHashValid) {
            txns = new Types.Executable[](2);
            fallbackHandler = AddressProviderService._getAuthorizedAddress(_CONSOLE_FALLBACK_HANDLER_HASH);

            // Enable guard on console account
            txns[1] = Types.Executable({
                callType: Types.CallType.DELEGATECALL,
                target: AddressProviderService._getAuthorizedAddress(_SAFE_ENABLER_HASH),
                value: 0,
                data: abi.encodeCall(
                    ISafeWallet.setGuard, (AddressProviderService._getAuthorizedAddress(_SAFE_MODERATOR_OVERRIDABLE_HASH))
                    )
            });
        } else {
            txns = new Types.Executable[](1);
            fallbackHandler = AddressProviderService._getAuthorizedAddress(_SAFE_FALLBACK_HANDLER_HASH);
        }

        // Register Wallet
        /// @dev This function is being packed as a part of multisend transaction as, safe internally performs
        // a delegatecall during initializer to the target contract, so direct call doesnt work. Multisend is
        // supposed to be delegatecall
        txns[0] = Types.Executable({
            callType: Types.CallType.CALL,
            target: walletRegistry,
            value: 0,
            data: abi.encodeCall(WalletRegistry.registerWallet, ())
        });

        return abi.encodeCall(
            ISafeWallet.setup,
            (
                _owners,
                _threshold,
                AddressProviderService._getAuthorizedAddress(_SAFE_MULTI_SEND_HASH),
                abi.encodeCall(ISafeMultiSend.multiSend, (SafeHelper._packMultisendTxns(txns))),
                fallbackHandler,
                address(0),
                0,
                address(0)
            )
        );
    }

    /**
     * @notice Private helper function to setup subAccount safe with setUp transactions
     * @param _owners list of owners addresses
     * @param _threshold safe threshold
     */
    function _setupSubAccount(address[] memory _owners, uint256 _threshold) private view returns (bytes memory) {
        address safeEnabler = AddressProviderService._getAuthorizedAddress(_SAFE_ENABLER_HASH);
        Types.Executable[] memory txns = new Types.Executable[](2);

        // Enable Brhma Console account as module on sub Account
        txns[0] = Types.Executable({
            callType: Types.CallType.DELEGATECALL,
            target: safeEnabler,
            value: 0,
            data: abi.encodeCall(ISafeWallet.enableModule, (msg.sender))
        });

        // Enable guard on subAccount
        txns[1] = Types.Executable({
            callType: Types.CallType.DELEGATECALL,
            target: safeEnabler,
            value: 0,
            data: abi.encodeCall(ISafeWallet.setGuard, (AddressProviderService._getAuthorizedAddress(_SAFE_MODERATOR_HASH)))
        });

        return abi.encodeCall(
            ISafeWallet.setup,
            (
                _owners,
                _threshold,
                AddressProviderService._getAuthorizedAddress(_SAFE_MULTI_SEND_HASH),
                abi.encodeCall(ISafeMultiSend.multiSend, (SafeHelper._packMultisendTxns(txns))),
                AddressProviderService._getAuthorizedAddress(_CONSOLE_FALLBACK_HANDLER_HASH),
                address(0),
                0,
                address(0)
            )
        );
    }

    /**
     * @notice Internal function to create a new Safe Wallet.
     * @dev SafeDeployer calls createProxyWithNonce to deploy a new Safe Wallet. This also contains initializer bytes
     *  which are used during creation to setup the safe with owners and threshold. An actor can precompute the salt
     *  for a given set of owners and deploy the safe. We choose to not consider that safe as a valid safe and deploy a new
     *  safe. In case the actor chooses to deploy multiple precomputed safes with bumped nonces, the transaction will run out
     *  of gas and user can retry with a new random salt
     *  To generate deterministic addresses for a given set of owners, the order of owner addresses and threshold should be same
     * @param _owners list of owners addresses
     * @param _salt salt to be used during creation of safe, to generate nonce
     * @return _safe The address of the created Safe Wallet.
     */
    function _createSafe(address[] calldata _owners, bytes memory _initializer, bytes32 _salt)
        private
        returns (address _safe)
    {
        address safeProxyFactory = AddressProviderService._getAuthorizedAddress(_SAFE_PROXY_FACTORY_HASH);
        address safeSingleton = AddressProviderService._getAuthorizedAddress(_SAFE_SINGLETON_HASH);
        bytes32 ownersHash = keccak256(abi.encode(_owners));

        // Generate nonce based on owners and user provided salt
        do {
            uint256 nonce = _genNonce(ownersHash, _salt);
            try ISafeProxyFactory(safeProxyFactory).createProxyWithNonce(safeSingleton, _initializer, nonce) returns (
                address _deployedSafe
            ) {
                _safe = _deployedSafe;
            } catch Error(string memory reason) {
                // KEK
                if (keccak256(bytes(reason)) != _SAFE_CREATION_FAILURE_REASON) {
                    // Revert if the error is not due to create2 call failure
                    revert SafeProxyCreationFailed();
                }
                // A safe is already deployed with the same salt, retry with bumped nonce
                emit SafeProxyCreationFailure(safeSingleton, nonce, _initializer);
            } catch {
                revert SafeProxyCreationFailed();
            }
        } while (_safe == address(0));
    }

    /**
     * @notice Internal function to get the nonce of a user's safe deployment
     * @param _ownersHash address of owner of the safe.
     * @param _salt salt to be used in nonce generation
     * @return The nonce of the user's safe deployment.
     */
    function _genNonce(bytes32 _ownersHash, bytes32 _salt) private returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_ownersHash, ownerSafeCount[_ownersHash]++, _salt, VERSION)));
    }
}
