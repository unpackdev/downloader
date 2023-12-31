// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the main contract with the functions we want to call
interface IMainContract {
    function declareWinner(int64 _telegramId, uint256 _gameId, address[] calldata _winners) external;
    function releaseLockedFunds(uint256 _gameId) external;
    function startGame(int64 _telegramId, uint256 _gameId, address[] calldata _players, uint256[] calldata _bets, uint256 _totalBet) external;
    function getInfo() external view returns (address[] memory, string[] memory, uint256[] memory);
}


contract SecondaryContract {
    IMainContract public mainContract; // State variable to store the address of the main contract
    address public owner; // Owner of the secondary contract

    // Modifier to restrict access only to the owner of the secondary contract
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Constructor to initialize the address of the main contract and the owner of the secondary contract
    constructor(address _mainContract) {
        mainContract = IMainContract(_mainContract);
        owner = msg.sender;
    }

    // Functions that invoke the corresponding ones in the main contract
    function fetchInfo() public view onlyOwner returns (address[] memory, string[] memory, uint256[] memory) {
        return mainContract.getInfo();
    }
    function declareWinner(int64 _telegramId, uint256 _gameId, address[] calldata _winners) public onlyOwner {
        mainContract.declareWinner(_telegramId, _gameId, _winners);
    }

    function releaseLockedFunds(uint256 _gameId) public onlyOwner {
        mainContract.releaseLockedFunds(_gameId);
    }

    function startGame(int64 _telegramId, uint256 _gameId, address[] calldata _players, uint256[] calldata _bets, uint256 _totalBet) public onlyOwner {
        mainContract.startGame(_telegramId, _gameId, _players, _bets, _totalBet);
    }

    // Function to update the address of the main contract, if necessary
    function setMainContract(address _mainContract) public onlyOwner {
        mainContract = IMainContract(_mainContract);
    }
}