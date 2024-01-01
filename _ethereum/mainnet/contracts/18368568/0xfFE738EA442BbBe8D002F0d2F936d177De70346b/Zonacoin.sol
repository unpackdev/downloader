// SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./Ownable.sol";

pragma solidity ^0.8.21;

// The Zonacoin contract is a standard ERC20 token with added staking functionality and reward accrual for participation in staking.

// Let's go through the contract's functions one by one:


//This is not the full version of your contacts
//https://zonacoin.org/ Web3 Zonacoin
//https://wiki.zonacoin.org/ Web3 Wiki Zonacoin
//https://t.me/ZonaCoinOrg Telegram News
//https://t.me/ZonacoinChat Telegram chat
// email Zonacoin@zonacoin.org

contract Zonacoin is ERC20, Ownable {
    uint256 public maxSupply = 50000000 * 10**18; //50 million is the maximum limit, we will prohibit staking when the value reaches ~50 million. Although there is no limit on staking in the contract, we will make a mention so that people understand what can be expected in 10 years
    uint256 public stakePercentage = 0;
    uint256 private storedStakePercentage;
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => uint256) private unstakeTime;

// 1. Constructor
// The constructor performs the following actions:

// - Calls the ERC20 constructor with parameters "Zonacoin" and "ZNC"
// - Calls the Ownable constructor with the parameter msg.sender (the contract creator's address)
// - Executes the _mint function, which creates 1,000,000 tokens and sends them to the contract creator's address.

    constructor() ERC20("Zonacoin", "ZNC") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10**18);
    }

// 2. Stake Function
// The stake function allows a user to lock their tokens in the contract and earn rewards for participating in staking. The function takes the parameter amount, which represents the number of tokens the user wants to lock.

// The function performs the following actions:

// - Checks if the user has enough tokens to stake
// - Calls the _transfer function to transfer tokens from the user to the contract
// - Increases the stakedBalances value for the user by the amount
// - Sets the lastStakeTime for the user equal to the current time
// - Sets the unstakeTime for the user equal to the current time plus 86400 seconds (1 day).

    function stake(uint256 amount) external {
        require(amount <= balanceOf(msg.sender), "Insufficient balance");

        _transfer(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        lastStakeTime[msg.sender] = block.timestamp;
        unstakeTime[msg.sender] = block.timestamp + 86400; // 1 days
    }

// 3. Unstake Function
// The unstake function allows a user to unlock their tokens and receive rewards for participating in staking. The function takes the parameter amount, which represents the number of tokens the user wants to unlock.

// The function performs the following actions:

// - Checks if the user has enough staked tokens to unstake
// - Checks if enough time has passed since the tokens were staked (1 day)
// - Calculates the reward for the user by calling the calculateReward function
// - Checks if the contract has enough tokens to pay the reward and the requested amount
// - Calls the _transfer function to transfer tokens from the contract to the user
// - Decreases the stakedBalances value for the user by the amount
// - Sets the lastStakeTime for the user equal to the current time.

    function unstake(uint256 amount) external {
        require(amount <= stakedBalances[msg.sender], "Insufficient staked balance");
        require(block.timestamp >= unstakeTime[msg.sender], "Cannot unstake before 1 days");

        uint256 reward = calculateReward(msg.sender);
        require(amount + reward <= balanceOf(address(this)), "Insufficient balance in contract");

        _transfer(address(this), msg.sender, amount + reward);
        stakedBalances[msg.sender] -= amount;
        lastStakeTime[msg.sender] = block.timestamp;
    }

// 4. Calculate Reward Function
// The calculateReward function calculates the reward for participating in staking for a given user. The function takes the parameter account, which represents the user's address.

// The function performs the following actions:

// - Gets the stakedAmount value for the user
// - Calculates the time elapsed since the last token staking in minutes
// - Calculates the reward using the storedStakePercentage (the staking percentage value stored in the contract).

// Please let me know if there's anything else you'd like to know!

    function calculateReward(address account) public view returns (uint256) {
        uint256 stakedAmount = stakedBalances[account];
        uint256 timeDiff = (block.timestamp - lastStakeTime[account]) / 60; // Difference in minutes
        uint256 reward = (stakedAmount * storedStakePercentage * timeDiff) / 100000000000; // Using storedStakePercentage
        return reward;
    }

// 5. Modifier resetReward

// The resetReward modifier calls the calculateReward function and awards the user with the calculated reward if it is greater than zero. Then, the modifier performs the remaining actions of the function it was applied to.

    modifier resetReward() {
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            _mint(msg.sender, reward);
            lastStakeTime[msg.sender] = block.timestamp;
        }
        _;
    }

// 6. Function setStakePercentage

// The setStakePercentage function allows the contract owner to change the stake percentage value. The function takes the parameter percentage, which represents the new stake percentage value.

// The function performs the following actions:

// - Checks that the new stake percentage value is within the allowed range (from 0 to 189998)
// - Stores the current stake percentage value in storedStakePercentage
// - Sets the new stake percentage value in stakePercentage.


// We do not have the right to change the reward without clear instructions; any violation by the contract is not allowed!1/2

// Every ~1,200,000 - ~1,300,000 blocks of Ethereum, the Zonacoin reward will decrease by 0.875%, which is equivalent to 12.5%.
// This means that the reward for staking will decrease every 6 months.
// Every 6 months, there will be a halving event.
// The first halving will occur on April 17, 2024.

// The difference may be 1-3 days from the halving!
// 189,999 - October 17, 2023
// 165,624 ~ April 17, 2024
// 144,119 ~ October 16, 2024
// 126,573 ~ April 16, 2025
// 110,587 ~ October 16, 2025
// 96,695  ~ April 16, 2026
// 84,553  ~ October 16, 2026
// 73,942  ~ April 16, 2027
// 64,500  ~ October 17, 2027
// ....

// We do not have the right to change the reward without clear instructions; any violation by the contract is not allowed!2/2

    function setStakePercentage(uint256 percentage) external resetReward onlyOwner {
        require(percentage >= 0 && percentage <= 189998, "Invalid stake percentage"); // 189998~100% ^-^

        storedStakePercentage = stakePercentage; // Saving the current value of stakePercentage
        stakePercentage = percentage; // Updating the stakePercentage
    }

// 7. Function fullUnstake

// The fullUnstake function allows a user to unfreeze all their staked tokens and receive rewards for their participation in staking. The function performs the following actions:

// - Checks if enough time has passed since the tokens were staked (1 day)
// - Calculates the amount of staked tokens for the user
// - Calculates the reward for the user by calling the calculateReward function
// - Checks if the contract has enough tokens to pay the reward and the requested amount
// - Calls the _transfer function to transfer tokens from the contract to the user
// - Sets the stakedBalances value for the user to zero
// - Sets the lastStakeTime for the user to the current time.

    function fullUnstake() external resetReward {
        require(block.timestamp >= unstakeTime[msg.sender], "Cannot perform full stake before 1 days");

        uint256 amount = stakedBalances[msg.sender];
        uint256 reward = calculateReward(msg.sender);
        require(amount + reward <= balanceOf(address(this)), "Insufficient balance in contract");

        _transfer(address(this), msg.sender, amount + reward);
        stakedBalances[msg.sender] = 0;
        lastStakeTime[msg.sender] = block.timestamp;
    }

// 8. Function renounceOwnership

// The renounceOwnership function overrides the function from the Ownable contract and prohibits the contract owner from relinquishing ownership of the contract. If the function is called, it will throw an exception.

// I hope this helps! If you have any further questions, feel free to ask.

    function renounceOwnership() public virtual override onlyOwner {
    revert("Cannot renounce ownership");
}
}

//Happy investment, and remember, your creator does not like meme coins and also does not like hype projects) 
//I love you cats ^:^
//I LIVE ZONACOIN TOKEN ERC20 #1