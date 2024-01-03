// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract RaffleDraw is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The king token
    IERC20 public king;

    //Ticket cost
    uint256 public ticketCost = 20e18;
    // game to keep track of the map of us doing
    uint256 public game = 1;

    // we want to accumulate until min 100 Ticket Entries and max 200 Entries
    // before we do the Raffles draw of giving away a Knight NFT
    uint256 public minParticipants = 100;
    uint256 public maxParticipants = 200;
    uint256 public participantsNum = 0;

    bool public isLocked = false;

    // Winning Number
    address public winningAddress;

    // Accumalated Funds will be sent to this address
    address public poolAccumalator;

    // Key = Referee Value= Referer
    mapping(address => address) public referrers;

    // key = maxIndex value Mapping of (key = ticketNumber, value = array of walletAddressOfTicketHolder)
    mapping(uint256 => mapping(uint256 => address)) public participants;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event TicketCosts(uint256 cost);
    event Game(uint256 game);
    event GameOver(uint256 game);
    event Ticket(uint256 indexed game, address indexed participant, uint256 index, uint256 finalIndex);
    event Referrer(address indexed referrer, address indexed referree);
    event Winner(uint256 indexed game, uint256 index, address participant);

    constructor(address _king, address _poolAccumalator) public {
        require(_king != address(0), "invalid king address");
        king = IERC20(_king);
        revertZeroAddress(_poolAccumalator);
        poolAccumalator = _poolAccumalator;
        _status = _NOT_ENTERED;
        emit TicketCosts(ticketCost);
        emit Game(1);
    }

    // if there is no referrer, pass the msg.sender as the _referrer
    function buyTicket(address _referrer, uint _noOfTicket) external {
        require(_status != _ENTERED, "reentrant call");
        _status = _ENTERED;

        require(msg.sender == tx.origin, "smart contracts are not allowed");
        require(!isLocked, "Draw is locked");
        require(_noOfTicket>0, "no of Tickets must be more than 1");
        uint noOfTicket = _noOfTicket;
        if (
            _referrer != address(0) &&
            _referrer != msg.sender &&
            referrers[msg.sender] == address(0)
        ) {
            // msg.sender has no referer and has entered a referrer name
            referrers[msg.sender] = _referrer;
        }

        uint256 amountToPool = ticketCost.mul(noOfTicket);
        address actualReferrer = referrers[msg.sender];

        if (actualReferrer != address(0)) {
            uint256 referrerAward = ticketCost.mul(noOfTicket).div(20);
            amountToPool = amountToPool.sub(referrerAward);
            king.safeTransferFrom(msg.sender, actualReferrer, referrerAward);
            emit Referrer(actualReferrer, msg.sender);
        }
        king.safeTransferFrom(msg.sender, poolAccumalator, amountToPool);
        uint256 index = participantsNum;
        uint256 newIndex = index + noOfTicket;
        require( newIndex <= maxParticipants, "No of Ticket Reached Limit");
        participantsNum = newIndex;
        
        for(uint i = index ; i < participantsNum ; i ++){
            participants[game][i] = msg.sender;
            
        }

        emit Ticket(game, msg.sender, index,participantsNum);


        // Lock once it reaches maximum number of participants
        if (participantsNum == maxParticipants) {
            _lock();
            emit GameOver(game);
        }

        _status = _NOT_ENTERED;
    }

    function draw() public onlyOwner {
        require(isLocked == true, "is locked, draw disabled");
        uint256 winningNumber = _chooseRandomNumber();
        address winner = participants[game][winningNumber];
        winningAddress = winner;
        emit Winner(game, winningNumber, winner);

        game = game + 1;
        participantsNum = 0;
        _unlock();
        emit Game(game);
    }

    function _chooseRandomNumber() internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (now)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (now)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / (participantsNum - 1)) * (participantsNum - 1)));
    }

    function setLock(bool _isLocked) public onlyOwner {
        isLocked = _isLocked;
    }

    function _lock() internal {
        isLocked = true;
    }

    function _unlock() internal {
        isLocked = false;
    }

    function updatePoolAccumalator(address _poolAccumalator)
        public
        onlyOwner
    {
        revertZeroAddress(_poolAccumalator);
        poolAccumalator = _poolAccumalator;
    }

    function revertZeroAddress(address _address) private pure {
        require(_address != address(0), "zero address");
    }

    function changeTicketCost(uint256 _ticketCost) public onlyOwner {
        require(_ticketCost > 0, "Invalid Ticket Cost");
        ticketCost = _ticketCost;
        emit TicketCosts(ticketCost);
    }

    function changeReferrer(address _referrer, address _referee) public onlyOwner {
        referrers[_referee] = _referrer;
        emit Referrer(_referrer, _referee);
    }

    function changeMinParticipants(uint256 _minParticipants) public onlyOwner {
        minParticipants = _minParticipants;
    }

    function changeMaxParticipants(uint256 _maxParticipants) public onlyOwner {
        maxParticipants = _maxParticipants;
    }
}
