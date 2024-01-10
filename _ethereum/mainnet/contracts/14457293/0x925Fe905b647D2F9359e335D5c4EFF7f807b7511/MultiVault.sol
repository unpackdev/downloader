// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Clones.sol";

import "./IMultiVault.sol";
import "./IMultiVaultToken.sol";
import "./IBridge.sol";
import "./IVault.sol";

import "./MultiVaultLibrary.sol";

import "./MultiVaultToken.sol";
import "./ChainId.sol";


uint constant MAX_BPS = 10_000;
uint constant FEE_LIMIT = MAX_BPS / 2;
address constant ZERO_ADDRESS = address(0);

uint8 constant DECIMALS_LIMIT = 18;
uint256 constant SYMBOL_LENGTH_LIMIT = 32;
uint256 constant NAME_LENGTH_LIMIT = 32;


string constant API_VERSION = '0.1.1';


/// @notice Vault, based on Octus Bridge. Allows to transfer arbitrary tokens from Everscale
/// to EVM and backwards. Everscale tokens are called "natives" (eg QUBE). EVM tokens are called
/// "aliens" (eg AAVE).
/// Inspired by Yearn Vault V2.
contract MultiVault is IMultiVault, ReentrancyGuard, Initializable, ChainId {
    using SafeERC20 for IERC20;

//    function getInitHash() public pure returns(bytes32){
//        bytes memory bytecode = type(MultiVaultToken).creationCode;
//        return keccak256(abi.encodePacked(bytecode));
//    }

    mapping (address => Token) tokens_;
    mapping (address => EverscaleAddress) natives_;

    uint public override defaultDepositFee;
    uint public override defaultWithdrawFee;

    bool public override emergencyShutdown;

    address public override bridge;
    mapping(bytes32 => bool) public override withdrawalIds;
    EverscaleAddress rewards_;
    EverscaleAddress configurationNative_;

    address public override governance;
    address pendingGovernance;
    address public override guardian;
    address public override management;

    // STORAGE UPDATE 1
    EverscaleAddress configurationAlien_;

    /// @notice Get token information
    /// @param _token Token address
    function tokens(
        address _token
    ) external view override returns (Token memory) {
        return tokens_[_token];
    }

    /// @notice Get native Everscale token address for EVM token
    /// @param _token Token address
    function natives(
        address _token
    ) external view override returns (EverscaleAddress memory) {
        return natives_[_token];
    }

    /// @notice Rewards address
    /// @return Everscale address, used for collecting rewards.
    function rewards()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return rewards_;
    }

    /// @notice Native configuration address
    /// @return Everscale address, used for verifying native withdrawals
    function configurationNative()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configurationNative_;
    }

    /// @notice Alien configuration address
    /// @return Everscale address, used for verifying alien withdrawals
    function configurationAlien()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configurationAlien_;
    }

    modifier tokenNotBlacklisted(address token) {
        require(!tokens_[token].blacklisted);

        _;
    }

    modifier initializeToken(address token) {
        if (tokens_[token].activation == 0) {
            // Non-activated tokens are always aliens

            require(
                IERC20Metadata(token).decimals() <= DECIMALS_LIMIT &&
                bytes(IERC20Metadata(token).symbol()).length <= SYMBOL_LENGTH_LIMIT &&
                bytes(IERC20Metadata(token).name()).length <= NAME_LENGTH_LIMIT
            );

            _activateToken(token, false);
        }

        _;
    }

    modifier onlyEmergencyDisabled() {
        require(!emergencyShutdown, "Vault: emergency mode enabled");

        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);

        _;
    }

    modifier onlyPendingGovernance() {
        require(msg.sender == pendingGovernance);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        require(msg.sender == governance || msg.sender == management);

        _;
    }

    modifier onlyGovernanceOrGuardian() {
        require(msg.sender == governance || msg.sender == guardian);

        _;
    }

    modifier withdrawalNotSeenBefore(bytes memory payload) {
        bytes32 withdrawalId = keccak256(payload);

        require(!withdrawalIds[withdrawalId], "Vault: withdraw payload already seen");

        _;

        withdrawalIds[withdrawalId] = true;
    }

    modifier respectFeeLimit(uint fee) {
        require(fee <= FEE_LIMIT);

        _;
    }

    /// @notice Vault API version. Used to track the deployed version of this contract.
    //  @return api_version Current API version
    function apiVersion()
        external
        override
        pure
        returns (string memory api_version)
    {
        return API_VERSION;
    }

    /// @notice MultiVault initializer
    /// @param _bridge Bridge address
    /// @param _governance Governance address
    /// @param _rewards Everscale address for receiving rewards
    function initialize(
        address _bridge,
        address _governance,
        EverscaleAddress memory _rewards
    ) external override initializer {
        bridge = _bridge;
        emit UpdateBridge(bridge);

        governance = _governance;
        emit UpdateGovernance(governance);

        rewards_ = _rewards;
        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    /// @notice Add token to blacklist. Only native token can be blacklisted.
    /// Blacklisted tokens cant be deposited or withdrawn.
    /// @param token Token address
    function blacklistAddToken(
        address token
    ) public override onlyGovernance tokenNotBlacklisted(token) {
        tokens_[token].blacklisted = true;

        emit BlacklistTokenAdded(token);
    }

    /// @notice Remove token from blacklist.
    /// @param token Token address
    function blacklistRemoveToken(
        address token
    ) external override onlyGovernance {
        require(tokens_[token].blacklisted);

        tokens_[token].blacklisted = false;

        emit BlacklistTokenRemoved(token);
    }

    /// @notice Set address to receive fees.
    /// This may be called only by `governance`
    /// @param _rewards Rewards receiver in Everscale network
    function setRewards(
        EverscaleAddress memory _rewards
    ) external override onlyGovernance {
        rewards_ = _rewards;

        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    /// @notice Set default deposit fee.
    /// @param _defaultDepositFee Default deposit fee, should be less than FEE_LIMIT
    function setDefaultDepositFee(
        uint _defaultDepositFee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_defaultDepositFee)
    {
        defaultDepositFee = _defaultDepositFee;

        emit UpdateDefaultDepositFee(defaultDepositFee);
    }

    /// @notice Set default withdraw fee.
    /// @param _defaultWithdrawFee Default withdraw fee, should be less than FEE_LIMIT
    function setDefaultWithdrawFee(
        uint _defaultWithdrawFee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_defaultWithdrawFee)
    {
        defaultWithdrawFee = _defaultWithdrawFee;

        emit UpdateDefaultWithdrawFee(defaultWithdrawFee);
    }

    /// @notice Set deposit fee for specific token.
    /// This may be called only by `owner` or `management`.
    /// @param token Token address
    /// @param _depositFee Deposit fee, must be less than FEE_LIMIT.
    function setTokenDepositFee(
        address token,
        uint _depositFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_depositFee)
    {
        tokens_[token].depositFee = _depositFee;

        emit UpdateTokenDepositFee(token, _depositFee);
    }

    /// @notice Set withdraw fee for specific token.
    /// This may be called only by `governance` or `management`
    /// @param token Token address, must be enabled
    /// @param _withdrawFee Withdraw fee, must be less than FEE_LIMIT.
    function setTokenWithdrawFee(
        address token,
        uint _withdrawFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_withdrawFee)
    {
        tokens_[token].withdrawFee = _withdrawFee;

        emit UpdateTokenWithdrawFee(token, _withdrawFee);
    }

    /// @notice Set alien configuration address.
    /// @param _configuration The address to use for alien configuration.
    function setConfigurationAlien(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configurationAlien_ = _configuration;

        emit UpdateConfiguration(
            TokenType.Alien,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Set native configuration address.
    /// @param _configuration The address to use for native configuration.
    function setConfigurationNative(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configurationNative_ = _configuration;

        emit UpdateConfiguration(
            TokenType.Native,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Nominate new address to use as a governance.
    /// The change does not go into effect immediately. This function sets a
    /// pending change, and the governance address is not updated until
    /// the proposed governance address has accepted the responsibility.
    /// This may only be called by the `governance`.
    /// @param _governance The address requested to take over Vault governance.
    function setGovernance(
        address _governance
    ) external override onlyGovernance {
        pendingGovernance = _governance;

        emit NewPendingGovernance(pendingGovernance);
    }

    /// @notice Once a new governance address has been proposed using `setGovernance`,
    /// this function may be called by the proposed address to accept the
    /// responsibility of taking over governance for this contract.
    /// This may only be called by the `pendingGovernance`.
    function acceptGovernance()
        external
        override
        onlyPendingGovernance
    {
        governance = pendingGovernance;

        emit UpdateGovernance(governance);
    }

    /// @notice Changes the management address.
    /// This may only be called by `governance`
    /// @param _management The address to use for management.
    function setManagement(
        address _management
    )
        external
        override
        onlyGovernance
    {
        management = _management;

        emit UpdateManagement(management);
    }

    /// @notice Changes the address of `guardian`.
    /// This may only be called by `governance`.
    /// @param _guardian The new guardian address to use.
    function setGuardian(
        address _guardian
    )
        external
        override
        onlyGovernance
    {
        guardian = _guardian;

        emit UpdateGuardian(guardian);
    }

    /// @notice Activates or deactivates MultiVault emergency shutdown.
    ///     During emergency shutdown:
    ///     - Deposits are disabled
    ///     - Withdrawals are disabled
    /// This may only be called by `governance` or `guardian`.
    /// @param active If `true`, the MultiVault goes into Emergency Shutdown. If `false`, the MultiVault goes back into
    ///     Normal Operation.
    function setEmergencyShutdown(
        bool active
    ) external override {
        if (active) {
            require(msg.sender == guardian || msg.sender == governance);
        } else {
            require(msg.sender == governance);
        }

        emergencyShutdown = active;

        emit EmergencyShutdown(active);
    }

    /// @notice Transfer tokens to the Everscale. Works both for native and alien tokens.
    /// Approve is required only for alien tokens deposit.
    /// @param recipient Everscale recipient.
    /// @param token EVM token address, should not be blacklisted.
    /// @param amount Amount of tokens to transfer.
    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint amount
    )
        external
        override
        nonReentrant
        tokenNotBlacklisted(token)
        initializeToken(token)
        onlyEmergencyDisabled
    {
        uint fee = calculateMovementFee(amount, token, Fee.Deposit);

        bool isNative = tokens_[token].isNative;

        if (isNative) {
            IMultiVaultToken(token).burn(
                msg.sender,
                amount
            );

            _transferToEverscaleNative(token, recipient, amount - fee);

            if (fee > 0) _transferToEverscaleNative(token, rewards_, fee);
        } else {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );

            _transferToEverscaleAlien(token, recipient, amount - fee);

            if (fee > 0) _transferToEverscaleAlien(token, rewards_, fee);
        }

        emit Deposit(
            isNative ? TokenType.Native : TokenType.Alien,
            msg.sender,
            token,
            recipient.wid,
            recipient.addr,
            amount,
            fee
        );
    }

    /// @notice Save withdrawal for native token
    /// @param payload Withdraw payload
    /// @param signatures Payload signatures
    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            configurationNative_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        NativeWithdrawalParams memory withdrawal = MultiVaultLibrary.decodeNativeWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == getChainID());

        // Derive token address
        // Depends on the withdrawn token source
        address token = _getNativeWithdrawalToken(withdrawal);

        // Ensure token is not blacklisted
        require(!tokens_[token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = calculateMovementFee(
            withdrawal.amount,
            token,
            Fee.Withdraw
        );

        IMultiVaultToken(token).mint(
            withdrawal.recipient,
            withdrawal.amount - fee
        );

        if (fee > 0) _transferToEverscaleNative(token, rewards_, fee);

        emit Withdraw(
            TokenType.Native,
            payloadId,
            token,
            withdrawal.recipient,
            withdrawal.amount,
            fee
        );
    }

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            configurationAlien_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        AlienWithdrawalParams memory withdrawal = MultiVaultLibrary.decodeAlienWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == getChainID());

        // Ensure token is not blacklisted
        require(!tokens_[withdrawal.token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = calculateMovementFee(
            withdrawal.amount,
            withdrawal.token,
            Fee.Withdraw
        );

        IERC20(withdrawal.token).safeTransfer(
            withdrawal.recipient,
            withdrawal.amount - fee
        );

        if (fee > 0) _transferToEverscaleAlien(withdrawal.token, rewards_, fee);

        emit Withdraw(
            TokenType.Alien,
            payloadId,
            withdrawal.token,
            withdrawal.recipient,
            withdrawal.amount,
            fee
        );
    }

    function migrateAlienTokenToVault(
        address token,
        address vault
    )
        external
        override
        onlyGovernance
    {
        require(tokens_[token].activation > 0);
        require(!tokens_[token].isNative);

        require(IVault(vault).token() == token);
        require(IVault(token).governance() == governance);

        tokens_[token].blacklisted = true;

        IERC20(token).safeTransfer(
            vault,
            IERC20(token).balanceOf(address(this))
        );

        emit TokenMigrated(token, vault);
    }

    /// @notice Calculates fee for deposit or withdrawal.
    /// @param amount Amount of tokens.
    /// @param _token Token address.
    /// @param fee Fee type (Deposit = 0, Withdraw = 1).
    function calculateMovementFee(
        uint256 amount,
        address _token,
        Fee fee
    ) public view returns (uint256) {
        Token memory token = tokens_[_token];

        uint tokenFee = fee == Fee.Deposit ? token.depositFee : token.withdrawFee;

        return tokenFee * amount / MAX_BPS;
    }

    function getNativeToken(
        int8 native_wid,
        uint256 native_addr
    ) external view returns (address) {
        return MultiVaultLibrary.getNativeToken(native_wid, native_addr);
    }

    function _activateToken(
        address token,
        bool isNative
    ) internal {
        tokens_[token].activation = block.number;
        tokens_[token].blacklisted = false;
        tokens_[token].isNative = isNative;
        tokens_[token].depositFee = defaultDepositFee;
        tokens_[token].withdrawFee = defaultWithdrawFee;

        emit TokenActivated(
            token,
            block.number,
            isNative,
            defaultDepositFee,
            defaultWithdrawFee
        );
    }

    function _transferToEverscaleNative(
        address _token,
        EverscaleAddress memory recipient,
        uint amount
    ) internal {
        EverscaleAddress memory native = natives_[_token];

        emit NativeTransfer(
            native.wid,
            native.addr,
            uint128(amount),
            recipient.wid,
            recipient.addr
        );
    }

    function _transferToEverscaleAlien(
        address _token,
        EverscaleAddress memory recipient,
        uint amount
    ) internal {
        emit AlienTransfer(
            getChainID(),
            uint160(_token),
            IERC20Metadata(_token).name(),
            IERC20Metadata(_token).symbol(),
            IERC20Metadata(_token).decimals(),
            uint128(amount),
            recipient.wid,
            recipient.addr
        );
    }

    function _getNativeWithdrawalToken(
        NativeWithdrawalParams memory withdrawal
    ) internal returns (address token) {
        token = MultiVaultLibrary.getNativeToken(
            withdrawal.native.wid,
            withdrawal.native.addr
        );

        if (tokens_[token].activation == 0) {
            _deployTokenForNative(withdrawal.native, withdrawal.meta);
            _activateToken(token, true);

            natives_[token] = withdrawal.native;
        }
    }

    function _deployTokenForNative(
        EverscaleAddress memory native,
        TokenMeta memory meta
    ) internal returns (address token) {
        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(native.wid, native.addr));

        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IMultiVaultToken(token).initialize(
            string(abi.encodePacked('Octus ', meta.name)),
            string(abi.encodePacked('oct', meta.symbol)),
            meta.decimals
        );

        emit TokenCreated(
            token,
            native.wid,
            native.addr,
            meta.name,
            meta.symbol,
            meta.decimals
        );
    }

    function _processWithdrawEvent(
        bytes memory payload,
        bytes[] memory signatures,
        EverscaleAddress memory configuration
    ) internal returns (EverscaleEvent memory) {
        require(
            IBridge(bridge).verifySignedEverscaleEvent(payload, signatures) == 0,
            "Vault: signatures verification failed"
        );

        // Decode Everscale event
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == configuration.wid &&
            _event.configurationAddress == configuration.addr
        );

        return _event;
     }
}