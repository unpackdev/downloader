// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";

struct BetTypeWin {
    uint betTypeId;
    bool choice;
}

struct Bet {
    address participant;
    uint256 amount;
    uint betTypeId;
    uint blockNum;
    bool choice;
}

contract BetBox{
    BettingContract[] public bets;
    address payable private owner;

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function createBet (
        string memory _title,
        string memory _description,
        string[] calldata types
    ) public onlyOwner {
        BettingContract newBet = new BettingContract(payable(msg.sender), payable(msg.sender), _title, _description, types);
        bets.push(newBet);
    }

    function createBetForUsers (
        string memory _title,
        string memory _description,
        string[] calldata types
    ) public {
        BettingContract newBet = new BettingContract(owner, payable(msg.sender), _title, _description, types);
        bets.push(newBet);
    }

    function returnAllBets() public view returns(BettingContract[] memory){
        return bets;
    }
}

contract BettingContract {
    using SafeMath for uint256;

    address public owner;
    address public creator;
    string public title;
    string public description;

    uint numerator = 990000000000;
    uint denominator = 1000000000000;

    enum State { Default, Running, Stopped, Finalized }
    State public betState = State.Default;

    Bet[] public bets;
    string [] public betTypes;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier bettingActive() {
        require(betState == State.Running);
        _;
    }

    constructor(
        address payable _owner,
        address payable _creator,
        string memory _title,
        string memory _description,
        string[] memory types
    ) {
        owner = _owner;
        creator = _creator;
        title = _title;
        description = _description;

        for (uint256 i = 0; i < types.length; i++) {
            betTypes.push(types[i]);
        }

        if (_owner == _creator) {
            betState = State.Running;
        }
    }

    function getBets() external view returns (Bet[] memory) {
        return bets;
    }

    function getBetTypes() external view returns (string[] memory) {
        return betTypes;
    }

    function placeBet(uint betTypeId, bool choice) external payable bettingActive {
        require(msg.value > 0);
        require(choice == true || choice == false);
        require(betTypeId < betTypes.length);

        Bet memory newBet = Bet({
            participant: msg.sender,
            amount: msg.value,
            choice: choice,
            betTypeId: betTypeId,
            blockNum: block.number
        });

        bets.push(newBet);
    }

    function stopBet() external onlyOwner {
        require(betState == State.Running, "Betting has already been stopped");
        betState = State.Stopped;
    }

    function startBet() external onlyOwner {
        require(betState == State.Default);
        betState = State.Running;
    }

    function distributeWinningPool(BetTypeWin[] calldata betsWin) external onlyOwner {
        require(betState == State.Stopped);

        for (uint256 b = 0; b < betsWin.length; b++) {
            uint256 totalPool = 0;
            uint256 winningPool = 0;
            for (uint256 i = 0; i < bets.length; i++) {
                if (bets[i].betTypeId == betsWin[b].betTypeId) {
                    totalPool += bets[i].amount;
                    if (bets[i].choice == betsWin[b].choice) {
                        winningPool += bets[i].amount;
                    }
                }
            }

            if (winningPool > 0) {
                for (uint256 i = 0; i < bets.length; i++) {
                    if (bets[i].amount > 0 && bets[i].choice == betsWin[b].choice && bets[i].betTypeId == betsWin[b].betTypeId) {
                        uint256 participantShare = bets[i].amount
                            .mul(numerator)
                            .mul(totalPool)
                            .div(winningPool)
                            .div(denominator);

                        (bool success, ) = payable(bets[i].participant).call{value: participantShare}("");
                        require(success, "Transfer failed");
                    }
                }
            }
        }
        if (owner != creator) {
            payable(creator).call{value:  address (this).balance.mul(400).div(1000) }("");
        }
        payable(owner).transfer(address (this).balance);
        betState = State.Finalized;
    }

    function refundBets(BetTypeWin[] calldata betsWin) external onlyOwner {
        for (uint256 b = 0; b < betsWin.length; b++) {
            for (uint256 i = 0; i < bets.length; i++) {
                if (bets[i].betTypeId == betsWin[b].betTypeId) {
                    (bool success, ) = payable(bets[i].participant).call{value: bets[i].amount}("");
                }
            }
        }
    }

    function refundLateBets(uint blockNum) external onlyOwner {
        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].blockNum > blockNum) {
                (bool success, ) = payable(bets[i].participant).call{value: bets[i].amount}("");
                if (success) {
                    bets[i].amount = 0;
                }
            }
        }
    }

    function emergencyReturn(address payable owner) public onlyOwner {
        owner.transfer(address(this).balance);
    }
}