/**
 *Submitted for verification at Etherscan.io on 2023-11-28
*/

// Sources flattened with hardhat v2.19.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.0.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File contracts/BullRun.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;
contract BullRun {

    event BettingOpened(); // Event emitted when betting is opened
    event BettingClosed(); // Event emitted when betting is closed
    event BetPlaced(address indexed bettor, uint indexed bull, uint amount); // Event emitted when a bet is placed
    event WinnerDeclared(uint indexed winningBull); // Event emitted when the winner is declared
    event PrizePool(uint amount); // Event emitted when the prize pool is updated

    struct Bet {
        uint amount; // Amount of the bet
        uint bull; // Bull number
        address bettor; // Address of the bettor
    }

    Bet[] public bets; // Array to store all the bets
    uint public houseTakePercent = 5; // Percentage of the total pool that goes to the house (5% in this example)
    bool public bettingOpen = true; // Flag to indicate if betting is open or closed
    bool private locked = false; // Flag to prevent reentrancy attacks
    uint public winningBull; // Number of the winning bull
    address public owner; // Address of the contract owner

    IERC20 public token;

    constructor(IERC20 _token) {
        owner = msg.sender; // Set the contract owner as the deployer of the contract
        token = _token;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function"); // Modifier to restrict access to the contract owner
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy"); // Modifier to prevent reentrancy attacks
        locked = true;
        _;
        locked = false;
    }

    function placeBet(uint bull, uint amount) public payable noReentrancy {
        require(bettingOpen, "Betting is closed"); // Check if betting is open
        require(bull >= 1 && bull <= 6, "Invalid bull number"); // Check if the bull number is valid (between 1 and 6)
        require(amount > 0, "Bet amount must be greater than 0"); // Check if the bet amount is greater than 0
        require(msg.value >= 0.005 ether, "Payment must be at least 0.005 ether");

        token.transferFrom(msg.sender, address(this), amount); // Transfer the tokens from the bettor to this contract

        bets.push(Bet(amount, bull, msg.sender)); // Add the bet to the bets array
        emit BetPlaced(msg.sender, bull, amount); // Emit the BetPlaced event
        emit PrizePool(token.balanceOf(address(this))); // Emit the PrizePool event with the updated balance of the contract
    }

    function closeBetting() public onlyOwner noReentrancy{
        require(bettingOpen, "Betting is already closed"); // Check if betting is already closed
        bettingOpen = false; // Close the betting
        emit BettingClosed(); // Emit the BettingClosed event
    }

    function openBetting() public onlyOwner noReentrancy{
        require(!bettingOpen, "Betting is already open"); // Check if betting is already open
        bettingOpen = true; // Open the betting
        emit BettingOpened(); // Emit the BettingOpened event
    }

    function declareWinner(uint bull) public onlyOwner noReentrancy {
        require(!bettingOpen, "Betting is still open"); // Check if betting is closed
        winningBull = bull; // Set the winning bull number
        distributeWinnings(); // Distribute the winnings to the bettors
        emit WinnerDeclared(winningBull); // Emit the WinnerDeclared event
    }

    function distributeWinnings() internal {
        uint totalPool = token.balanceOf(address(this)); // Get the total pool balance
        uint houseTake = (totalPool * houseTakePercent) / 100; // Calculate the house take
        uint payoutPool = totalPool - houseTake; // Calculate the payout pool
        uint[] memory totalBetsPerBull = new uint[](6); // Array to store the total bets for each bull

        uint betsLength = bets.length;
        require(betsLength > 0, "No bets placed");
        for (uint i = 0; i < betsLength; i++) {
            totalBetsPerBull[bets[i].bull - 1] += bets[i].amount; // Calculate the total bets for each bull
        }

        // Calculate winnings for each bettor who bet on the winning bull
        for (uint i = 0; i < betsLength; i++) {
            if (bets[i].bull == winningBull) {
                uint betAmount = bets[i].amount;
                // Calculate the bettor's share of the winnings
                uint winnings = (betAmount * payoutPool) / totalBetsPerBull[winningBull - 1];
                token.transfer(bets[i].bettor, winnings); // Transfer the winnings to the bettor
            }
        }

        // Clear the bets for the next race
        delete bets;

        // Reset the winning bull
        winningBull = 0;
    }

    function withdrawTokens() public onlyOwner noReentrancy{
        require(!bettingOpen, "Betting must be closed");
        require(bets.length == 0, "All bets must be paid out");
        
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.transfer(owner, balance);
    }

    function withdrawEther() public onlyOwner noReentrancy {
        require(!bettingOpen, "Betting must be closed");
        uint balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");

        // Transfer Ether to the owner
        payable(owner).transfer(balance);
    }

    function refundBets() public onlyOwner noReentrancy {
      require(!bettingOpen, "Betting is still open");
      for (uint i = 0; i < bets.length; i++) {
        token.transfer(bets[i].bettor, bets[i].amount);
      }
    }
}