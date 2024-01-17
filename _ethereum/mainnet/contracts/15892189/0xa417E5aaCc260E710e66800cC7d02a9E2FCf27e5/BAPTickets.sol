// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./AbstractERC1155Factory.sol";
import "./Strings.sol";
import "./BAPGenesisInterface.sol";
import "./BAPOrchestratorInterfaceV3.sol";

/*
 * @title ERC1155 token for BAP Tickets Selling
 */
contract BAPIRL is AbstractERC1155Factory {
    using Strings for uint256;

    struct Event {
        // Max amount of tickets of the event
        uint256 maxSupply;
        // Max amount of tickets allowed to buy in a tx
        uint8 maxPerTx;
        // Max amount of tickets allowed to own in a wallet
        uint8 maxPerWallet;
        // Ticket price
        uint256 price;
        // Status to sell tickets or not
        // 0 - sale close - no one can buy
        // 1 - public sale - everybody can buy, no checks
        // 2 - only gods owner - only god owners can buy (you're currently checking)
        // 3 - only signature - only users with a valid signature
        uint8 status;
    }

    mapping(uint256 => Event) public events;
    mapping(address => mapping(uint256 => uint256)) public ticketsBought;
    uint256 public currentEventId = 0; // The last event id

    BAPGenesisInterface public bapGenesis;
    BAPOrchestratorInterfaceV3 public bapOrchestratorV3;

    // Verify Signature
    address public secret;

    event CreatedEvent(
        uint256 indexed eventId,
        uint256 maxSupply,
        uint8 maxPerTx,
        uint8 maxPerWallet,
        uint256 ticketPrice,
        uint8 status
    );
    event Purchased(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _bapGenesis,
        address _bapOrchestratorV3
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;

        bapGenesis = BAPGenesisInterface(_bapGenesis);
        bapOrchestratorV3 = BAPOrchestratorInterfaceV3(_bapOrchestratorV3);
    }

    modifier noZeroAddress(address _address) {
        require(_address != address(0), "200:ZERO_ADDRESS");
        _;
    }

    modifier availableEvent(uint256 _id) {
        require(_id > 0 && _id <= currentEventId, "No exist event");
        _;
    }

    /**
     * @notice set event id that can be minted
     *
     * @param _maxSupply the max amount of tickets in the event
     * @param _maxPerTx the new max amount of tickets allowed to buy in a tx
     * @param _maxPerWallet the new max amount of tickets allowed to own in a wallet
     * @param _ticketPrice the price of ticket
     * @param _status status of the event
     */
    function createEvent(
        uint256 _maxSupply,
        uint8 _maxPerTx,
        uint8 _maxPerWallet,
        uint256 _ticketPrice,
        uint8 _status // 0: sale close, 1: public sale - everybody can buy, no checks, 2: only gods owner - only god owners can buy (you're currently checking), 3: only signature - only users with a valid signature
    ) external onlyOwner {
        require(_status < 4, "Wrong status value");

        currentEventId++;
        events[currentEventId] = Event({
            maxSupply: _maxSupply,
            maxPerTx: _maxPerTx,
            maxPerWallet: _maxPerWallet,
            price: _ticketPrice,
            status: _status
        });

        emit CreatedEvent(
            currentEventId,
            _maxSupply,
            _maxPerTx,
            _maxPerWallet,
            _ticketPrice,
            _status
        );
    }

    /**
     * @notice get event data
     */
    function getEvent(uint256 eventId)
        public
        view
        availableEvent(eventId)
        returns (Event memory)
    {
        return events[eventId];
    }

    /**
     * @notice edit the mint price
     *
     * @param _ticketPrice the new price in wei
     */
    function setPrice(uint256 _eventId, uint256 _ticketPrice)
        external
        availableEvent(_eventId)
        onlyOwner
    {
        events[currentEventId].price = _ticketPrice;
    }

    /**
     * @notice edit sale restrictions
     *
     * @param _maxPerTx the new max amount of tokens allowed to buy in one tx
     * @param _maxPerWallet the new max amount of tokens allowed to own in a wallet
     */
    function updateSaleRestrictions(
        uint256 _eventId,
        uint8 _maxPerTx,
        uint8 _maxPerWallet,
        uint8 _status
    ) external availableEvent(_eventId) onlyOwner {
        require(_status < 4, "Wrong status value");

        events[_eventId].maxPerTx = _maxPerTx;
        events[_eventId].maxPerWallet = _maxPerWallet;
        events[_eventId].maxPerWallet = _status;
    }

    /**
     * @notice update Genesis Contract
     *
     * @param _newAddress the new Genesis contract address
     */
    function setGenesisContract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapGenesis = BAPGenesisInterface(_newAddress);
    }

    /**
     * @notice update OrchestratorV3 Contract
     *
     * @param _newAddress the new OrchestratorV3 contract address
     */
    function setOrchestratorV3Contract(address _newAddress)
        external
        onlyOwner
        noZeroAddress(_newAddress)
    {
        bapOrchestratorV3 = BAPOrchestratorInterfaceV3(_newAddress);
    }

    /**
     * @notice set new secret address to verify signature
     *
     * @param _secret the new secret address
     */
    function setSecretAddress(address _secret)
        external
        onlyOwner
        noZeroAddress(_secret)
    {
        secret = _secret;
    }

    /**
     * @notice airdrop tickets
     *
     * @param account address to airdrop
     * @param amount the amount of cards to purchase
     */
    function airdrop(
        uint256 eventId,
        address account,
        uint256 amount
    )
        external
        availableEvent(eventId)
        whenNotPaused
        noZeroAddress(account)
        onlyOwner
    {
        require(
            totalSupply(eventId) + amount <= events[eventId].maxSupply,
            "Airdrop: Max supply reached"
        );

        _mint(account, eventId, amount, "");
    }

    /**
     * @notice purchase tickets
     *
     * @param godTokenId the genesis god token id
     * @param amount the amount of tokens to purchase
     */
    function purchase(
        uint256 eventId,
        uint256 amount,
        uint256 godTokenId,
        bytes memory signature
    ) external payable availableEvent(eventId) whenNotPaused {
        require(events[eventId].status != 0, "Sale is close.");

        if (events[eventId].status == 2) {
            // 2: only gods owner - only god owners can buy (you're currently checking)
            // Verify token owner
            require(
                bapGenesis.ownerOf(godTokenId) == msg.sender,
                "Only token owner can purchase"
            );
            // Verify god
            require(
                bapOrchestratorV3.godBulls(godTokenId),
                "Only god owner can purchase" // 3: only signature - only users with a valid signature
            );
        } else if (events[eventId].status == 3) {
            require(
                _verifyHashSignature(
                    keccak256(abi.encode(eventId, amount, msg.sender)),
                    signature
                ),
                "Signature is invalid"
            );
        }

        _purchase(eventId, amount);
    }

    /**
     * @notice global purchase function used in early access and public sale
     *
     * @param amount the amount of tokens to purchase
     */
    function _purchase(uint256 eventId, uint256 amount) private {
        require(
            amount > 0 && amount <= events[eventId].maxPerTx,
            "Purchase: amount prohibited"
        );
        require(
            ticketsBought[msg.sender][eventId] + amount <=
                events[eventId].maxPerWallet,
            "Purchase: balance is over."
        );
        require(
            totalSupply(eventId) + amount <= events[eventId].maxSupply,
            "Purchase: Max supply reached"
        );
        require(
            msg.value == amount * events[eventId].price,
            "Purchase: Incorrect payment"
        );

        ticketsBought[msg.sender][eventId] += amount;

        _mint(msg.sender, eventId, amount, "");
        emit Purchased(eventId, msg.sender, amount);
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the card id to return metadata for
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    function withdrawETH(address _address, uint256 amount)
        public
        nonReentrant
        noZeroAddress(_address)
        onlyOwner
    {
        require(amount <= address(this).balance, "Insufficient funds");
        (bool success, ) = _address.call{value: amount}("");

        require(success, "Unable to send eth");
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}
