// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
    The Minority Games - Game Contract
    A game that the minority wins.
 
    Telegram: https://t.me/theminoritygames
    Game Bot: https://t.me/the_minority_game_bot
    Twitter: https://twitter.com/ethminoritygame
    
**/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";

contract TheMinorityGames is Ownable, ReentrancyGuard {
    enum VOTE {YES, NO}
    enum GAMESTATUS {NONE, START, VOTE, REVEAL, CLAIM}
    struct Status { 
        GAMESTATUS status;
        uint activeBlock;
    }
    struct PlayerStatus {
        uint round;
        GAMESTATUS status;
        bytes32 encrVote;
        uint voteCost;
        VOTE voteRevealed;
        uint winCount;
    }

    // Game Info
    IERC20 public gameChip;
    uint public currentRound;
    Status public currentStatus;
    string public currentTopic;
    uint public currentTopicBid;
    uint public voteYesCount;
    uint public voteNoCount;
    uint public voteCount;
    uint public yesPool;
    uint public noPool;
    uint public totalPool;
    address public currentGamePrizePool;
    address public teamWallet;
    // Player Info
    mapping(address => PlayerStatus) public playerStatus;

    // Prepare Game
    function setGameChipAddress(address addr) external onlyOwner {
        gameChip = IERC20(addr);
    }

    // Start Game
    function newRound(uint round, string memory topic, uint blockNum) external onlyOwner {
        currentRound = round;
        currentTopic = topic;
        currentTopicBid = 0;
        currentStatus = Status(GAMESTATUS.START, blockNum);
        voteCount = 0;
        voteYesCount = 0;
        voteNoCount = 0;
        yesPool = 0;
        noPool = 0;
        totalPool = 0;
    }

    function distributeTokenPrize() external onlyOwner {
        uint tokenBalance = gameChip.balanceOf(address(this));
        if (tokenBalance == 0) {
            return;
        }
        gameChip.transfer(address(gameChip), tokenBalance);
    }

    function distributeEthPrize() external onlyOwner {
        uint ethBalance = address(this).balance;
        if (address(this).balance == 0) {
            return;
        }
        payable(currentGamePrizePool).transfer(ethBalance * 8 / 10);
        payable(teamWallet).transfer(ethBalance * 2 / 10);
    }

    function withdrawStuckToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function changeTopic(string memory newTopic) external payable {
        require(currentStatus.status == GAMESTATUS.START, "Game: Invalid game status (require start).");
        require(currentStatus.activeBlock > block.number, "Game: Start phase ended");
        if (msg.sender != owner()) {
            require(msg.value >= 2 * currentTopicBid && msg.value >= 0.1 ether, "Game: Require more ethers to change the topic.");
        }
        currentTopic = newTopic;
        currentTopicBid = msg.value;
    }

    function updateGameStatus(GAMESTATUS status, uint blockNum) external onlyOwner {
        currentStatus = Status(status, blockNum);
    }

    function setPrizePool(address current, address team) external onlyOwner {
        currentGamePrizePool = current;
        teamWallet = team;
    }

    function vote(bytes32 encrVote) external nonReentrant {
        require (currentStatus.status == GAMESTATUS.VOTE, "Game: Invalid game status (require vote)");
        require (currentStatus.activeBlock > block.number, "Game: Vote ended");
        if (playerStatus[msg.sender].status == GAMESTATUS.VOTE && playerStatus[msg.sender].round == currentRound) {
            revert("Game: Player has voted this round.");
        }
        uint lostCount = currentRound - playerStatus[msg.sender].winCount;
        uint voteCost = lostCount * lostCount * 100 * 1e18;
        require (gameChip.balanceOf(msg.sender) >= voteCost, string(abi.encodePacked("Game: Vote costs " , Strings.toString(voteCost / 1e18), " Chips")));
        playerStatus[msg.sender].round = currentRound;
        playerStatus[msg.sender].status = GAMESTATUS.VOTE;
        playerStatus[msg.sender].encrVote = encrVote;
        playerStatus[msg.sender].voteCost = voteCost;
        gameChip.transferFrom(msg.sender, address(this), voteCost);
        totalPool += voteCost;
        voteCount ++;
    }

    function reveal(string memory pass, uint playerVote) external nonReentrant {
        require (currentStatus.status == GAMESTATUS.REVEAL, "Game: Invalid game status (require reveal)");
        require (currentStatus.activeBlock > block.number, "Game: Reveal ended");
        // The player need to vote this round
        require (playerStatus[msg.sender].round == currentRound, "Game: You didn't vote this round.");
        require (playerStatus[msg.sender].status == GAMESTATUS.VOTE, "Game: Invalid player status (require vote)");
        string memory voteString;
        if (playerVote == 0) {
            voteString = "0";
        } else if (playerVote == 1) {
            voteString = "1";
        } else {
            revert("Game: Invalid vote.");
        }
        require (playerStatus[msg.sender].encrVote == keccak256(abi.encodePacked(pass, voteString)), "Game: Incorrect password or vote data.");
        // Result
        if (playerVote == 0) {
            voteYesCount ++;
            playerStatus[msg.sender].status = GAMESTATUS.REVEAL;
            playerStatus[msg.sender].voteRevealed = VOTE.YES;
            yesPool += playerStatus[msg.sender].voteCost;
        } else if (playerVote == 1) {
            voteNoCount ++;
            playerStatus[msg.sender].status = GAMESTATUS.REVEAL;
            playerStatus[msg.sender].voteRevealed = VOTE.NO;
            noPool += playerStatus[msg.sender].voteCost;
        } else {
            revert("Game: Incorrect vote input.");
        }
    }

    function claim() external nonReentrant {
        require (currentStatus.status == GAMESTATUS.CLAIM, "Game: Invalid game status (require claim)");
        require (currentStatus.activeBlock > block.number, "Game: Claim ended");
        // The player need to vote before
        require (playerStatus[msg.sender].round == currentRound, "Game: You didn't vote this round.");
        if (playerStatus[msg.sender].status == GAMESTATUS.CLAIM) {
            revert("Game: You've already claimed your chips.");
        }
        if (playerStatus[msg.sender].status == GAMESTATUS.VOTE) {
            revert("Game: You didn't reveal this round.");
        }
        require (playerStatus[msg.sender].status == GAMESTATUS.REVEAL, "Game: Invalid Player Status (require reveal)");

        uint claimAmount = 0;
        if (voteYesCount == voteNoCount) {
            // DRAW return vote cost
            claimAmount = playerStatus[msg.sender].voteCost;
            gameChip.transferFrom(address(this), msg.sender, claimAmount);
        } else if (voteYesCount < voteNoCount && playerStatus[msg.sender].voteRevealed == VOTE.YES) {
            // vote YES and win
            playerStatus[msg.sender].winCount++;
            claimAmount = playerStatus[msg.sender].voteCost + (totalPool - yesPool) * playerStatus[msg.sender].voteCost / yesPool * 6 / 10;
            gameChip.transferFrom(address(this), msg.sender, claimAmount);
        } else if (voteYesCount > voteNoCount && playerStatus[msg.sender].voteRevealed == VOTE.NO) {
            // vote NO and win
            playerStatus[msg.sender].winCount++;
            claimAmount = playerStatus[msg.sender].voteCost + (totalPool - noPool) * playerStatus[msg.sender].voteCost / noPool * 6 / 10;
            gameChip.transferFrom(address(this), msg.sender, claimAmount);
        } else {
            // Lose, return 20% cost
            claimAmount = playerStatus[msg.sender].voteCost * 2 / 10;
            gameChip.transferFrom(address(this), msg.sender, claimAmount);
        }
        playerStatus[msg.sender].status = GAMESTATUS.CLAIM;
    }
}