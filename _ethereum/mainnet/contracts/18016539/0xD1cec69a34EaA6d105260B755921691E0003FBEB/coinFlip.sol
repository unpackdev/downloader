// SPDX-License-Identifier: MIT
// OATTTTTTTTTTT
// https://twitter.com/ilovegamblingCF
// https://medium.com/@ilovegamblingCF
// https://coinflipeth.com

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.18;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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

// File: blockhashflip.sol



pragma solidity ^0.8.18;


contract coinFlip {
    IERC20 public token;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public owner;
    uint32 public lockPeriod; //https://www.unixtimestamp.com/index.php
    uint8 constant N = 2;

    struct Bet {
        uint256 amount; // 32
        uint88 blockToReveal; // 11
        address player; // 20
        bool hasRevealed; // 1
    }

    mapping(address => Bet) public bets;

    event BetPlaced(address indexed player, uint256 amount, uint256 revealBlock);
    event BetOutcome(address indexed player, bool won, uint256 prizeAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function placeBet( uint256 _taxAmount) external payable {

        require(msg.value > 0, "Must send some ether to place a bet");
        require(msg.value <= .1 ether, "Bet amount too large");
        require(bets[msg.sender].amount == 0, "You have a pending bet");
        require(_taxAmount == 100 * 1e18, "Must send 100 tokens for fees");

        // Check if the contract has enough allowance to transfer tokens on behalf of the user for the tax 
        uint128 allowance = uint128(token.allowance(msg.sender, address(this)));
        require(allowance >= _taxAmount, "Contract not allowed to transfer enough tokens. Please approve first.");


        // Combine the hashes from the last N blocks
        uint256 combinedHashValue = 0;
        for (uint8 i = 0; i < N; i++) {
            combinedHashValue ^= uint256(blockhash(block.number - 1 - i));
        }

        uint256 blocksToWait = (combinedHashValue % 11) + 2;

        token.transferFrom(msg.sender, BURN_ADDRESS, _taxAmount);

        bets[msg.sender] = Bet({
            amount: msg.value,
            player: msg.sender,
            blockToReveal: uint88(block.number + blocksToWait),
            hasRevealed: false
        });

        emit BetPlaced(msg.sender, msg.value, block.number + blocksToWait);
    }


    function revealBet() external {
        Bet storage bet = bets[msg.sender];
        require(bet.amount > 0, "You have no bet placed");
        require(!bet.hasRevealed, "Already revealed");
        require(bet.player == msg.sender, "Only the player who placed the bet can reveal");
        require(block.number >= bet.blockToReveal, "Too early to reveal the bet");
        
        bet.hasRevealed = true;

        // Combine the hashes from the last N blocks
        uint256 combinedHashValue = 0;
        for (uint8 i = 0; i < N; i++) {
            combinedHashValue ^= uint256(blockhash(block.number - 1 - i));
        }

        bool won = (combinedHashValue % 2 == 0);
        if (won) {
            uint256 prize = uint256(bet.amount) * 200 / 100; 
            payable(msg.sender).transfer(prize);
            emit BetOutcome(msg.sender, true, prize);
        } else {
            emit BetOutcome(msg.sender, false, 0);
        }

        // Clear the bet for the player
        delete bets[msg.sender];
    }

    function setLockingPeriod(uint32 _lockperiod) external onlyOwner {
        require(_lockperiod >= block.timestamp + 2678400, "Cannot lock for shorter than a month");
        lockPeriod = _lockperiod;
    }

    function withdrawProfits() external onlyOwner {
        require(block.timestamp > lockPeriod , "Need to wait for locked period to be completed");
        payable(owner).transfer(address(this).balance);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }
}