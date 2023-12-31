// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRouterClient.sol";
import "./CCIPReceiver.sol";
import "./Client.sol";
import "./ERC721.sol";

contract CCIPeth is CCIPReceiver {
    error EmergencyPaused();
    error NotEnoughFees(uint256 calculatedFees, uint256 sentFees);
    error NotConfirmedSourceChain(uint64 sourceChainSelector);
    error NotConfirmedSender(address sender);
    error NotOwner(address caller, uint256 tokenId);
    error NotAdmin(address caller);
    error TravelLocked();
    error FailedToWithdrawEth(address admin, address target, uint256 value);
    error MigrationNotProposed();
    error TimestampNotPassed(uint blockTimestamp, uint allowedTimestamp);
    error ExceededMaxAmountOfNfts();
    error NotEOA();

    event MessageSent(bytes32 messageId);
    event MessageReceived(bytes32 messageId);
    event PenguinsUnlocked(address owner, uint256[] tokenIds);
    event QueuedToMigrate();
    event ExecuteMigration(address indexed migrateTo, uint256[] tokenIds);
    event CancelMigration();
    event SetSenderAddress(address sender);
    event SetAdmin(address admin);
    event SetGasLimit(uint256 gasLimit);
    event SetMaxAmountOfNfts(uint16);

    ERC721 cozyPenguin;
    IRouterClient public router;
    address public receiver;
    address private admin;
    address public confirmedSender;
    address public migrationAddress;
    uint256 public constant MIGRATION_DELAY_SECONDS = 3600 * 24 * 7;
    uint256 public migrationAllowedTimestamp;
    uint256 public gasLimit = 2000000;
    uint64 public destinationChainSelector;
    uint64 public sourceChainSelector;
    uint16 public maxAmountOfNfts = 25;
    bool public travelLock = false;
    bool public emergencyPause = false;

    constructor(
        address _router,
        address _admin,
        address _cozyPenguinNft,
        uint64 _destinationChainSelector,
        bool _travelLock
    ) CCIPReceiver(_router) {
        admin = _admin;
        cozyPenguin = ERC721(_cozyPenguinNft);
        destinationChainSelector = _destinationChainSelector;
        sourceChainSelector = _destinationChainSelector;
        travelLock = _travelLock;
        router = IRouterClient(_router);
    }

    modifier onlyNftOwner(uint256[] calldata _tokenIds) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (cozyPenguin.ownerOf(tokenId) != msg.sender) {
                revert NotOwner(msg.sender, tokenId);
            }
        }
        _;
    }
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin(msg.sender);
        }
        _;
    }

    modifier onlyConfirmedSender(address _sender) {
        if (_sender != confirmedSender) {
            revert NotConfirmedSender(_sender);
        }
        _;
    }
    modifier onlyConfirmedSourceChain(uint64 _sourceChainSelector) {
        if (_sourceChainSelector != sourceChainSelector) {
            revert NotConfirmedSourceChain(_sourceChainSelector);
        }
        _;
    }

    modifier allowedAmountOfNfts(uint256 _amountOfNfts) {
        if (_amountOfNfts > maxAmountOfNfts) {
            revert ExceededMaxAmountOfNfts();
        }
        _;
    }

    // Used in case if we have to change how penguins travel.
    modifier unlocked() {
        if (travelLock) {
            revert TravelLocked();
        }
        _;
    }

    modifier unpaused() {
        if (emergencyPause) {
            revert EmergencyPaused();
        }
        _;
    }

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

    // Show the required fee amount for the user.
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

    function _buildCCIPMessage(
        uint256[] calldata _tokenIds
    ) public view returns (Client.EVM2AnyMessage memory) {
        bytes memory messageData = abi.encode(msg.sender, _tokenIds); // ABI-encoded string message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: messageData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
            ),
            feeToken: address(0)
        });

        return evm2AnyMessage;
    }

    // Locks the existing NFTs in this contract and sends the message through the router.
    function travel(
        uint256[] calldata _tokenIds
    )
        external
        payable
        onlyNftOwner(_tokenIds)
        onlyEOA
        allowedAmountOfNfts(_tokenIds.length)
        unlocked
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory message = _buildCCIPMessage(_tokenIds);
        uint256 fees = router.getFee(destinationChainSelector, message);

        if (fees > msg.value) revert NotEnoughFees(fees, msg.value);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            cozyPenguin.transferFrom(msg.sender, address(this), tokenId);
        }

        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            message
        );

        emit MessageSent(messageId);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    )
        internal
        override
        unpaused
        onlyConfirmedSender(abi.decode(message.sender, (address)))
        onlyConfirmedSourceChain(message.sourceChainSelector)
    {
        emit MessageReceived(message.messageId);
        address owner;
        uint256[] memory tokenIds;
        (owner, tokenIds) = abi.decode(message.data, (address, uint256[]));

        unlockPenguin(owner, tokenIds);
        emit PenguinsUnlocked(owner, tokenIds);
    }

    // Unlocks the existing NFTs.
    function unlockPenguin(
        address _owner,
        uint256[] memory _tokenIds
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            cozyPenguin.transferFrom(address(this), _owner, tokenId);
        }
    }

    // ------ Receive Ether ---------

    receive() external payable {}

    // ------ Withdraw Ether ---------

    function withdraw(address beneficiary) external onlyAdmin {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    // ------ Administration ---------

    function setReceiverAddress(address _receiver) external onlyAdmin {
        receiver = _receiver;
    }

    function setDestinationChainSelector(
        uint64 _destinationChainSelector
    ) external onlyAdmin {
        destinationChainSelector = _destinationChainSelector;
    }

    function setSourceChainSelector(
        uint64 _sourceChainSelector
    ) external onlyAdmin {
        sourceChainSelector = _sourceChainSelector;
    }

    function setSenderAddress(address _sender) external onlyAdmin {
        confirmedSender = _sender;
        emit SetSenderAddress(_sender);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function setMaxAmountOfNfts(uint16 _maxAmountOfNfts) external onlyAdmin {
        maxAmountOfNfts = _maxAmountOfNfts;
        emit SetMaxAmountOfNfts(_maxAmountOfNfts);
    }

    function setGasLimit(uint256 _gasLimit) external onlyAdmin {
        gasLimit = _gasLimit;
        emit SetGasLimit(_gasLimit);
    }

    // ------------ Locking -------------

    function lockTravel(bool _lock) external onlyAdmin {
        travelLock = _lock;
    }

    function setEmergencyPause(bool _pause) external onlyAdmin {
        emergencyPause = _pause;
    }

    // -------- Migrating -----------

    function proposeMigration(address _migrateTo) external onlyAdmin {
        migrationAddress = _migrateTo;
        migrationAllowedTimestamp = block.timestamp + MIGRATION_DELAY_SECONDS;
        emit QueuedToMigrate();
    }

    function cancelMigration() external onlyAdmin {
        migrationAddress = address(0);
        emit CancelMigration();
    }

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
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (cozyPenguin.ownerOf(tokenIds[i]) != address(this)) {
                revert NotOwner(address(this), tokenIds[i]);
            }
            cozyPenguin.safeTransferFrom(
                address(this),
                migrationAddress,
                tokenIds[i]
            );
        }
        emit ExecuteMigration(migrationAddress, tokenIds);
    }
}
