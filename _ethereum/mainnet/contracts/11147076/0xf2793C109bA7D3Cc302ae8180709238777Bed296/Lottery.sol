pragma solidity ^0.5.10;

contract Lottery {
    address payable manager = 0x15682BD0eb3f8B8922428C3Ca61E5E912fD658C5;
    address payable public winner;
    uint public winningsLimit = 1000000000000000000;
    uint public playerLimit = 55.0;
    address payable[] public players;

    
    // restrict to only the manager (the contract creator)
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor() public restricted {
        manager = msg.sender;
        // function params uint _winningsLimit, uint _playerLimit
        // winningsLimit = _winningsLimit;
        // playerLimit = _playerLimit;
    }

    function enter() public payable  {
        require(msg.value > .019999 ether, "not enough");
        players.push(msg.sender);
        if (address(this).balance > winningsLimit || players.length > playerLimit) {
          pickWinner();
        }
    }

    function kindaRandom() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }

    function pickWinner() public restricted {
        uint index = kindaRandom() % players.length;
        
        // set winner
        winner = players[index];

        // pay 
        uint totalPayout = address(this).balance;
        
        // Take 10% for the manager (rounded down by int-division)
        uint managerFee = totalPayout / 10;
        // Pay the rest to the winner
        uint payoutToWinner = totalPayout - managerFee;
        
        winner.transfer(payoutToWinner);
        manager.transfer(managerFee);

        // clear players and start over.
        winner = address(0);
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getPot() public view returns (uint) {
        return address(this).balance;
    }

}