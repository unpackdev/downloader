// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IRMU.sol";
import "./IHopeNonTradable.sol";
import "./IHope.sol";

//import "./console.sol";

contract HopeRaffle is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Ticket {
        address owner;                           // Address owning tickets
        uint256 amount;                          // Amount of tickets purchased
    }

    struct Raffle {
        uint256[] nftIds;                        // Raffle will cycle through those NFTs until all are minted
        uint256 currentNftIndex;                 // The index of NFT to be won in the raffle (This is the index in nftIds) Ex : if nftIds = [2,5,6] and currentNftIndex is 0, then nftId is 2;
        uint256 ticketsPurchased;                // The number of ticket purchased (Once it reaches nbTickets, we can settle)
        uint256 ticketsRequired;                 // Amount of tickets required to sell before we can settle
        uint256 ticketPrice;                     // Price of each ticket
        address[] participants;                  // All participants of current raffle
        mapping (address => uint256) tickets;    // Ticket balances
        bool isDisabled;                         // If true, this raffle will be disabled once current ends
    }

    IRMU public rmu;
    IHopeNonTradable public hopeNonTradable;
    IHope public hope;

    Raffle[] public raffles;

    ////////////
    // Events //
    ////////////

    event RaffleAdded(uint256 id);
    event TicketsPurchased(address indexed user, uint256 indexed id, uint256 amount);
    event RaffleSettled(address indexed winner, uint256 indexed id, uint256 nftId, uint256 ticketsPurchased);
    event RaffleInitialized(uint256 indexed id, uint256 nftId);
    event RaffleDisabled(uint256 id, bool isDisabled);

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    constructor(IRMU _rmu, IHopeNonTradable _hopeNonTradable, IHope _hope) public {
        rmu = _rmu;
        hopeNonTradable = _hopeNonTradable;
        hope = _hope;
    }


    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not eoa");
        _;
    }

    ///////////
    // Admin //
    ///////////

    function addRaffle(uint256[] memory _nftIds, uint256 _ticketsRequired, uint256 _ticketPrice) public onlyOwner {
        raffles.push(Raffle({
            nftIds: _nftIds,
            currentNftIndex: 0,
            ticketsPurchased: 0,
            ticketsRequired: _ticketsRequired,
            ticketPrice: _ticketPrice,
            participants: new address[](0),
            isDisabled: false
        }));

        // Mint card and keep it in contract
        rmu.mint(address(this), _nftIds[0], 1, "");

        emit RaffleAdded(raffles.length.sub(1));
    }

    function setRaffleDisabled(uint256 _id, bool _state) public onlyOwner {
        raffles[_id].isDisabled = _state;
        emit RaffleDisabled(_id, _state);
    }

    //////////
    // View //
    //////////

    function rafflesLength() public view returns(uint256) {
        return raffles.length;
    }

    function getRaffleNftIds(uint256 _id) public view returns(uint256[] memory) {
        return raffles[_id].nftIds;
    }

    function getRaffleParticipants(uint256 _id) public view returns(address[] memory) {
        return raffles[_id].participants;
    }

    function getRaffleUserTicketBalance(uint256 _id, address _user) public view returns(uint256) {
        return raffles[_id].tickets[_user];
    }

    //////////
    // Main //
    //////////

    function buyTickets(uint256 _id, uint256 _amount, bool _useHopeNonTradable) public nonReentrant {
        Raffle storage raffle = raffles[_id];

        require(!(raffle.isDisabled && raffle.ticketsPurchased == 0), "Raffle disabled");

        if (raffle.ticketsPurchased.add(_amount) > raffle.ticketsRequired) {
            _amount = raffle.ticketsRequired.sub(raffle.ticketsPurchased);
            require(_amount != 0, "No tickets left");
        }

        uint256 totalPrice = raffle.ticketPrice.mul(_amount);

        if (_useHopeNonTradable) {
            hopeNonTradable.burn(msg.sender, totalPrice);
        } else {
            hope.burn(msg.sender, totalPrice);
        }

        raffle.ticketsPurchased = raffle.ticketsPurchased.add(_amount);

        if (!_isInArray(msg.sender, raffle.participants)) {
            raffle.participants.push(msg.sender);
        }

        raffle.tickets[msg.sender] = raffle.tickets[msg.sender].add(_amount);

        emit TicketsPurchased(msg.sender, _id, _amount);
    }

    function settleRaffle(uint256 _id) public nonReentrant onlyEOA {
        Raffle storage raffle = raffles[_id];
        require(raffle.ticketsPurchased == raffle.ticketsRequired, "Tickets not sold out");

        uint256 rng = _rng() % raffle.ticketsRequired;

        uint256 cumul = 0;
        for (uint256 i = 0; i < raffle.participants.length; ++i) {
            address user = raffle.participants[i];
            uint256 balance = raffle.tickets[user];

            if (balance == 0) continue;

            cumul = cumul.add(balance);

            if (rng < cumul) {
                // Winner
                uint256 currentNftIndex = raffle.currentNftIndex;
                rmu.safeTransferFrom(address(this), user, raffle.nftIds[currentNftIndex], 1, "");
                emit RaffleSettled(user, _id, raffle.nftIds[currentNftIndex], balance);
                break;
            }
        }

        _initNextRaffle(_id);
    }

    //////////////
    // Internal //
    //////////////

    function _initNextRaffle(uint256 _id) internal {
        Raffle storage raffle = raffles[_id];

        raffle.ticketsPurchased = 0;

        // Reset ticket balances
        for (uint256 i = 0; i < raffle.participants.length; ++i) {
            address user = raffle.participants[i];
            delete raffle.tickets[user];
        }

        // Reset participants
        raffle.participants = new address[](0);

        // Look for next available nft
        for (uint256 i = 1; i <= raffle.nftIds.length; ++i) {
            uint256 newIndex = raffle.currentNftIndex.add(i) % raffle.nftIds.length;

            uint256 nftId = raffle.nftIds[newIndex];
            if (rmu.totalSupply(nftId) < rmu.maxSupply(nftId)) {
                raffle.currentNftIndex = newIndex;

                // Mint card and keep it in contract
                rmu.mint(address(this), raffle.nftIds[newIndex], 1, "");
                emit RaffleInitialized(_id, raffle.nftIds[newIndex]);
                return;
            }
        }

        // If we reach this, there is no more NFT to mint, so we disable this raffle
        raffle.isDisabled = true;
        emit RaffleDisabled(_id, true);
    }

    // Utility function to check if a value is inside an array
    function _isInArray(address _value, address[] memory _array) internal pure returns(bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; ++i) {
            if (_array[i] == _value) {
                return true;
            }
        }

        return false;
    }

    // This is a pseudo random function, but considering the fact that redeem function is not callable by contract,
    // and the fact that Hope is not transferable, this should be enough to protect us from an attack
    // I would only expect a miner to be able to exploit this, and the attack cost would not be worth it in our case
    function _rng() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked((block.timestamp).add
        (block.difficulty).add
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
            block.timestamp).add
        (block.gaslimit).add
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
            block.timestamp).add
            (block.number)
            )));
    }

    /////////
    /////////
    /////////

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4) {
        return 0xf23a6e61;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4) {
        return 0xbc197c81;
    }

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Whether ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}