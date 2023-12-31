// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title Reward
 * @dev This contract handles the distribution of rewards to recipients.
 * It allows single and batch reward distributions, checks for available balance,
 * and emits events to log reward distribution and balance changes.
 */
contract Reward is Ownable{

    IERC20 public usdtToken; // Declare a variable for the USDC token contract
    IERC20 public erc20Crypto;



// Event emitted when funds are added to the contract
    event addedFund(address walletAddress, uint256 fund);

// Event emitted to indicate whether the reward amount is less than the smart contract's balance
    event event_isRewardAmountLessThanSMCBalance(bool isRewardAmountLessThanSMCBalance);

// Event emitted when a reward is successfully distributed
    event rewardDistributed(address rewardSMC, address recipient, uint256 rewardAmount);

// Event emitted when rewards are successfully distributed in batch
    event rewardDistributedInBatch(address rewardSMC, address payable[] recipient, uint256[] rewardAmount);

// Event emitted after reward distribution to log the balance of the contract
    event balanceAfterRewardDistribution(uint256 balanceAfterRewardDistribution);

// Event emitted to log details of failed reward distributions
    event failedRewardDistribution(address[] failedRecipient, uint256[] rewardAmount);

// Event emitted to log details of successful reward distributions
    event succeededRewardDistribution(address[] succeededRecipient, uint256[] rewardAmount);

    event transferredUSDT(address userAddress, uint256 amount);
    event changedERC20Token(address newCrypto);
    event transferredCrypto(address userAddress, uint256 amount);

// Constructor to initialize the contract with an owner
    constructor(address ownerOfTheSmartContract, address  _usdcTokenAddress){
        // Set the provided address as the initial owner of the smart contract
        _transferOwnership(ownerOfTheSmartContract);
        usdtToken = IERC20(_usdcTokenAddress);
    }

/**
 * @dev Changes the ERC-20 token used for bonus distribution.
 * @param newCrypto The address of the new ERC-20 token contract.
 * @return The address of the new ERC-20 token contract.
 */
    function changeERC20Token(address newCrypto) external onlyOwner returns (address) {
        usdtToken = IERC20(newCrypto);
        emit changedERC20Token(newCrypto);
        return newCrypto;
    }



/**
 * @dev Transfers USDT tokens to a specified address.
 * @param to The recipient's address.
 * @param amount The amount of USDT tokens to transfer.
 * @return True if the transfer is successful, false otherwise.
 */
    function transferUSDT(address to, uint256 amount) external onlyOwner returns (bool) {
        require(balanceOfUSDT() >= amount, "Not sufficient amount to transfer!");
        require(usdtToken.transfer(to, amount), "USDT transfer failed");
        emit transferredUSDT(to, amount);
        return true;
    }

/**
 * @dev Returns the balance of USDT tokens owned by the caller.
 * @return The balance of USDT tokens.
 */
    function balanceOfUSDT() public view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }


/**
 * @dev Changes the cryptocurrency used for transfers.
 * @param newCrypto The address of the new cryptocurrency contract.
 * @return The address of the new cryptocurrency contract.
 */
    function changeCrypto(address newCrypto) external onlyOwner returns (address) {
        require(newCrypto != address(0), "ERC20: Crypto address cannot be empty!"); // Ensure the new cryptocurrency address is not empty
        erc20Crypto = IERC20(newCrypto); // Update the cryptocurrency contract
        return newCrypto; // Return the new cryptocurrency contract address
    }

/**
 * @dev Transfers cryptocurrency tokens to a specified address.
 * @param to The recipient's address.
 * @param amount The amount of cryptocurrency tokens to transfer.
 * @return True if the transfer is successful, false otherwise.
 */
    function transferCrypto(address to, uint256 amount) external onlyOwner returns (bool) {
        require(erc20Crypto != IERC20(address(0)), "ERC20: Crypto address cannot be empty, Please add crypto first!"); // Ensure the cryptocurrency contract is set
        require(balanceOfCrypto() >= amount, "Not sufficient amount to transfer!"); // Ensure the caller has sufficient balance
        require(erc20Crypto.transfer(to, amount), "Cryptocurrency transfer failed"); // Perform the transfer
        emit transferredCrypto(to, amount); // Emit an event to log the transfer
        return true; // Return true to indicate a successful transfer
    }

/**
 * @dev Returns the balance of the selected cryptocurrency owned by the caller.
 * @return The balance of the selected cryptocurrency.
 */
    function balanceOfCrypto() public view returns (uint256) {
        return erc20Crypto.balanceOf(address(this)); // Return the caller's balance of the selected cryptocurrency
    }



/**
 * @dev Fallback function to receive MATIC.
 * This function is automatically called when the contract receives MATIC.
 * The received MATIC will be added to the contract's balance.
 * This function is marked as "payable" to allow the contract to accept funds.
 */
    receive() external payable {
    }
    
/**
 * @dev Get the current balance of the smart contract.
 * @return The amount of MATIC held by the contract.
 */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

/**
 * @dev Add funds to the smart contract.
 * Emits the `addedFund` event to log the added funds and the sender's address.
 * @return The amount of MATIC added to the contract.
 */
    function addFunds() external payable returns (uint256) {
        emit addedFund(msg.sender, msg.value);
        return msg.value;
    }

/**
 * @dev Check if the total reward amount is less than the smart contract's balance.
 * Emits the `event_isRewardAmountLessThanSMCBalance` event to log the result.
 * @param totalRewardAmount The total amount of MATIC for the reward.
 * @return Whether the reward amount is less than the contract's balance.
 */
    function isRewardAmountLessThanSMCBalance(uint256 totalRewardAmount) public returns (bool) {
        if (totalRewardAmount < address(this).balance) {
            emit event_isRewardAmountLessThanSMCBalance(true);
            return true;
        }

        emit event_isRewardAmountLessThanSMCBalance(false);
        return false;
    }

/**
 * @dev Distribute a reward to a recipient.
 * Requires that the reward amount is less than the smart contract's balance.
 * Transfers the reward amount to the recipient and emits the `rewardDistributed` event.
 * @param rewardAmount The amount of MATIC to be rewarded.
 * @param recipient The address of the recipient of the reward.
 * @return A boolean indicating the success of the reward distribution.
 */
    function rewardDistribution(uint256 rewardAmount, address payable recipient) external onlyOwner returns (bool) {
        require(isRewardAmountLessThanSMCBalance(rewardAmount), "Insufficient balance in reward SMC");
        
        recipient.transfer(rewardAmount);
        
        emit rewardDistributed(address(this), recipient, rewardAmount);
        
        return true;
    }

/**
 * @dev Distribute rewards to multiple recipients in batch.
 * Requires that the arrays have the same length, and each recipient address and reward amount is valid.
 * Transfers rewards to recipients, logs failed and successful distributions, and emits balance information.
 * @param rewardAmount An array of reward amounts to be distributed.
 * @param recipients An array of recipient addresses for the rewards.
 * @return A boolean indicating the success of the batch reward distribution.
 */
    function rewardDistributionInbatch(uint256[] memory rewardAmount, address payable[] memory recipients) external onlyOwner returns (bool) {
        require(recipients.length == rewardAmount.length, "Arrays must have the same length");
        
        address[] memory failedRecipients = new address[](recipients.length);
        uint256[] memory failedRewardAmount = new uint256[](rewardAmount.length);
        
        address[] memory succeededRecipients = new address[](recipients.length);
        uint256[] memory succeededRewardAmount = new uint256[](rewardAmount.length);
        
        uint256 failedCount = 0;
        uint256 succeededCount = 0;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(rewardAmount[i] > 0, "Amount must be greater than 0");
            
            // Attempt to transfer the funds
            if (rewardAmount[i] <= address(this).balance) {
                if (recipients[i].send(rewardAmount[i])) {
                    // Add succeeded recipient and reward amount to arrays
                    succeededRecipients[succeededCount] = recipients[i];
                    succeededRewardAmount[succeededCount] = rewardAmount[i];
                    succeededCount++;
                }
            } else {
                // Add failed recipient and reward amount to arrays
                failedRecipients[failedCount] = recipients[i];
                failedRewardAmount[failedCount] = rewardAmount[i];
                failedCount++;
            }
        }
        
        // Resize the arrays to remove any empty slots
        assembly {
            mstore(failedRecipients, failedCount)
            mstore(failedRewardAmount, failedCount)
            mstore(succeededRecipients, succeededCount)
            mstore(succeededRewardAmount, succeededCount)
        }

        emit failedRewardDistribution(failedRecipients, failedRewardAmount);
        emit succeededRewardDistribution(succeededRecipients, succeededRewardAmount);
        emit balanceAfterRewardDistribution(address(this).balance);
        
        return true;
    }

}