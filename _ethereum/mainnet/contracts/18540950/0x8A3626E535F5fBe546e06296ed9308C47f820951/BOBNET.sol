// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2.sol";

/**
 * @author BLOCKCHAINX
 * @title BOBNET
 * @dev BOBNET is an ERC-20 token contract with additional functionality.
 *
 * This contract represents the BobNet token (BOB) and includes features such as tax collection,
 * treasury wallets, and a maximum trade amount. It also integrates with the Uniswap decentralized
 * exchange for liquidity provision.
 *
 * The contract inherits from the Ownable contract and the IERC20 interface.
 */
contract BOBNET is IERC20, Ownable {
    string public name = "BOBNET"; // Token name
    string public symbol = "$BOBNET"; // Token symbol
    uint8 public decimals = 18; // Number of decimal places
    uint256 private _totalSupply; // Total supply of tokens

    uint256 public maxTradeAmount = 10000 * 10 ** 18; // Maximum trade amount (1,000,000 tokens)
    uint256 public thresholdTokenAmount = 10000 * 10 ** 18; // Threshold amount for tax collection
    address[] private treasuryWallets; // Addresses for treasury wallets
    uint256[] public treasuryWalletsShare; // shares for treasury wallets
    bool private swapFeeToEth; // Flag for swapping fees to ETH
    address public UNISWAPV2ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2 Router address
    IUniswapV2Router02 public uniswapV2Router; // Uniswap V2 Router contract instance
    address public uniswapV2Pair; // Uniswap V2 token pair address
    mapping(address => bool) public _isExcludedFromDexFee; // Addresses excluded from DEX fees
    uint256 public totalFeeInTokens; // Total fee collected in tokens
    uint256 public buyTax = 5; // Buy tax percentage
    uint256 public sellTax = 5; // Sell tax percentage
    bool public isFeeEnabled; // Flag for enabling/disabling fees

    // Events
    event UpdateTreasuryWallets(address[] addresses); // Event for updating treasury wallet addresses
    event TaxCollected(uint256 amount); // Event for tax collection
    event ThresholdUpdated(uint256 amount); // Event for updating the threshold amount
    event WithdrawToken(uint256 amount); // Event for token withdrawal
    event WithdrawNative(uint256 amount); // Event for native (ETH) withdrawal
    event UpdateTradeStatus(bool status); // Event for updating the trade status
    event UpdateTax(uint256 tax); // Event for updating the tax
    event WithdrawToken(address token, address to, uint256 amount); // Event for Withdraw token from contract

    // Balances and allowances mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Constructor to initialize the BobNetV2 contract.
     *
     * @param initialSupply The initial supply of tokens (in the smallest unit, with decimals).
     * @param initialAddresses An array containing 5 initial treasury wallet addresses.
     *
     * Requirements:
     * - Exactly 5 initial addresses must be provided, and none of them can be the zero address.
     */
    constructor(uint256 initialSupply,uint256[] memory shares, address[] memory initialAddresses) {
        require(
            initialAddresses.length == 8,
            "You must provide exactly 8 addresses."
        );
        require(
            shares.length == 8,
            "You must provide exactly 8 shares."
        );
        for (uint256 i = 0; i < initialAddresses.length; i++) {
            require(
                initialAddresses[i] != address(0),
                "Address cannot be the zero address."
            );
            treasuryWallets.push(initialAddresses[i]);
            treasuryWalletsShare.push(shares[i]);
        }
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            UNISWAPV2ROUTER
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
    }

    /**
     * @dev Get the total supply of tokens.
     *
     * This function returns the total supply of tokens in circulation.
     *
     * @return The total supply of tokens as a uint256 value.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get the token balance of a specific account.
     *
     * This function returns the token balance of a specified account.
     *
     * @param account The address of the account for which to retrieve the balance.
     * @return The token balance of the specified account as a uint256 value.
     */
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfer tokens to a specified address.
     *
     * This function allows the sender to transfer tokens to a specified recipient.
     *
     * @param to The recipient's address.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful (true) or not (false).
     */

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Get the allowance for a spender to spend tokens on behalf of an owner.
     *
     * This function returns the allowance that has been approved by the owner for the spender
     * to spend tokens on their behalf.
     *
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @return The allowance for the specified spender as a uint256 value.
     */
    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approve a spender to spend tokens on behalf of the sender.
     *
     * This function allows the sender to approve a specified address (spender) to spend a
     * specified amount of tokens on their behalf.
     *
     * @param spender The address to which approval is granted.
     * @param amount The amount of tokens to approve for spending.
     * @return A boolean indicating whether the approval was successful (true) or not (false).
     */
    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another using an allowance.
     *
     * This function allows a designated sender to transfer tokens from one address (`from`)
     * to another address (`to`) on behalf of the sender, as long as the allowance is sufficient.
     *
     * @param from The address from which tokens are transferred.
     * @param to The address to which tokens are transferred.
     * @param amount The amount of tokens to transfer.
     * @return A boolean indicating whether the transfer was successful (true) or not (false).
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(from, to, amount);
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(from, msg.sender, currentAllowance - amount);
        return true;
    }

    /**
     * @dev Increase the allowance for a spender.
     *
     * This function allows the sender to increase the allowance for a specified address (spender)
     * by a specified amount (addedValue).
     *
     * @param spender The address for which to increase the allowance.
     * @param addedValue The additional amount to add to the current allowance.
     * @return A boolean indicating whether the increase was successful (true) or not (false).
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Decrease the allowance for a spender.
     *
     * This function allows the sender to decrease the allowance for a specified address (spender)
     * by a specified amount (subtractedValue).
     *
     * @param spender The address for which to decrease the allowance.
     * @param subtractedValue The amount to subtract from the current allowance.
     * @return A boolean indicating whether the decrease was successful (true) or not (false).
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
     * @dev Internal function to perform a token transfer with potential fees.
     *
     * This function transfers tokens from one address (`from`) to another address (`to`) while
     * considering various scenarios, including fees, maximum trade amount, and fee distribution.
     *
     * @param from The sender's address.
     * @param to The recipient's address.
     * @param amount The amount of tokens to transfer.
     *
     * Requirements:
     * - Neither the `from` nor the `to` address can be the zero address.
     * - The `from` address must have a balance greater than or equal to the transfer amount.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        // Deduct the transferred amount from the `from` balance.
        _balances[from] -= amount;

        // Initialize a variable to store the final amount to be received by the `to` address.
        uint256 toAmount;

        // Handle different scenarios based on trade, fees, and maximum trade amount.
        if (
            (from == uniswapV2Pair || to == uniswapV2Pair) &&
            (!swapFeeToEth && isFeeEnabled)
        ) {
            // Check if the transfer amount exceeds the maximum trade amount.
            require(
                amount <= maxTradeAmount,
                "ERC20: exceeds max trade amount"
            );
            uint256 taxAmount;

            // Determine if it's a buy or sell transaction and calculate the corresponding tax.
            if (from == uniswapV2Pair) {
                taxAmount = calculateTax(amount, buyTax);
            } else if (to == uniswapV2Pair) {
                taxAmount = calculateTax(amount, sellTax);
            }

            // Calculate the final amount to be received by the `to` address after deducting the trade tax.
            toAmount = amount - taxAmount;

            // Increase the contract's balance by the trade tax.
            _balances[address(this)] += taxAmount;

            // Update the total fee in tokens.
            totalFeeInTokens += taxAmount;

            // Emit a `Transfer` event to log the trade tax.
            emit Transfer(from, address(this), taxAmount);
        } else {
            // In scenarios without fees or max trade limits, the `toAmount` remains the same.
            toAmount = amount;
        }

        // If not swapping to ETH and the sender is not the Uniswap pair, distribute fees.
        if (!swapFeeToEth && from != uniswapV2Pair) {
            distributeFee();
        }

        // Update the balance of the `to` address with the final `toAmount`.
        _balances[to] += toAmount;

        // Emit a `Transfer` event to log the final token transfer.
        emit Transfer(from, to, toAmount);
    }

    /**
     * @dev Internal function to approve spending on behalf of an owner.
     *
     * This internal function allows an owner to approve another address (spender) to spend
     * a specified amount of tokens on their behalf. It checks that neither the owner nor the
     * spender addresses are the zero address and updates the allowances accordingly.
     *
     * @param owner The address that owns the tokens.
     * @param spender The address to which approval is granted.
     * @param amount The amount of tokens to approve for spending.
     *
     * Requirements:
     * - Neither the owner nor the spender address can be the zero address.
     *
     * Emits an `Approval` event to signal the approval of the spending allowance.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Update the treasury wallets with new addresses.
     *
     * This function allows the contract owner to update the treasury wallets with a new set
     * of addresses. It checks that exactly 5 addresses are provided and that none of them
     * are the zero address. The new addresses are then stored in the treasuryWallets array.
     *
     * @param newAddresses An array containing the 5 new treasury wallet addresses.
     *
     * Requirements:
     * - Exactly 5 addresses must be provided.
     * - None of the provided addresses can be the zero address.
     *
     * Emits an `UpdateTreasuryWallets` event with the new addresses.
     */
    function updateTreasuryWallets(
        address[] memory newAddresses
    ) external onlyOwner {
        require(
            newAddresses.length == 7,
            "You must provide exactly 7 addresses."
        );
        for (uint256 i = 1; i < newAddresses.length; i++) {
            require(
                newAddresses[i] != address(0),
                "Address cannot be the zero address."
            );
            treasuryWallets[i] = newAddresses[i-1];
        }
        emit UpdateTreasuryWallets(newAddresses);
    }

    /**
     * @dev Distribute collected tax (native currency) to multiple treasury wallets.
     *
     * This internal function evenly distributes the collected native currency (ETH) balance
     * among multiple treasury wallets. It checks that each treasury wallet address is valid,
     * and then transfers an equal share of the tax amount to each of the treasury wallets.
     * Emits a `TaxCollected` event with the total tax amount distributed.
     */
    function _distributeTax() internal {
        uint256 taxAmount = address(this).balance;

        
        for (uint256 i = 0; i < treasuryWallets.length; i++) {
            uint256 eachShare = (taxAmount * treasuryWalletsShare[i])/1000;
            require(
                treasuryWallets[i] != address(0),
                "Treasury wallet address cannot be the zero address."
            );
            payable(treasuryWallets[i]).transfer(eachShare);
        }
        emit TaxCollected(taxAmount);
    }

    /**
     * @dev Calculate the tax amount based on the provided amount and tax percentage.
     *
     * This internal function calculates the tax amount by multiplying the provided amount
     * with the tax percentage and dividing by 100 to convert it to the correct decimal scale.
     *
     * @param _amount The amount of tokens for which to calculate the tax.
     * @param _taxPercentage The tax percentage to apply.
     * @return The calculated tax amount as a uint256 value.
     */
    function calculateTax(
        uint256 _amount,
        uint256 _taxPercentage
    ) internal pure returns (uint256) {
        return (_amount * _taxPercentage) / 10 ** 2;
    }

    /**
     * @dev Distribute accumulated fees if the contract balance meets the threshold.
     *
     * This internal function checks if the contract's token balance is greater than or equal to the
     * threshold token amount. If so, it proceeds to distribute fees by swapping tokens for native currency (ETH)
     * and transferring the ETH to 5 treasury wallets. It also resets the fee-related state variables.
     */
    function distributeFee() internal {
        uint256 contractTokenBalance = _balances[address(this)];

        if (contractTokenBalance >= thresholdTokenAmount) {
            // to prevent from transaction loop
            swapFeeToEth = true;

            // Sell tokens in the liquidity pool to obtain native (ETH) in the contract.
            swapTokensForEth(contractTokenBalance, address(this));

            // Transfer native (ETH) from the contract to 5 treasury wallets.
            _distributeTax();

            totalFeeInTokens = 0;

            swapFeeToEth = false;
        }
    }

    /**
     * @dev Swap tokens for native currency (ETH) using Uniswap.
     *
     * This private function is responsible for swapping a given amount of tokens for ETH
     * using the Uniswap decentralized exchange.
     *
     * @param tokenAmount The amount of tokens to swap for ETH.
     * @param account The address to receive the swapped ETH.
     */
    function swapTokensForEth(uint256 tokenAmount, address account) private {
        // Generate the Uniswap pair path for token -> WETH.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Approve the Uniswap router to spend the token.
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap using Uniswap.
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            account,
            block.timestamp
        );
    }

    /**
     * @dev Update the threshold token amount required for certain operations.
     *
     * This function allows the contract owner to update the threshold token amount
     * required for specific operations. Only the contract owner can call this function.
     *
     * @param amount The new threshold token amount to set.
     *
     * Requirements:
     * - The `amount` must be greater than 0.
     *
     * Emits a `ThresholdUpdated` event with the new amount.
     */
    function updateThreshold(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        thresholdTokenAmount = amount;
        emit ThresholdUpdated(amount);
    }

    /**
     * @dev Allows the owner to withdraw native cryptocurrency (e.g., ETH) from this contract.
     */
    function withdrawNative() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Allows the owner to withdraw ERC-20 tokens from this contract.
     * @param _tokenContract The address of the ERC-20 token contract.
     * @param _amount The amount of tokens to withdraw.
     * @notice The '_tokenContract' address should not be the zero address.
     */
    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit WithdrawToken(_tokenContract, msg.sender, _amount);
    }

    /**
     * @dev Enable or disable fee collection functionality.
     *
     * This function allows the contract owner to enable or disable fee collection within the contract.
     * When fee collection is enabled, certain operations may apply fees. Only the contract owner
     * can call this function.
     *
     * @param status A boolean value indicating whether fee collection should be enabled (true) or
     * disabled (false).
     *
     * Effects:
     * - Updates the fee collection status of the contract.
     * - Emits an `UpdateTradeStatus` event with the new status.
     */
    function enableFee(bool status) external onlyOwner {
        isFeeEnabled = status;
        emit UpdateTradeStatus(status);
    }

    // /**
    //  * @dev Update the buy tax rate.
    //  *
    //  * This function allows the contract owner to update the buy tax rate, which is applied to
    //  * buy transactions. The buy tax rate represents the percentage of tokens that will be
    //  * collected as tax when buying tokens.
    //  *
    //  * @param tax The new buy tax rate to be set.
    //  *
    //  * Emits an `UpdateTax` event to signal the change in the buy tax rate.
    //  */
    // function updateBuyTax(uint256 tax) external onlyOwner {
    //     buyTax = tax;
    //     emit UpdateTax(tax);
    // }

    // /**
    //  * @dev Update the sell tax rate.
    //  *
    //  * This function allows the contract owner to update the sell tax rate, which is applied to
    //  * sell transactions. The sell tax rate represents the percentage of tokens that will be
    //  * collected as tax when selling tokens.
    //  *
    //  * @param tax The new sell tax rate to be set.
    //  *
    //  * Emits an `UpdateTax` event to signal the change in the sell tax rate.
    //  */
    // function updateSellTax(uint256 tax) external onlyOwner {
    //     sellTax = tax;
    //     emit UpdateTax(tax);
    // }

    /**
     * @dev Get the list of treasury wallet addresses.
     *
     * This function allows anyone to retrieve the list of treasury wallet addresses.
     *
     * @return An array containing the treasury wallet addresses.
     */
    function getTreasuryWallets() external view returns (address[] memory) {
        return treasuryWallets;
    }

    /**
     * @dev Fallback function to accept native currency (Ether).
     *
     * This function allows the contract to receive native currency (Ether) sent to it.
     * It's typically used for depositing Ether into the contract.
     *
     * Effects:
     * - Receives native currency (Ether) and stores it in the contract balance.
     * - No explicit actions are performed in this function.
     */
    receive() external payable {}
}
