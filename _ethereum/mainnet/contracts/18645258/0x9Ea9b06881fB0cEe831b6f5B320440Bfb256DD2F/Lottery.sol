// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// lottery contract
contract Lottery {
    // manager address
    address public manager;
    // lottery players
    address[] public players;
    // lottery winners
    address[] public winners;

    // target amount of tickets
    uint public target_amount;
    // price of ticket in USDT
    uint public ticket_price;
    // check if game finished
    bool public isGameEnded = true;
    bool public isReadyPickWinner = false;
    uint public startedTime = 0;
    uint public endTime = 0;

    // remaining USDT in the contract
    uint public remainingUSDT = 0;
    // ERC-20 token address
    IERC20 usdtToken;
    // Lottery information
    struct LotteryInfo {
        uint index;
        uint startTime;
        uint endTime;
        address[] winners;
        address[] entries;
        uint ticketPrice;
        uint ticketAmount;
    }

    // List of lotteries
    LotteryInfo[] public lotteries;

    // add event
    event PickWinner(address[] winners, uint prizeAmount);

    // Transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // constructor
    constructor(address _usdtTokenAddress) {
        // define administrator with deployer
        manager = msg.sender;
        isGameEnded = true;
        usdtToken = IERC20(_usdtTokenAddress);

    }

    // role middleware
    modifier restricted() {
        require(msg.sender == manager, "only manager has access");
        _;
    }

    // middleware to check if game is on or off
    modifier onGame() {
        require(!isGameEnded && !isReadyPickWinner, "Game has not started yet.");
        _;
    }

    // Get Balance of pool
    function balanceInPool() public view returns (uint) {
        return usdtToken.balanceOf(address(this));
    }

    // enter the game
    function enter(uint256 _usdtAmount) public onGame returns (bool){        
        require(target_amount > 0, "The whole tickets have been sold");
        require(_usdtAmount == ticket_price, "USDT amount doesn't match the price of the ticket");
        require(_usdtAmount <= usdtToken.balanceOf(msg.sender), "Insufficient USDT Amount in wallet");
        // Check if the sender has approved the contract to spend their USDT
        require(usdtToken.allowance(msg.sender, address(this)) >= ticket_price, "Not enough allowance");
        // Transfer USDT from the sender to the contract
        bool ok = usdtToken.transferFrom(msg.sender, address(this), _usdtAmount);
        if (ok) {
            emit Transfer(msg.sender, address(this), _usdtAmount);
            // Add the sender to the list of players
            players.push(msg.sender);
            // Decrement the target_amount
            target_amount = target_amount - 1;
            lotteries[lotteries.length - 1].entries.push(msg.sender);

            // Check if all tickets are sold
            if (target_amount == 0) {
                isReadyPickWinner = true;
                endTime = block.timestamp;
            }
            return true;
        }
        return false;

    }

    // initialize the game
    function initialize(
        uint _ticketPrice,
        uint _ticketAmount       
    ) public restricted {
        // before init newly, the previous game should be finished.
        require(isGameEnded, "Game is running now.");
        startedTime = block.timestamp;
        ticket_price = _ticketPrice;
        target_amount = _ticketAmount;        
        isGameEnded = false;
        isReadyPickWinner = false;
        remainingUSDT = 0;
        if (winners.length > 0){
            delete winners;
        }
        if (players.length >0 ){
            delete players;
        }
        // Create a new lottery entry
        lotteries.push(LotteryInfo({
            index: lotteries.length,
            startTime: startedTime,
            endTime: 0,
            winners: winners,
            entries: players,
            ticketPrice: _ticketPrice,
            ticketAmount: _ticketAmount
        }));
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, players)));
    }

     function pickWinner() public restricted {
        require(isReadyPickWinner, "Game is running now.");

        uint totalPlayers = players.length;

        require(totalPlayers >= 3, "Not enough players to pick 3 winners");

        // Shuffle the players array
        address[] memory entries = new address[](players.length);
        for (uint i = totalPlayers - 1; i > 0; i--) {
            uint j = random() % (i + 1);
            (entries[i], entries[j]) = (players[j], players[i]);
        }

        // Calculate total USDT collected
        uint totalUSDT = ticket_price * players.length;

        // Select the first 3 players as winners
        address[] memory selectedWinners = new address[](3);
        for (uint i = 0; i < 3; i++) {
            selectedWinners[i] = entries[i];
        }

        // Distribute prizes to winners based on total USDT
        uint prizeAmount = (totalUSDT * 30) / 100;
        for (uint i = 0; i < 3; i++) {
            usdtToken.transfer(selectedWinners[i], prizeAmount);
        }
        // 10% remains in the contract and only the manager can withdraw
        remainingUSDT = (totalUSDT * 10) / 100;

        // Save lottery information
        lotteries[lotteries.length - 1].winners = selectedWinners;
        lotteries[lotteries.length - 1].endTime = block.timestamp;
        winners = selectedWinners;
        // Reset game state
        isGameEnded = true;
        isReadyPickWinner = false;

        emit PickWinner(selectedWinners, prizeAmount);
    }




    // Manager can withdraw USDT
    function withdrawUSDT(uint _usdtAmount) public restricted {
        require(_usdtAmount <= usdtToken.balanceOf(address(this)), "No such amount in contract");
        usdtToken.transfer(manager, _usdtAmount);
    }

    // Manager can withdraw all USDT
    function withdrawAllUSDT() public restricted {
        uint amountToWithdraw = usdtToken.balanceOf(address(this));
        require(amountToWithdraw > 0, "No USDT to withdraw");        
        usdtToken.transfer(manager, amountToWithdraw);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getWinners() public view returns (address[] memory) {
        return winners;
    }

    function getPlayerNumber() public view returns (uint) {
        return players.length;
    }

    function getStartedTime() public view returns (uint) {
        return block.timestamp - startedTime;
    }

    function getEndTime() public view returns (uint) {
        return endTime;
    }    

    function getLotteriesCount() public view returns (uint) {
        return lotteries.length;
    }

    function getLotteryInfo(uint index) public view returns (LotteryInfo memory) {
        require(index < lotteries.length, "Invalid lottery index");
        return lotteries[index];
    }

    function changeManger(address _newManager) public restricted {
        manager = _newManager;
    }
}