// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: turkeys/turkeyRaceBot.sol


pragma solidity ^0.8.0;

interface GameTurkeys {
    struct Stats {
        uint8 strength;
        uint8 intelligence;
        uint8 speed;
        uint8 bravery;
    }
    function getTokenStats(uint256 tokenId) external view returns (Stats memory);
}


contract TurkeysRaceBeta {
    // Variables
    address public admin;
    address public turkeys = 0x000000000000000000000000000000000000dEaD;
    IERC20 public token = IERC20(0x85Cd22083260e1D6C869ca7D89b0c8B5428e3c92);
    GameTurkeys public nftContract = GameTurkeys(0x49C59D51a3e0fA9df6c80F38Dda32b66E51b21c8);
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256[] public racers; // List of NFTs in the race
    mapping(uint256 => uint256) public bets; // tokenId => amount
    mapping(uint256 => address[]) public bettors;
    mapping(address => uint256) public balances; // User balance inside the contract
    uint256 public totalBets;
    uint256 public oddsBalancer = 90;

    address[] public bettorUsers;
    mapping(address => bool) public hasBet;
    
    // Events
    event PreRaceSet(uint256[] racers);
    event BetPlaced(address indexed user, uint256 tokenId, uint256 amount);
    event RaceCompleted(uint256 winner);
    event RacerPointsUpdated(uint256 indexed tokenId, uint256 newPoints);
    event RaceWinnerDeclared(uint256 indexed tokenId);
    event WinningBettor(address indexed bettor, uint256 amountWon);
    
    // Constructor
    constructor() {admin = msg.sender;}
    
    // Set pre-race numbers
    function preRace(uint256 numberOfRacers, uint256 totalNFTs) external {
        require(msg.sender == admin, "Only admin");
        require(numberOfRacers <= totalNFTs, "Invalid racers");

        // Reset bets and racers
        for (uint256 i = 0; i < racers.length; i++) {
            // Reset total bets for each racer tokenID
            bets[racers[i]] = 0;
        }

        // Reset user bets
        for (uint256 i = 0; i < racers.length; i++) {
            // Reset individual bet amounts for each tokenId
            bets[racers[i]] = 0;
            delete bettors[racers[i]];  // Remove all bettors for this tokenId
        }

        // Reset state
        delete racers;
        totalBets = 0;

        // Generate unique random numbers
        for(uint256 i = 0; i < numberOfRacers; i++) {
            uint256 rand = (uint256(keccak256(abi.encodePacked(block.timestamp, i))) % totalNFTs) + 1;
            while(isDuplicate(rand)) {
                rand = (uint256(keccak256(abi.encodePacked(block.timestamp, i))) % totalNFTs) + 1;
            }
            racers.push(rand);
        }
        emit PreRaceSet(racers);
    }
    
    function placeBet(uint256 tokenId, uint256 amount) external {
        require(isValidRacer(tokenId), "Invalid racer");
        require(amount < 1000000000000, "You can only bet upto 1000 $VEG.");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed"); // Directly transfer tokens from user to contract

        bets[tokenId] += amount;
        bettors[tokenId].push(msg.sender); // add bettor to the list of bettors for the specific tokenId
        totalBets += amount;
        emit BetPlaced(msg.sender, tokenId, amount);

        if(!hasBet[msg.sender]) {
            bettorUsers.push(msg.sender);
            hasBet[msg.sender] = true;
        }
    }

    function race() external {
        require(msg.sender == admin, "Only admin");

        uint256 winner = simulateRace();
        if (bets[winner] == 0) {
            // No winners, burn the tokens
            burnTokens(totalBets);
            return;
        }

        uint256 turkeyShare = (totalBets * 20) / 100;
        uint256 winnersShare = totalBets - turkeyShare;

        require(token.transfer(turkeys, turkeyShare), "Transfer to turkeys failed"); // Directly transfer turkey's share

        // Distribute winnings
        uint256 totalWinnerBets = bets[winner];
        address[] memory winnerBettors = bettors[winner];
        for(uint256 i = 0; i < winnerBettors.length; i++) {
            address bettor = winnerBettors[i];
            uint256 betAmount = bets[winner];
            uint256 share = (betAmount * winnersShare) / totalWinnerBets;
            require(token.transfer(bettor, share), "Transfer to winner failed"); // Directly transfer winner's share

            emit WinningBettor(bettor, share);  // Emit the event
        }

        emit RaceCompleted(winner);

        // Reset bets and racers
        for (uint256 i = 0; i < racers.length; i++) {
            // Reset total bets for each racer tokenID
            bets[racers[i]] = 0;
        }

        // Reset user bets
        for (uint256 i = 0; i < racers.length; i++) {
            // Reset individual bet amounts for each tokenId
            bets[racers[i]] = 0;
            delete bettors[racers[i]];  // Remove all bettors for this tokenId
        }

        // Reset state
        delete racers;
        totalBets = 0;
    }

    function simulateRace() internal returns(uint256) {
        uint256[] memory positions = new uint256[](racers.length);

        for(uint256 j = 0; j < racers.length; j++) {
        uint256 tokenId = racers[j];

        GameTurkeys.Stats memory stats = nftContract.getTokenStats(tokenId);
        uint256 speed = stats.speed;

        uint256 totalBetsForTokenRaw = bets[tokenId];
        uint256 totalBetsForToken = totalBetsForTokenRaw / (10 ** 9);
        uint256 handicap = totalBetsForToken / oddsBalancer;

        positions[j] += handicap + (speed / 10);
    }

        for(uint256 i = 0; i < 5; i++) {  // 5 rounds
            for(uint256 j = 0; j < racers.length; j++) {
                uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, i, j))) % 10;
                positions[j] += rand;
                emit RacerPointsUpdated(racers[j], positions[j]);
            }
        }

        uint256 highestPosition = 0;
        uint256 winnerIndex = 0;
        for(uint256 i = 0; i < racers.length; i++) {
            if(positions[i] > highestPosition) {
                highestPosition = positions[i];
                winnerIndex = i;
            }
        }

        uint256 winner = racers[winnerIndex];
        emit RaceWinnerDeclared(winner);

        return winner;
    }
    
    function isDuplicate(uint256 n) internal view returns(bool) {
        for(uint256 i = 0; i < racers.length; i++) {
            if(racers[i] == n) return true;
        }
        return false;
    }
    
    function isValidRacer(uint256 tokenId) internal view returns(bool) {
        for(uint256 i = 0; i < racers.length; i++) {
            if(racers[i] == tokenId) return true;
        }
        return false;
    }

    function getRacers() public view returns(uint256[] memory) {
        return racers;
    }

    function burnTokens(uint256 amount) internal {
        require(token.transfer(DEAD_ADDRESS, amount), "Failed to burn tokens");
    }

    function getCurrentTotalBettingPot() public view returns (uint256) {
        uint256 totalPot = 0;
        for (uint256 i = 0; i < racers.length; i++) {
            totalPot += bets[racers[i]];
        }
        return totalPot;
    }

    function getTotalAmountBet() public view returns (uint256) {
        return totalBets;
    }

    function getBetsValueForToken(uint256 tokenId) public view returns (uint256) {
        return bets[tokenId];
    }

    function getNumberOfBetsForRacers() public view returns (uint256[] memory) {
        uint256[] memory betCounts = new uint256[](racers.length);
        for (uint256 i = 0; i < racers.length; i++) {
            betCounts[i] = bettors[racers[i]].length;
        }
        return betCounts;
    }

    function turkeysRevenue() public {        
        uint256 amount = balances[turkeys];
        require(amount > 0, "No balance to transfer");
        
        balances[turkeys] = 0;
        require(token.transfer(turkeys, amount), "Transfer failed");
    }

    function adminTransfer(address user) public {
        require(msg.sender == admin, "Only admin can transfer");
        
        uint256 amount = balances[user];
        require(amount > 0, "No balance to transfer");
        
        balances[user] = 0;
        require(token.transfer(user, amount), "Transfer failed");
    }

    function adminTransferAll(address[] memory users) public {
        require(msg.sender == admin, "Only admin can transfer");

        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = balances[user];
            
            if (amount > 0) {
                balances[user] = 0;
                require(token.transfer(user, amount), "Transfer failed");
            }
        }
    }

    function setOddsBalancer(uint256 _newOddsBalancer) external {
        require(msg.sender == admin, "Only admin can call this.");
        oddsBalancer = _newOddsBalancer;
    }

    function withdrawStuckEther() external {
        require(msg.sender == admin, "Only admin can call this.");
        payable(admin).transfer(address(this).balance);
    }

    function withdrawStuckTokens(uint256 amount) external {
        require(msg.sender == admin, "Only admin can call this.");
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.transfer(admin, amount);
    }
}