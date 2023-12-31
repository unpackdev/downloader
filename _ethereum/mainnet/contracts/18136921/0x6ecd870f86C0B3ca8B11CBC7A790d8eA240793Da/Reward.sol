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
    IERC20 public erc20Crypto; // Declare a variable for the Crypto token contract


/**
 * @dev Emitted when funds are added to the contract.
 *
 * @param walletAddress The address from which funds were added.
 * @param fund The amount of funds added.
 */
    event AddedFund(address walletAddress, uint256 fund);

/**
 * @dev Emitted to indicate whether the reward amount is less than the smart contract's balance.
 *
 * @param isRewardAmountLessThanSMCBalance A boolean flag indicating if the reward amount is less than the contract's balance.
 */
    event EventIsRewardAmountLessThanSMCBalance(bool isRewardAmountLessThanSMCBalance);

/**
 * @dev Emitted when a reward is successfully distributed to a recipient.
 *
 * @param rewardSMC The address of the reward smart contract.
 * @param recipient The address of the recipient.
 * @param rewardAmount The amount of reward distributed.
 */
    event RewardDistributed(address rewardSMC, address recipient, uint256 rewardAmount);

/**
 * @dev Emitted when rewards are successfully distributed in batch to multiple recipients.
 *
 * @param rewardSMC The address of the reward smart contract.
 * @param recipients An array of recipient addresses.
 * @param rewardAmounts An array of reward amounts corresponding to each recipient.
 */
    event RewardDistributedInBatch(address rewardSMC, address payable[] recipients, uint256[] rewardAmounts);

/**
 * @dev Emitted after reward distribution to log the balance of the contract.
 *
 * @param balanceAfterRewardDistribution The balance of the contract after reward distribution.
 */
    event BalanceAfterRewardDistribution(uint256 balanceAfterRewardDistribution);

/**
 * @dev Emitted to log details of failed reward distributions.
 *
 * @param failedRecipient An array of recipient addresses for which reward distribution failed.
 * @param rewardAmounts An array of reward amounts corresponding to each failed recipient.
 */
    event FailedRewardDistribution(address[] failedRecipient, uint256[] rewardAmounts);

/**
 * @dev Emitted to log details of successful reward distributions.
 *
 * @param succeededRecipient An array of recipient addresses for which reward distribution succeeded.
 * @param rewardAmounts An array of reward amounts corresponding to each successful recipient.
 */
    event SucceededRewardDistribution(address[] succeededRecipient, uint256[] rewardAmounts);

/**
 * @dev Emitted when USDT is transferred from one user to another.
 *
 * @param userAddress The address of the user who received the USDT.
 * @param amount The amount of USDT transferred.
 */
    event TransferredUSDT(address userAddress, uint256 amount);

/**
 * @dev Emitted when the USDT token address is changed.
 *
 * @param newCrypto The new USDT token address.
 */
    event ChangedUSDTTokenAddress(address newCrypto);

/**
 * @dev Emitted when a different cryptocurrency is transferred from one user to another.
 *
 * @param userAddress The address of the user who received the cryptocurrency.
 * @param amount The amount of the cryptocurrency transferred.
 */
    event TransferredCrypto(address userAddress, uint256 amount);


// Constructor to initialize the contract with an owner
    constructor(address ownerOfTheSmartContract, address  _usdtTokenAddress){
        // Set the provided address as the initial owner of the smart contract
        _transferOwnership(ownerOfTheSmartContract);
        usdtToken = IERC20(_usdtTokenAddress);
    }

/**
 * @dev Changes the ERC-20 token used for bonus distribution.
 * @param newUSDT The address of the new ERC-20 token contract.
 * @return The address of the new ERC-20 token contract.
 */
    function changeUSDTToken(address newUSDT) external onlyOwner returns (address) {
        usdtToken = IERC20(newUSDT);
        emit ChangedUSDTTokenAddress(newUSDT);
        return newUSDT;
    }

/**
 * @dev Allows the current owner to transfer ownership of the contract to a new address.
 *
 * @param newOwner The address of the new owner.
 * @return The address of the new owner after the transfer.
 */
    function changeOwnerOfContract(address newOwner) external onlyOwner returns (address) {
        // Ensure that the new owner address is not the zero address (invalid).
        require(newOwner != address(0), "New owner cannot be the zero address");

        // Call the internal function to transfer ownership to the new address.
        _transferOwnership(newOwner);

        // Return the address of the new owner after the transfer.
        return newOwner;
    }



/**
 * @dev Transfers USDT tokens to a specified address.
 * @param to The recipient's address.
 * @param amount The amount of USDT tokens to transfer.
 * @return True if the transfer is successful, false otherwise.
 */
    function transferUSDT(address to, uint256 amount) external onlyOwner returns (bool) {
        require(balanceOfUSDT() >= amount, "Not sufficient amount to transfer!");
        emit TransferredUSDT(to, amount);
        require(usdtToken.transfer(to, amount), "USDT transfer failed");
        return true;
    }

/**
 * @dev Returns the balance of USDT tokens owned by the caller.
 * @return The balance of USDT tokens.
 */
    function balanceOfUSDT() public view returns (uint256) {
        return usdtToken.balanceOf(msg.sender);
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
        require(balanceOfUSDT() >= amount, "Not sufficient amount to transfer!"); // Ensure the caller has sufficient balance
        emit TransferredCrypto(to, amount); // Emit an event to log the transfer
        require(erc20Crypto.transfer(to, amount), "Cryptocurrency transfer failed"); // Perform the transfer
        return true; // Return true to indicate a successful transfer
    }

/**
 * @dev Returns the balance of the selected cryptocurrency owned by the caller.
 * @return The balance of the selected cryptocurrency.
 */
    function balanceOfCrypto() public view returns (uint256) {
        require(erc20Crypto != IERC20(address(0)), "ERC20: Crypto address cannot be empty, Please add crypto first!");
        return erc20Crypto.balanceOf(msg.sender); // Return the caller's balance of the selected cryptocurrency
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
        emit AddedFund(msg.sender, msg.value);
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
            emit EventIsRewardAmountLessThanSMCBalance(true);
            return true;
        }

        emit EventIsRewardAmountLessThanSMCBalance(false);
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
        // Check: Verify conditions and inputs.
        require(isRewardAmountLessThanSMCBalance(rewardAmount), "Insufficient balance in reward SMC");

        // Effects: Update the contract state.
        // Note: It's safer to transfer funds using `transfer` instead of `send`.
        // Using `transfer` will throw an exception if the transfer fails, protecting against reentrancy.
        recipient.transfer(rewardAmount);

        // Emit the event after state updates.
        emit RewardDistributed(address(this), recipient, rewardAmount);

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
    function rewardDistributionInBatch(uint256[] memory rewardAmount, address payable[] memory recipients) external onlyOwner returns (bool) {
    // Check: Verify conditions and inputs.
    require(recipients.length == rewardAmount.length, "Arrays must have the same length");

    // Arrays to track successful and failed recipients and reward amounts.
    address[] memory failedRecipients = new address[](recipients.length);
    uint256[] memory failedRewardAmount = new uint256[](rewardAmount.length);

    address[] memory succeededRecipients = new address[](recipients.length);
    uint256[] memory succeededRewardAmount = new uint256[](rewardAmount.length);

    uint256 failedCount = 0;
    uint256 succeededCount = 0;

    for (uint256 i = 0; i < recipients.length; i++) {
        require(recipients[i] != address(0), "Invalid recipient address");
        require(rewardAmount[i] > 0, "Amount must be greater than 0");

        // Check if the contract balance is sufficient for the transfer.
        if (rewardAmount[i] <= address(this).balance) {
            // Effects: Update the contract state before interactions.
            address payable recipient = recipients[i];
            uint256 amount = rewardAmount[i];

            // Interactions: Transfer funds using 'transfer'.
            bool success = recipient.send(amount);

            // Effects: Update state based on the result of the transfer.
            if (success) {
                succeededRecipients[succeededCount] = recipient;
                succeededRewardAmount[succeededCount] = amount;
                succeededCount++;
            } else {
                failedRecipients[failedCount] = recipient;
                failedRewardAmount[failedCount] = amount;
                failedCount++;
            }
        } else {
            failedRecipients[failedCount] = recipients[i];
            failedRewardAmount[failedCount] = rewardAmount[i];
            failedCount++;
        }
    }

    // Resize the arrays to remove any empty slots.
    assembly {
        mstore(failedRecipients, failedCount)
        mstore(failedRewardAmount, failedCount)
        mstore(succeededRecipients, succeededCount)
        mstore(succeededRewardAmount, succeededCount)
    }

    // Emit events after state updates.
    emit FailedRewardDistribution(failedRecipients, failedRewardAmount);
    emit SucceededRewardDistribution(succeededRecipients, succeededRewardAmount);
    emit BalanceAfterRewardDistribution(address(this).balance);

    return true;
}


}