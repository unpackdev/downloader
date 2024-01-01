// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract TicketLottery is ReentrancyGuard {
    address public owner;
    address[] public players;
    address public winner;
    uint public poolAmount;
    uint public queueSize = 10;
    uint256 public entryAmount = 0.01 ether;

    uint public totalLotteries;
    uint public totalWinnings;
    uint public totalHouseFees;
    address public houseFeeReciever = address(0xfB1b1C0eeDDB71bc46cD7A860B7A74F63119A2f8);
    uint public houseFeePercent = 10;
    

    constructor() {
        owner = msg.sender;
    }

    event LotteryConcluded(
        address[] players,
        address winner,
        uint256 prize,
        uint256 outcome
    );

    event LotteryStarted(address indexed starter, uint256 entryAmount, uint256 queueSize);

    function enterLottery() public payable nonReentrant {
        require(msg.value == entryAmount, "You must send the correct amount to enter");
        require(players.length < queueSize, "Queue is full, wait for the next round.");


    // Check if the lottery is starting (i.e., no players yet for this round)
        bool isNewRoundStarting = players.length == 0;

        players.push(msg.sender);
        poolAmount += msg.value;

    // Emit the LotteryStarted event if this is the start of a new round
        if (isNewRoundStarting) {
            emit LotteryStarted(msg.sender, entryAmount, queueSize);
        }

        if (players.length == queueSize) {
            selectWinner();
        }
    }

    function selectWinner() internal {
        uint randNumber = rand();
        uint index = randNumber % players.length;
        winner = players[index];

        uint houseFee = (poolAmount * houseFeePercent) / 100;
        uint winnings = poolAmount - houseFee;

        payable(winner).transfer(winnings);
        payable(houseFeeReciever).transfer(houseFee);

        totalWinnings += winnings;
        totalHouseFees += houseFee;
        totalLotteries++;

        emit LotteryConcluded(players, winner, winnings, index);

        reset();
    }

    function reset() private {
        delete players;
        poolAmount = 0;
        winner = address(0);
    }


    // This function is just a placeholder for generating a random number.
    function rand() private view returns (uint256) {

        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.prevrandao +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return seed;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Allow the owner to withdraw any excess funds (if any).
    function withdrawExcess() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function setHouseFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0), "New receiver cannot be the zero address");
        houseFeeReciever = newReceiver;
    }


    function setHouseFeePercent(uint8 newPercent) external onlyOwner {
        require(newPercent != houseFeePercent, "This is already the house fee percent");
        require(newPercent <= 10, "Cannot set house fee percentage higher than 10 percent");

        houseFeePercent = newPercent;
    }

    function setQueueSize(uint8 newSize) external onlyOwner {
        require(newSize != queueSize, "This is already the queue size!");
        require(newSize > 0, "Cannot set queue size to 0!");

        queueSize = newSize;
    }

    function setEntryAmount(uint256 newAmount) external onlyOwner {
        require(newAmount != entryAmount, "This is already the entry amount!");
        require(newAmount > 0, "Cannot set entry amount to 0!");


        entryAmount = newAmount;
    }

    receive() external payable {
        require(msg.value == entryAmount, "You must send the correct amount to enter");
        enterLottery();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
}