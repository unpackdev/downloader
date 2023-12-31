// SPDX-License-Identifier: MIT
// An example of a consumer contract that directly pays for each request.
pragma solidity ^0.8.7;

import "./ConfirmedOwner.sol";
import "./VRFV2WrapperConsumerBase.sol";

contract Lottery is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );
    event PurchaseTicket(
        address purchaser,
        uint8 amount,
        uint256 priceOfTickets
    );
    event Deposit(address sender, uint256 amount);
    event LotteryConduct(address winner, uint256 prize);
    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    // List of addreses with amount of tickets
    uint256 public currentRound;

    struct LotteryData {
        mapping(address => uint8) Tickets;
        address[] players;
        uint256 ticketsSold;
        uint256 winningAmount;
        uint256 lotteryEndTime;
        address winner;
    }
    //Make an array of lotteries
    LotteryData[] public _Lottery;

    uint8 MAX_TICKET_LIMIT = 10; //the maximum tickets one user can purchase
    uint256 MAX_RANDOM_NUMBER = 100;
    uint256 public ticketPrice;

    uint256 public randomNumber = 0;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit = 300000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    uint32 numWords = 2;

    // Address LINK
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // address WRAPPER
    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;
    address public treasury;

    constructor(address _treasury)
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        ticketPrice = 25000000000000000; //ticket price in ethers
        currentRound = 0; //The first round
        treasury = _treasury; //the treasury wallet
        _Lottery.push();
        _Lottery[currentRound].lotteryEndTime = block.timestamp + 7 days;
    }

    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](1),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        LotteryData storage _currentLottery = _Lottery[currentRound];
        require(s_requests[_requestId].paid > 0, "request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        //random Number for the player index
        randomNumber = _randomWords[0] % _currentLottery.ticketsSold;
        //random Number for the lottery conduct chances
        uint256 LotteryConductChances = _randomWords[1] % MAX_RANDOM_NUMBER;
        if (LotteryConductChances < 5) {
            //if the lottery conduct chances are less then 5% dont conduct
            NextRound();
            emit RequestFulfilled(
                _requestId,
                _randomWords,
                s_requests[_requestId].paid
            );
        } else {
            //conduct the lottery
            _currentLottery.winner = _currentLottery.players[randomNumber];
            uint256 prizeAmount = address(this).balance;
            uint256 treasuryAmount = (prizeAmount * 5) / 100; //calculating 5% of the total pool amount
            _currentLottery.winningAmount = prizeAmount - treasuryAmount;
            payable(_currentLottery.winner).transfer(
                prizeAmount - treasuryAmount
            );
            payable(treasury).transfer(treasuryAmount);
            emit RequestFulfilled(
                _requestId,
                _randomWords,
                s_requests[_requestId].paid
            );
            NextRound();
            emit LotteryConduct(_currentLottery.winner, prizeAmount);
        }
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function UpdateTicketPrice(uint256 _price) external onlyOwner {
        ticketPrice = _price;
    }

    function NextRound() internal {
        //Move to the next round
        currentRound += 1;
        _Lottery.push();
        _Lottery[currentRound].lotteryEndTime = block.timestamp + 7 days;
    }

    //should autamaticallly calculate the amouunct of ethers
    function PurchaseTickets(uint8 amountOfTickets) external payable {
        LotteryData storage _currentLottery = _Lottery[currentRound];
        require(
            _currentLottery.lotteryEndTime >= block.timestamp,
            "The lottery duration has expired!"
        );
        uint8 UserTicketsPurchased = _currentLottery.Tickets[msg.sender];
        //check and see if the user wants to purchase more then 10 tokens
        require(
            (amountOfTickets + UserTicketsPurchased) <= MAX_TICKET_LIMIT,
            "Cannot purchase more then 10 Tickets"
        );
        uint256 priceOfTickets = amountOfTickets * ticketPrice;
        require(
            address(msg.sender).balance >= priceOfTickets,
            "The user doesnt have enough ETH to purchase the tickets"
        );
        require(
            msg.value >= priceOfTickets,
            "The user has not provided enough ETH"
        );

        (bool sent, ) = address(this).call{value: priceOfTickets}("");
        require(sent, "Unable to transfer");
        _currentLottery.Tickets[msg.sender] += amountOfTickets;
        _currentLottery.ticketsSold += amountOfTickets;
        for (uint256 i = 0; i < amountOfTickets; i++) {
            _currentLottery.players.push(msg.sender);
        }
        emit PurchaseTicket(msg.sender, amountOfTickets, ticketPrice);
    }

    function ConductLottery() external onlyOwner {
        LotteryData storage _currentLottery = _Lottery[currentRound];
        require(
            _currentLottery.winner == address(0),
            "Winner already selected"
        );
        //genrate a random number between 0-99
        requestRandomWords();
    }

    function DespositETH() external payable onlyOwner {
        //The owner can deposit some ethers to the smart contract but cannot withdraw them
        uint256 amount = msg.value;
        require(amount > 0, "No amount to deposit");
        (
            bool sent, /*bytes memory data*/

        ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Unable to transfer the ethers");
        emit Deposit(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getParticipants() external view returns (address[] memory) {
        LotteryData storage _currentLottery = _Lottery[currentRound];
        return _currentLottery.players;
    }

    function getTicketsPurchased(address _user, uint256 _index)
        external
        view
        returns (uint8)
    {
        LotteryData storage _IndexLottery = _Lottery[_index];
        return _IndexLottery.Tickets[_user];
    }

    receive() external payable {
        //to receive the ETH
    }
}
