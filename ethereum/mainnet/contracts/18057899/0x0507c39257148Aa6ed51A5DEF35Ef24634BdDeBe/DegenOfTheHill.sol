// SPDX-License-Identifier: MIT

/*
 $$$$$$\   $$$$$$\        $$$$$$$\  $$$$$$$$\  $$$$$$\  $$$$$$$$\ $$\   $$\        $$$$$$\  $$$$$$$$\       $$$$$$$$\ $$\   $$\ $$$$$$$$\       $$\   $$\ $$$$$$\ $$\       $$\       
$$  __$$\ $$  __$$\       $$  __$$\ $$  _____|$$  __$$\ $$  _____|$$$\  $$ |      $$  __$$\ $$  _____|      \__$$  __|$$ |  $$ |$$  _____|      $$ |  $$ |\_$$  _|$$ |      $$ |      
$$ /  $$ |$$ /  \__|      $$ |  $$ |$$ |      $$ /  \__|$$ |      $$$$\ $$ |      $$ /  $$ |$$ |               $$ |   $$ |  $$ |$$ |            $$ |  $$ |  $$ |  $$ |      $$ |      
$$ |  $$ |$$ |$$$$\       $$ |  $$ |$$$$$\    $$ |$$$$\ $$$$$\    $$ $$\$$ |      $$ |  $$ |$$$$$\             $$ |   $$$$$$$$ |$$$$$\          $$$$$$$$ |  $$ |  $$ |      $$ |      
$$ |  $$ |$$ |\_$$ |      $$ |  $$ |$$  __|   $$ |\_$$ |$$  __|   $$ \$$$$ |      $$ |  $$ |$$  __|            $$ |   $$  __$$ |$$  __|         $$  __$$ |  $$ |  $$ |      $$ |      
$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |      $$ |  $$ |$$ |      $$ |\$$$ |      $$ |  $$ |$$ |               $$ |   $$ |  $$ |$$ |            $$ |  $$ |  $$ |  $$ |      $$ |      
 $$$$$$  |\$$$$$$  |      $$$$$$$  |$$$$$$$$\ \$$$$$$  |$$$$$$$$\ $$ | \$$ |       $$$$$$  |$$ |               $$ |   $$ |  $$ |$$$$$$$$\       $$ |  $$ |$$$$$$\ $$$$$$$$\ $$$$$$$$\ 
 \______/  \______/       \_______/ \________| \______/ \________|\__|  \__|       \______/ \__|               \__|   \__|  \__|\________|      \__|  \__|\______|\________|\________|
                                                                                                                                                                                      */                                                                                                                                                                                   

/* The Original King of the Hill dApp by DapperLad.
More Fun dApps and experiences at: https://dapperlad.xyz */

pragma solidity >=0.8.0;

contract DegenOfTheHill {
    address payable public kingOfTheHill;
    uint256 public totalBalance;
    uint256 public endTime;
    uint256 public roundNumber;
    uint256 public constant COUNTDOWN_TIME = 10 minutes;
    uint256 public TICKET_PRICE = 0.01 ether;
    address payable public owner;
    bool public isTimerActive;

    mapping(address => bool) private participants;
    uint256 public participantsCount;

    event Bought(address indexed buyer, uint256 amount);
    event Distributed(uint256 kingPrize, uint256 ownerPrize);
    event TimerStarted();
    event TimerEnded();
    event Swept(uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        roundNumber = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function startTimer() public onlyOwner {
        require(!isTimerActive, "Timer is already started.");
        isTimerActive = true;
        endTime = block.timestamp + COUNTDOWN_TIME;
        emit TimerStarted();
    }

    function endTimer() public onlyOwner {
        isTimerActive = false;
        emit TimerEnded();
    }

    function setTicketPrice(uint256 _newPrice) public onlyOwner {
        TICKET_PRICE = _newPrice;
    }

    function buy() public payable {
        require(isTimerActive, "The timer has not started.");
        require(block.timestamp <= endTime, "Timer has ended.");
        require(msg.value == TICKET_PRICE, "Incorrect amount sent.");

        if (!participants[msg.sender]) {
            participants[msg.sender] = true;
            participantsCount++;
        }

        kingOfTheHill = payable(msg.sender);
        totalBalance += msg.value;
        endTime = block.timestamp + COUNTDOWN_TIME;

        emit Bought(msg.sender, msg.value);
    }

    function distribute() public onlyOwner {
        require(!isTimerActive || getRemainingTime() == 0, "Timer has not ended or is still active.");

        uint256 kingPrize = (totalBalance * 70) / 100;
        uint256 ownerPrize = totalBalance - kingPrize;
        kingOfTheHill.transfer(kingPrize);
        owner.transfer(ownerPrize);

        emit Distributed(kingPrize, ownerPrize);

        reinitialize();
    }

    function sweep() public onlyOwner { // to use as an emergency if distribute() doesn't work
        uint256 amount = totalBalance;
        owner.transfer(amount);
        emit Swept(amount);

        reinitialize();
    }

    function getRemainingTime() public view returns (uint256) {
        if (block.timestamp > endTime || !isTimerActive) {
            return 0;
        } else {
            return endTime - block.timestamp;
        }
    }

    function reinitialize() internal {
        kingOfTheHill = payable(address(0));
        totalBalance = 0;
        endTime = 0;
        isTimerActive = false;
        roundNumber++;
    }
}