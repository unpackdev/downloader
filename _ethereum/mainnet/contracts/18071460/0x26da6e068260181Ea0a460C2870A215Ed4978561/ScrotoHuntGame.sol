// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

contract ScrotoHuntGame {
    address public owner;
    address public tokenAddress;
    uint256 public winningChance;
    uint256 public betAmount;
    uint256 public housePercentage; // Percentage of the bet amount that goes to the house

    event GameResult(
        address indexed player,
        uint256 indexed betAmount,
        bool indexed win,
        uint256 userId
    );

    constructor(
        address _tokenAddress,
        uint256 _winningChance,
        uint256 _betAmount,
        uint256 _housePercentage
    ) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        winningChance = _winningChance;
        betAmount = _betAmount;
        housePercentage = _housePercentage;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    function playGame(uint256 userId) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance >= betAmount, "Insufficient token balance");

        uint256 houseAmount = (betAmount * housePercentage) / 100;

        require(
            token.transferFrom(msg.sender, address(this), betAmount),
            "Token transfer failed"
        );

        uint256 randomNumber = generateRandomNumber();

        bool win = randomNumber < winningChance;
        uint256 playerAmount = win ? betAmount * 2 - houseAmount : 0;

        if (win) {
            require(
                token.transfer(msg.sender, playerAmount),
                "Token transfer to player failed"
            );
        }

        emit GameResult(msg.sender, betAmount, win, userId);
    }

    function generateRandomNumber() internal view returns (uint256) {
        uint256 dummy = 0; // Adding a dummy variable
        dummy = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    dummy
                )
            )
        );
        return dummy % 100;
    }

    function setBetAmount(uint256 _betAmount) external onlyOwner {
        betAmount = _betAmount;
    }

    function setWinningChance(uint256 _winningChance) external onlyOwner {
        winningChance = _winningChance;
    }

    function withdrawTokens(address _teamWallet) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, "No tokens to withdraw");

        require(
            token.transfer(_teamWallet, contractBalance),
            "Token transfer to team wallet failed"
        );
    }

    function setHousePercentage(uint256 _housePercentage) external onlyOwner {
        housePercentage = _housePercentage;
    }
}
