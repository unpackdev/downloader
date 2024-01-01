// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRouterClient.sol";
import "./CCIPReceiver.sol";
import "./Client.sol";
import "./ERC721.sol";

/// @title Cozy Penguin NFT bridge powered by Chainlink CCIP - Eth side
/// @author Cozy Labs
/// @notice Send Cozy Penguin NFTs to Avalanche using Chainlink CCIP
///         Code reviewed by engineers external to Cozy Labs, no formal audit
///         WARNING: Experimental, use or replicate at your own risk.
contract CCIPeth is CCIPReceiver {
    error EmergencyPaused();
    error NotEnoughFees(uint256 calculatedFees, uint256 sentFees);
    error NotConfirmedSourceChain(uint64 sourceChainSelector);
    error NotConfirmedSourceAddress(address sourceAddress);
    error NotOwner(address caller, uint256 tokenId);
    error NotAdmin(address caller);
    error TravelLocked();
    error FailedToWithdrawEth(address admin, address target, uint256 value);
    error MigrationNotProposed();
    error TimestampNotPassed(uint blockTimestamp, uint allowedTimestamp);
    error ExceededMaxAmountOfNfts();
    error NotEOA();
    error NotSortedTokenIds();

    /// @notice Message ID of successful travel call to CCIP
    event MessageSent(bytes32 messageId);
    /// @notice Message ID of a received message from authorized sender
    event MessageReceived(bytes32 messageId);
    /// @notice tokenIds of Cozy Penguins unlocked and the address
    ///         they are sent to
    event PenguinsUnlocked(address owner, uint256[] tokenIds);
    /// @notice A migration of NFTs locked in the contract is proposed
    event MigrationQueued();
    /// @notice A migration of tokens out of the contract occurred
    event MigrationExecuted(address indexed migrateTo, uint256[] tokenIds);
    /// @notice A migration proposal is cancelled
    event MigrationCanceled();
    /// @notice A new authorized source address is set
    event SourceAddressSet(address sourceAddress);
    /// @notice A new contract admin is set
    event AdminSet(address admin);
    /// @notice A new gas limit on travel calls is set
    event GasLimitSet(uint256 gasLimit);
    /// @notice A new limit on NFTs sent per travel call is set
    event MaxAmountOfNftsSet(uint16);

    /// @notice the Cozy Penguin NFT contract
    ERC721 public immutable cozyPenguin;
    /// @notice the CCIP router client
    IRouterClient public immutable router;
    /// @notice address of the bridge contract on Avalanche
    address public targetAddress;
    /// @notice address of the admin that can perform maintenance
    address private admin;
    /// @notice address of the contract that this contract is
    ///         authorized to receive CCIP messages from
    address public sourceAddress;
    /// @notice proposed address to migrate locked Cozys to
    address public migrationAddress;
    /// @notice minimum time required to pass after proposal to migrate
    uint256 public constant MIGRATION_DELAY_DAYS = 7 days;
    /// @notice timestamp after migration to proposed address can occur
    uint256 public migrationAllowedTimestamp;
    /// @notice gasLimit of receiving CCIP call on destination chain
    uint256 public gasLimit = 2000000;
    /// @notice CCIP chain selector of destination (and source)
    uint64 public immutable destinationChainSelector;
    /// @notice Max amount of NFTs that can be transferred at once
    uint16 public maxAmountOfNfts = 25;
    /// @notice boolean that allows users to travel
    bool public travelLock = false;
    /// @notice boolean that allows receiver to process inbound messages
    bool public emergencyPause = false;

    /// @param _router CCIP router address
    /// @param _admin Contract admin address
    /// @param _cozyPenguinNft address of the ERC NFT contract
    /// @param _destinationChainSelector ID of the bridge sends and receives from
    /// @param _travelLock Initial state of travelLock (true = users can't send)
    constructor(
        address _router,
        address _admin,
        address _cozyPenguinNft,
        uint64 _destinationChainSelector,
        bool _travelLock
    ) CCIPReceiver(_router) {
        admin = _admin;
        cozyPenguin = ERC721(_cozyPenguinNft);
        require(
            IRouterClient(_router).isChainSupported(_destinationChainSelector),
            "Unsupported chain selector"
        );
        destinationChainSelector = _destinationChainSelector;
        travelLock = _travelLock;
        router = IRouterClient(_router);
    }

    /// @notice Modifier for admin only calls
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin(msg.sender);
        }
        _;
    }

    /// @notice modifier to confirm cross chain message
    ///         sender contract address
    modifier onlyConfirmedSourceAddress(address _sourceAddress) {
        if (_sourceAddress != sourceAddress) {
            revert NotConfirmedSourceAddress(_sourceAddress);
        }
        _;
    }

    /// @notice modifier to confirm chain the message came from
    modifier onlyConfirmedSourceChain(uint64 _sourceChainSelector) {
        if (_sourceChainSelector != destinationChainSelector) {
            revert NotConfirmedSourceChain(_sourceChainSelector);
        }
        _;
    }

    /// @notice modifier to ensure traveling NFTs under limit
    modifier allowedAmountOfNfts(uint256 _amountOfNfts) {
        if (_amountOfNfts > maxAmountOfNfts) {
            revert ExceededMaxAmountOfNfts();
        }
        _;
    }

    /// @notice modifier to ensure bridge is unlocked
    modifier unlocked() {
        if (travelLock) {
            revert TravelLocked();
        }
        _;
    }

    /// @notice modifier to ensure no emeregency pause before
    ///         processing a CCIP receive message
    modifier unpaused() {
        if (emergencyPause) {
            revert EmergencyPaused();
        }
        _;
    }

    /// @notice Best effort check to ensure Cozys are sent from EOAs,
    ///         as destinations address is same as sender address
    /// @dev Can be circumvented via constructor call - doesn't benefit caller
    modifier onlyEOA() {
        address sender = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        if (size > 0) {
            revert NotEOA();
        }
        _;
    }

    // ------ CCIP ---------

    /// @notice Calculate the fees for a travel call
    /// @param _tokenIds An ordered list of token Ids to be sent
    function travelRequest(
        uint256[] calldata _tokenIds
    )
        external
        view
        unlocked
        allowedAmountOfNfts(_tokenIds.length)
        returns (uint256 fees)
    {
        Client.EVM2AnyMessage memory message = _buildCCIPMessage(_tokenIds);
        fees = router.getFee(destinationChainSelector, message);

        return fees;
    }

    /// @notice Builds the message to be sent to the CCIP router
    function _buildCCIPMessage(
        uint256[] calldata _tokenIds
    ) public view returns (Client.EVM2AnyMessage memory) {
        bytes memory messageData = abi.encode(msg.sender, _tokenIds);
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(targetAddress),
            data: messageData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
            ),
            feeToken: address(0)
        });

        return evm2AnyMessage;
    }

    /// @notice Locks NFT tokens and sends a message to mint/unlock on
    ///         destination chain and target address
    /// @notice Must send fee amount determined by `travelRequest`
    /// @notice Can only call travel from EOAs, sending from contract
    ///         will result in locked Cozys!!!
    /// @param _tokenIds An ordered list of token ids to be sent.
    ///        Note: out of order or duplicate ids will result in a revert
    function travel(
        uint256[] calldata _tokenIds
    )
        external
        payable
        onlyEOA
        allowedAmountOfNfts(_tokenIds.length)
        unlocked
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory message = _buildCCIPMessage(_tokenIds);
        uint256 fees = router.getFee(destinationChainSelector, message);

        if (fees > msg.value) revert NotEnoughFees(fees, msg.value);

        uint256 tokenId;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            tokenId = _tokenIds[i];
            if (i > 0 && tokenId <= _tokenIds[i - 1]) {
                revert NotSortedTokenIds();
            }
            if (cozyPenguin.ownerOf(tokenId) != msg.sender) {
                revert NotOwner(msg.sender, tokenId);
            }
            cozyPenguin.transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        }

        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            message
        );

        emit MessageSent(messageId);
    }

    /// @notice Receive owner & tokenIds data from CCIP. Unlocks penguins
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    )
        internal
        override
        unpaused
        onlyConfirmedSourceAddress(abi.decode(message.sender, (address)))
        onlyConfirmedSourceChain(message.sourceChainSelector)
    {
        emit MessageReceived(message.messageId);
        (address owner, uint256[] memory tokenIds) = abi.decode(
            message.data,
            (address, uint256[])
        );

        unlockPenguin(owner, tokenIds);
        emit PenguinsUnlocked(owner, tokenIds);
    }

    /// @notice Sends penguins from contract to owner
    /// @param _owner address to send penguins to
    /// @param _tokenIds Token ids to send
    function unlockPenguin(
        address _owner,
        uint256[] memory _tokenIds
    ) internal {
        uint256 tokenId;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            tokenId = _tokenIds[i];
            cozyPenguin.transferFrom(address(this), _owner, tokenId);
        }
    }

    // ------ Receive Ether ---------

    receive() external payable {}

    // ------ Withdraw Ether ---------

    /// @notice Withdraw native token. Not part of core workflow
    /// @notice Admin only operation
    /// @param beneficiary address to send tokens to
    function withdraw(address beneficiary) external onlyAdmin {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    // ------ Administration ---------

    /// @notice Set new target contract address for CCIP messages
    /// @notice Admin only operation
    /// @param _targetAddress New address CCIP will send messages to
    function setTargetAddress(address _targetAddress) external onlyAdmin {
        targetAddress = _targetAddress;
    }

    /// @notice Set new source contract address to receive CCIP messages
    /// @notice Admin only operation
    /// @param _sourceAddress New address that contract is authorized to
    ///        receive CCIP messages from
    function setSourceAddress(address _sourceAddress) external onlyAdmin {
        sourceAddress = _sourceAddress;
        emit SourceAddressSet(_sourceAddress);
    }

    /// @notice Set new contract admin
    /// @notice Admin only operation
    /// @param _admin New address for contract admin
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
        emit AdminSet(_admin);
    }

    /// @notice Set new max NFTs that can travel in one call
    /// @notice Admin only operation
    /// @param _maxAmountOfNfts New number of max NFts to be sent
    function setMaxAmountOfNfts(uint16 _maxAmountOfNfts) external onlyAdmin {
        maxAmountOfNfts = _maxAmountOfNfts;
        emit MaxAmountOfNftsSet(_maxAmountOfNfts);
    }

    /// @notice Set new Gas Limit on what CCIP can use on destination call
    /// @notice Admin only operation
    /// @param _gasLimit New gas limit (max 2,000,000 for now)
    function setGasLimit(uint256 _gasLimit) external onlyAdmin {
        gasLimit = _gasLimit;
        emit GasLimitSet(_gasLimit);
    }

    // ------------ Locking -------------

    /// @notice Set travel lock state (true = no travel, false = can travel)
    /// @notice Admin only operation
    /// @param _lock Boolean determining if the travel call is locked
    function lockTravel(bool _lock) external onlyAdmin {
        travelLock = _lock;
    }

    /// @notice Set emergency pause state that determines if contract can
    ///         can receive CCIP messages
    /// @notice Admin only operation
    /// @param _pause Boolean determining pause (true = no message, false = yes)
    function setEmergencyPause(bool _pause) external onlyAdmin {
        emergencyPause = _pause;
    }

    // -------- Migrating -----------

    /// @notice Propose new address to migrate to. Subject to timelock
    /// @notice Admin only operation
    /// @param _migrateTo New address to allow transfer of NFTs to
    function proposeMigration(address _migrateTo) external onlyAdmin {
        migrationAddress = _migrateTo;
        migrationAllowedTimestamp = block.timestamp + MIGRATION_DELAY_DAYS;
        emit MigrationQueued();
    }

    /// @notice Cancel migration proposal by setting migration address
    ///         to the zero address
    /// @notice Admin only operation
    function cancelMigration() external onlyAdmin {
        migrationAddress = address(0);
        emit MigrationCanceled();
    }

    /// @notice Migrate specified NFTs to the migration address
    /// @notice Can only migrate eafter timelock is up
    /// @notice Can't migrate to zero address
    /// @notice Admin only operation
    /// @param tokenIds Token ids to migrate
    function migrate(uint256[] calldata tokenIds) external onlyAdmin {
        if (migrationAddress == address(0)) {
            revert MigrationNotProposed();
        }
        if (block.timestamp < migrationAllowedTimestamp) {
            revert TimestampNotPassed(
                block.timestamp,
                migrationAllowedTimestamp
            );
        }
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            if (i > 0 && tokenId <= tokenIds[i - 1]) {
                revert NotSortedTokenIds();
            }
            if (cozyPenguin.ownerOf(tokenId) != address(this)) {
                revert NotOwner(address(this), tokenId);
            }
            cozyPenguin.safeTransferFrom(
                address(this),
                migrationAddress,
                tokenId
            );
        }
        emit MigrationExecuted(migrationAddress, tokenIds);
    }
}
