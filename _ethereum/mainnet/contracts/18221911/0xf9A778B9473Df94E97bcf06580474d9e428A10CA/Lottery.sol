//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./VRFV2WrapperConsumerBase.sol";

/**
 * @title Lottery
 * @dev A smart contract for a lottery game using ERC721 tokens.
 */
contract Lottery is ERC721, Ownable, VRFV2WrapperConsumerBase {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256 private constant MAX_NUMBERS = 30;
    uint256 private constant NUM_DIGITS = 2;
    uint256 private constant NUM_WINNING_NUMBERS = 6;

    uint32 constant callbackGasLimit = 400000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 6;
    address constant linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    uint256 public roundId = 1;
    uint256 public lastDrawTime;
    uint256 public nextDrawTime;
    uint256 public jackPotValue;
    uint256 public unclaimedValues;
    uint256 public drawFrequency = 7 days;

    uint256[] public lastDrawNumbers;

    uint256 public ticketPrize = 5 * 10 ** 15;

    uint256 public marketingFee = 10;

    address public marketingAddress =
        0x142619d565b3821E2a28170A9c3BAcFf515123F5;

    struct LotteryTicket {
        uint256[] numbers;
        uint256 roundId;
        bool claimed;
        bool isWinner;
        uint256 winningAmount;
    }

    struct Draw {
        bool isDraw;
        uint256[] winingNumbers;
        bool isFullFilled;
        bool isClaimeSet;
        uint256 numberOfWinners;
        uint256 startingJackpot;
        uint256 drawedAt;
        uint256 ticketSold;
    }

    struct UserDetais {
        uint256 numberOfWinningTickets;
        uint256 claimedRewards;
        uint256 totalRewards;
    }

    mapping(uint256 => LotteryTicket) private _tickets;
    mapping(address => mapping(uint256 => uint256[])) public _userTickets;
    mapping(uint256 => Draw) public drawDetails;
    mapping(uint256 => uint256) public requestId;
    mapping(uint256 => uint256) public totalPrizePerRound;
    mapping(address => UserDetais) public userRewards;

    event WinnigNumbersRecived(uint256 roundId, uint256[] numbers);
    event NewTicketBought(
        address _owner,
        uint256 _ticketId,
        uint256[] _ticketNumbers,
        uint256 roundId
    );

    /**
     * @dev Constructor function.
     * Initializes the Lottery contract.
     * Sets the name and symbol of the ERC721 token.
     * Initializes the VRFV2WrapperConsumerBase contract.
     * Sets the buyingToken address and next draw time.
     */
    constructor()
        ERC721("LotteryTicket", "POGEXLT")
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        nextDrawTime = block.timestamp + drawFrequency;
    }

    receive() external payable {}

    /**
     * @dev Allows users to buy a specified number of lottery tickets.
     * @param _numberOfTickets The number of tickets to be bought.
     * Transfers the required token amount from the user to the contract.
     * Generates random numbers, mints new ERC721 tokens, and associates them with the user.
     * Emits the `NewTicketBought` event for each ticket bought.
     */
    function buyTicket(uint256 _numberOfTickets) external payable {
        require(_numberOfTickets > 0, "can not buy 0 tickets");

        uint256 totalFees = ticketPrize * _numberOfTickets;
        require(
            msg.value >= totalFees,
            "Please submit asking price in order to complete the transaction"
        );

        for (uint256 i = 0; i < _numberOfTickets; i++) {
            uint256[] memory numbers = generateRandomNumbers(i);
            uint256 ticketId = _tokenIds.current();

            _mint(msg.sender, ticketId);
            _tickets[ticketId] = LotteryTicket(
                numbers,
                roundId,
                false,
                false,
                0
            );
            _userTickets[msg.sender][roundId].push(ticketId);

            _tokenIds.increment();

            emit NewTicketBought(msg.sender, ticketId, numbers, roundId);
        }
    }

    /**
     * @dev Allows users to buy customized lottery tickets by specifying their own numbers.
     * @param _numbers The 2D array of ticket numbers for each ticket.
     * Allows a maximum of 10 tickets.
     * Validates the ticket numbers and transfers the required token amount from the user to the contract.
     * Mints new ERC721 tokens and associates them with the user.
     * Emits the `NewTicketBought` event for each ticket.
     */
    function buyCustomizedTicket(uint256[][] memory _numbers) external payable {
        require(_numbers.length <= 10, "Exceeded maximum ticket limit");

        uint256 totalTickets = _numbers.length;
        for (uint256 i = 0; i < totalTickets; i++) {
            require(_numbers[i].length == 6, "Invalid ticket numbers");
            require(areNumbersValid(_numbers[i]), "Invalid numbers");
        }

        require(
            msg.value >= (ticketPrize * totalTickets),
            "Please submit asking price in order to complete the transaction"
        );

        for (uint256 i = 0; i < totalTickets; i++) {
            uint256 ticketId = _tokenIds.current();

            _mint(msg.sender, ticketId);
            _tickets[ticketId] = LotteryTicket(
                _numbers[i],
                roundId,
                false,
                false,
                0
            );
            _userTickets[msg.sender][roundId].push(ticketId);

            _tokenIds.increment();

            emit NewTicketBought(msg.sender, ticketId, _numbers[i], roundId);
        }
    }

    /**
     * @dev Allows users to buy tickets using their previously owned ERC721 tokens.
     * @param _ticketIds The array of ERC721 token IDs representing the tickets to be used.
     * Validates the ownership of the tokens by the caller.
     * Transfers the required token amount from the user to the contract.
     * Associates the tickets with the user.
     * Emits the `NewTicketBought` event for each ticket.
     */
    function buyTicketsWithPreviousNumbers(
        uint256[] memory _ticketIds
    ) external payable {
        require(_ticketIds.length <= 20, "Exceeded maximum ticket limit");

        uint256 totalTickets = _ticketIds.length;
        for (uint256 i = 0; i < totalTickets; i++) {
            require(_ticketIds[i] <= _tokenIds.current(), "Invalid ticket ID");
            require(
                ownerOf(_ticketIds[i]) == msg.sender,
                "Not the owner of the ticket"
            );

            uint256[] memory previousNumbers = _tickets[_ticketIds[i]].numbers;
            require(previousNumbers.length == 6, "Invalid ticket numbers");
            require(areNumbersValid(previousNumbers), "Invalid numbers");
        }

        require(
            msg.value >= (ticketPrize * totalTickets),
            "Please submit asking price in order to complete the transaction"
        );

        for (uint256 i = 0; i < totalTickets; i++) {
            uint256 ticketId = _tokenIds.current();

            _mint(msg.sender, ticketId);
            _tickets[ticketId] = LotteryTicket(
                _tickets[_ticketIds[i]].numbers,
                roundId,
                false,
                false,
                0
            );
            _userTickets[msg.sender][roundId].push(ticketId);

            _tokenIds.increment();

            emit NewTicketBought(
                msg.sender,
                ticketId,
                _tickets[_ticketIds[i]].numbers,
                roundId
            );
        }
    }

    function areNumbersValid(
        uint256[] memory _numbers
    ) internal pure returns (bool) {
        require(_numbers.length == 6, "Invalid ticket numbers");
        for (uint256 i = 0; i < _numbers.length; i++) {
            require(
                _numbers[i] >= 0 && _numbers[i] <= 30,
                "Number out of range"
            );
            for (uint256 j = i + 1; j < _numbers.length; j++) {
                require(_numbers[i] != _numbers[j], "Duplicate number");
            }
        }
        return true;
    }

    function generateRandomNumbers(
        uint256 j
    ) private view returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[](NUM_WINNING_NUMBERS);
        uint256 maxNumber = MAX_NUMBERS;

        require(
            maxNumber >= NUM_WINNING_NUMBERS,
            "Range is too small for unique numbers"
        );

        uint256[] memory candidates = new uint256[](maxNumber);
        for (uint256 i = 0; i < maxNumber; i++) {
            candidates[i] = i;
        }

        for (uint256 i = 0; i < NUM_WINNING_NUMBERS; i++) {
            uint256 randomIndex = uint256(
                keccak256(abi.encode(block.timestamp, i, block.difficulty, j))
            ) % maxNumber;

            numbers[i] = candidates[randomIndex];

            // Remove the selected number from the candidates array
            maxNumber--;
            candidates[randomIndex] = candidates[maxNumber];
        }

        return numbers;
    }

    function getTicketNumbers(
        uint256 ticketId
    ) public view returns (uint256[] memory) {
        return _tickets[ticketId].numbers;
    }

    function getUserTickets(
        uint256 _roundId,
        address _user
    ) public view returns (uint256[] memory) {
        return _userTickets[_user][_roundId];
    }

    function draw() external onlyOwner {
        // require(nextDrawTime <= block.timestamp, "Not the time to draw");
        uint256 _requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        requestId[_requestId] = roundId;
        drawDetails[roundId].isDraw = true;

        lastDrawTime = block.timestamp;

        nextDrawTime = block.timestamp + drawFrequency;
        roundId++;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 _roundId = requestId[_requestId];

        require(
            drawDetails[_roundId].isDraw && !drawDetails[_roundId].isFullFilled,
            "Invalid Request"
        );

        require(
            _randomWords.length == NUM_WINNING_NUMBERS,
            "Invalid number of random words"
        );

        uint256[] memory numbers = new uint256[](NUM_WINNING_NUMBERS);
        uint256 maxNumber = MAX_NUMBERS;

        require(
            maxNumber >= NUM_WINNING_NUMBERS,
            "Range is too small for unique numbers"
        );

        uint256[] memory candidates = new uint256[](maxNumber);
        for (uint256 i = 0; i < maxNumber; i++) {
            candidates[i] = i;
        }

        for (uint256 i = 0; i < NUM_WINNING_NUMBERS; i++) {
            uint256 randomIndex = _randomWords[i] % maxNumber;

            numbers[i] = candidates[randomIndex];

            // Remove the selected number from the candidates array
            maxNumber--;
            candidates[randomIndex] = candidates[maxNumber];
        }

        lastDrawNumbers = numbers;
        drawDetails[_roundId].winingNumbers = numbers;
        drawDetails[_roundId].isFullFilled = true;

        emit WinnigNumbersRecived(_roundId, numbers);
    }

    function claimPrize(uint256 _roundId, uint256 _ticketId) public {
        require(
            ownerOf(_ticketId) == msg.sender,
            "Only the ticket owner can claim the prize"
        );
        require(!_tickets[_ticketId].claimed, "Prize already claimed");

        require(drawDetails[_roundId].isClaimeSet, "Claim details not set yet");
        require(_tickets[_ticketId].isWinner, "You are not a winner");

        uint256 winnerAmount = _tickets[_ticketId].winningAmount;

        _burn(_ticketId);
        _tickets[_ticketId].claimed = true;

        unclaimedValues -= winnerAmount;
        if (winnerAmount > 0) payable(msg.sender).transfer(winnerAmount);
    }

    function setWinners(
        uint256[] memory _Winningtickets,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(_Winningtickets.length == _amounts.length, "Array mismatch");

        for (uint256 i = 0; i < _Winningtickets.length; i++) {
            _tickets[_Winningtickets[i]].isWinner = true;
            _tickets[_Winningtickets[i]].winningAmount = _amounts[i];
        }
    }

    function setUserRewards(
        address[] memory _users,
        uint256[] memory _amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            userRewards[_users[i]].totalRewards += _amounts[i];
        }
    }

    function updateTotalClaimeValue(
        uint256 _roundId,
        uint256 _amount
    ) external onlyOwner {
        require(totalPrizePerRound[_roundId] == 0, "Claime value already set");
        require(drawDetails[_roundId].isFullFilled, "Round Not Completed");

        uint256 tokenBalance = address(this).balance;

        tokenBalance -= unclaimedValues;

        totalPrizePerRound[_roundId] = _amount;

        unclaimedValues += _amount;

        drawDetails[_roundId].isClaimeSet = true;

        uint256 _marketingFee = (tokenBalance * marketingFee) / 100;

        payable(marketingAddress).transfer(_marketingFee);
    }

    function withdrawLink() external onlyOwner {
        IERC20(linkAddress).transfer(
            msg.sender,
            IERC20(linkAddress).balanceOf(address(this))
        );
    }

    function getDrawNumbers(
        uint256 _drawNumber
    ) public view returns (uint256[] memory) {
        return drawDetails[_drawNumber].winingNumbers;
    }

    function withdrawBep20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function changeFeePercentages(uint256 _marketingFee) external onlyOwner {
        marketingFee = _marketingFee;
    }

    function changeFeeAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function changeTicketPrice(uint256 _price) external onlyOwner {
        ticketPrize = _price;
    }

    function changeDrawFrquency(uint256 _frequency) external onlyOwner {
        drawFrequency = _frequency;
    }

    function changeWrapperAddress(address _wrapper) external onlyOwner {
        wrapperAddress = _wrapper;
    }
}
