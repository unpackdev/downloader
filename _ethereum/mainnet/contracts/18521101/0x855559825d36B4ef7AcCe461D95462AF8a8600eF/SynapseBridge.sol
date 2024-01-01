// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ISynapseBridge.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

/// @custom:security-contact vali@humans.ai
contract SynapseBridge is
    ISynapseBridge,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice initialize() is used to initialize the contract after it has been deployed
    /// @dev This function is called by the OpenZeppelin initializer framework
    /// @param _evmERC20Token The address of the $HEART ERC20 token contract on the Ethereum mainnet
    /// @param _nativeChainId The chain ID of the Humans mainnet
    /// @param _evmChainId The chain ID of the Ethereum mainnet
    function initialize(
        address _evmERC20Token,
        uint256 _nativeChainId,
        uint256 _evmChainId
    ) public initializer {
        if (_evmERC20Token == address(0)) revert AddressZeroCheck();
        if (_nativeChainId == 0) revert ChainIdZeroCheck();
        if (_evmChainId == 0) revert ChainIdZeroCheck();

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Set the native chain ID (where the bridge transfers native tokens)
        nativeChainId = _nativeChainId;

        // Set the evm chain ID (where the bridge transfers ERC20 tokens)
        evmChainId = _evmChainId;

        // Address of the ERC20 token contract that the bridge will transfer on the evm chain
        evmERC20Token = IERC20Upgradeable(_evmERC20Token);
    }

    // Wrapper around the interface that eliminates the need to handle boolean return values.
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Address of the $HEART ERC20 token contract on the Ethereum mainnet
    IERC20Upgradeable private evmERC20Token;

    // Roles
    bytes32 private constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Counter to track the number of deposits
    uint256 public depositsCounter;

    // Counter to track the number of withdrawals
    uint256 public withdrawalsCounter;

    // Chain ID of the Humans mainnet
    uint256 private nativeChainId;

    // Chain ID of the Ethereum mainnet
    uint256 private evmChainId;

    // Mapping to store deposit data
    mapping(uint256 id => Deposit) public deposits;

    // Mapping to store withdraw data
    mapping(uint256 id => Withdraw) public withdrawals;

    // Mapping to store used messageHash
    mapping(bytes32 messageHash => bool) private used;

    // Gap for upgrade safety
    uint256[50] private __gap;

    /// @notice depositERC20() allows users to deposit ERC20 tokens into the bridge
    /// @dev This function is non-reentrant and can only be called when the bridge is not paused
    /// @param receiver The address of the receiver on the destination network
    /// @param amount The amount of tokens to be deposited
    function depositERC20(
        address receiver,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (block.chainid != evmChainId) revert InvalidChainId();
        if (receiver == address(0)) revert AddressZeroCheck();
        if (amount == 0) revert InvalidAmount();

        // Check input parameters
        uint256 nonce = depositsCounter;

        // Check token balance before deposit
        uint256 balanceBefore = evmERC20Token.balanceOf(address(this));

        // Transfer to-be-deposited tokens from sender to this smart contract
        evmERC20Token.safeTransferFrom(msg.sender, address(this), amount);

        // Check if token balance has increased by amount
        if (evmERC20Token.balanceOf(address(this)) != balanceBefore + amount)
            revert InvalidTransfer();

        // Store deposit data in mapping
        deposits[nonce] = Deposit(
            address(evmERC20Token),
            address(0),
            msg.sender,
            receiver,
            amount,
            evmChainId,
            nativeChainId,
            nonce
        );

        // Emit event with deposit data
        emit DepositEvent(
            address(evmERC20Token),
            msg.sender,
            receiver,
            amount,
            evmChainId,
            nativeChainId,
            nonce
        );

        // Increment deposits counter
        depositsCounter++;
    }

    /// @notice depositNativeToken() allows users to deposit native tokens into the bridge
    /// @dev This function is non-reentrant and can only be called when the bridge is not paused
    /// @param receiver The address of the receiver on the destination network
    function depositNativeToken(
        address receiver
    ) external payable nonReentrant whenNotPaused {
        // Check input parameters
        if (block.chainid != nativeChainId) revert InvalidChainId();
        if (receiver == address(0)) revert AddressZeroCheck();
        if (msg.value == 0) revert InvalidAmount();

        uint256 nonce = depositsCounter;

        // Store deposit data in mapping
        deposits[nonce] = Deposit(
            address(0),
            address(evmERC20Token),
            msg.sender,
            receiver,
            msg.value,
            nativeChainId,
            evmChainId,
            nonce
        );

        // Emit event with deposit data
        emit DepositEvent(
            address(0),
            msg.sender,
            receiver,
            msg.value,
            nativeChainId,
            evmChainId,
            nonce
        );

        // Increment deposits counter
        depositsCounter++;
    }

    /// @notice withdrawERC20() allows users to withdraw ERC20 tokens from the bridge
    /// @dev This function is non-reentrant and can only be called when the bridge is not paused.
    /// @param sender The address of the sender on the source network
    /// @param amount The amount of tokens deposited and to be withdrawn
    /// @param nonce The nonce of the deposit
    /// @param signature The signature of the deposit
    function withdrawERC20(
        address sender,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        // Check input parameters
        if (sender == address(0)) revert AddressZeroCheck();
        if (amount == 0) revert InvalidAmount();
        if (evmERC20Token.balanceOf(address(this)) < amount)
            revert InsufficientAvailableBalance();

        // Generate message hash to verify signature
        bytes32 messageHash = keccak256(
            abi.encode(
                address(0),
                address(evmERC20Token),
                sender,
                msg.sender,
                amount,
                nativeChainId,
                evmChainId,
                nonce
            )
        );

        if (used[messageHash]) revert HashAlreadyUsed();

        // Recover signer from signature
        address signer = ECDSAUpgradeable.recover(
            ECDSAUpgradeable.toEthSignedMessageHash(messageHash),
            signature
        );

        // Check if signer has the signer role
        if (!hasRole(SIGNER_ROLE, signer)) revert InvalidSigner();

        // Mark the signature as used
        used[messageHash] = true;

        // Increment withdrawals counter
        withdrawalsCounter++;

        // Transfer ERC20 tokens if the source token is on Humans mainnet
        evmERC20Token.safeTransfer(msg.sender, amount);

        // Store withdraw data in mapping
        withdrawals[nonce] = Withdraw(
            address(0),
            address(evmERC20Token),
            sender,
            msg.sender,
            amount,
            nativeChainId,
            evmChainId,
            nonce
        );

        // Emit event with withdraw data
        emit WithdrawEvent(
            address(evmERC20Token),
            sender,
            msg.sender,
            amount,
            nativeChainId,
            evmChainId,
            nonce
        );
    }

    /// @notice withdrawNative() allows users to withdraw native tokens from the bridge
    /// @dev This function is non-reentrant and can only be called when the bridge is not paused.iveToken == address(0), it will withdraw evmERC20Token ERC20 tokens.
    /// @param sender The address of the sender on the source network
    /// @param amount The amount of tokens deposited and to be withdrawn
    /// @param nonce The nonce of the deposit
    /// @param signature The signature of the deposit
    function withdrawNative(
        address sender,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        // Check input parameters
        if (sender == address(0)) revert AddressZeroCheck();
        if (amount == 0) revert InvalidAmount();
        if (address(this).balance < amount)
            revert InsufficientAvailableBalance();

        // Generate message hash to verify signature
        bytes32 messageHash = keccak256(
            abi.encode(
                address(evmERC20Token),
                address(0),
                sender,
                msg.sender,
                amount,
                evmChainId,
                nativeChainId,
                nonce
            )
        );

        if (used[messageHash]) revert HashAlreadyUsed();

        // Recover signer from signature
        address signer = ECDSAUpgradeable.recover(
            ECDSAUpgradeable.toEthSignedMessageHash(messageHash),
            signature
        );

        // Check if signer has the signer role
        if (!hasRole(SIGNER_ROLE, signer)) revert InvalidSigner();

        // Mark the signature as used
        used[messageHash] = true;

        // Increment withdrawals counter
        withdrawalsCounter++;

        // Transfer native tokens
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert InvalidTransfer();

        // Store withdraw data in mapping
        withdrawals[nonce] = Withdraw(
            address(evmERC20Token),
            address(0),
            sender,
            msg.sender,
            amount,
            evmChainId,
            nativeChainId,
            nonce
        );

        // Emit event with withdraw data
        emit WithdrawEvent(
            address(0),
            sender,
            msg.sender,
            amount,
            evmChainId,
            nativeChainId,
            nonce
        );
    }

    /// @notice renounceClaim() allows users to renounce their claim on a deposit
    /// @dev This function is non-reentrant and can only be called when the bridge is not paused.
    /// @param destinationNetworkToken The address of the token deposited
    /// @param sender The address of the sender on the source network
    /// @param amount The amount of tokens deposited and to be withdrawn
    /// @param nonce The nonce of the deposit
    /// @param signature The signature of the deposit
    function renounceClaim(
        address destinationNetworkToken,
        address sender,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        // Check input parameters
        if (sender == address(0)) revert AddressZeroCheck();
        if (amount == 0) revert InvalidAmount();

        uint256 currentChainId = block.chainid;

        // Generate message hash to verify signature
        bytes32 messageHash;
        uint256 sourceChainId;
        uint256 destinationChainId;

        if (destinationNetworkToken == address(0)) {
            if (currentChainId == evmChainId) revert InvalidChainId();
            messageHash = keccak256(
                abi.encode(
                    address(evmERC20Token),
                    address(0),
                    sender,
                    msg.sender,
                    amount,
                    evmChainId,
                    nativeChainId,
                    nonce
                )
            );

            sourceChainId = evmChainId;
            destinationChainId = nativeChainId;
        } else {
            if (currentChainId == nativeChainId) revert InvalidChainId();
            messageHash = keccak256(
                abi.encode(
                    address(0),
                    address(evmERC20Token),
                    sender,
                    msg.sender,
                    amount,
                    nativeChainId,
                    evmChainId,
                    nonce
                )
            );

            sourceChainId = nativeChainId;
            destinationChainId = evmChainId;
        }

        if (used[messageHash]) revert HashAlreadyUsed();

        // Recover signer from signature
        address signer = ECDSAUpgradeable.recover(
            ECDSAUpgradeable.toEthSignedMessageHash(messageHash),
            signature
        );

        // Check if signer has the signer role
        if (!hasRole(SIGNER_ROLE, signer)) revert InvalidSigner();

        // Mark the signature as used
        used[messageHash] = true;

        // Emit event with renounce data
        emit RenounceEvent(
            destinationNetworkToken,
            sender,
            msg.sender,
            amount,
            sourceChainId,
            destinationChainId,
            nonce
        );
    }

    // ! Admin functions
    ///  @notice emergencyWithdrawNative() allows the admin to withdraw native tokens from the bridge
    ///  @dev This function can only be called by the admin
    function emergencyWithdrawNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InsufficientAvailableBalance();

        // Transfer native tokens to the admin
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) revert InvalidTransfer();

        // Emit event with withdraw data
        emit EmergencyWithdrawEvent(address(0), msg.sender, balance);
    }

    /// @notice emergencyWithdrawERC20() allows the admin to withdraw ERC20 tokens from the bridge
    /// @dev This function can only be called by the admin
    /// @param token The address of the ERC20 token to withdraw
    function emergencyWithdrawERC20(
        IERC20Upgradeable token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Get the token balance of this contract
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        if (balance == 0) {
            revert InsufficientAvailableBalance();
        }

        // Transfer ERC20 tokens to the admin
        IERC20Upgradeable(token).safeTransfer(msg.sender, balance);

        // Emit event with withdraw data
        emit EmergencyWithdrawEvent(address(token), msg.sender, balance);
    }

    /// @notice setSigner() allows the admin to grant the signer role to an address
    /// @dev This function can only be called by the admin
    /// @param _signer The address to grant the signer role to
    function setSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_signer == address(0)) revert AddressZeroCheck();
        _grantRole(SIGNER_ROLE, _signer);
    }

    /// @notice removeSigner() allows the admin to revoke the signer role from an address
    /// @dev This function can only be called by the admin
    /// @param _signer The address to revoke the signer role from
    function removeSigner(
        address _signer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_signer == address(0)) revert AddressZeroCheck();
        _revokeRole(SIGNER_ROLE, _signer);
    }

    /// @notice pause() allows the admin to pause the bridge
    /// @dev This function can only be called by the admin
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice unpause() allows the admin to unpause the bridge
    /// @dev This function can only be called by the admin
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice _authorizeUpgrade() allows the admin to upgrade the bridge
    /// @dev This function can only be called by the admin
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /// @notice receive() allows the contract to receive native tokens
    receive() external payable virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        emit PaymentReceived(msg.sender, msg.value);
    }
}
