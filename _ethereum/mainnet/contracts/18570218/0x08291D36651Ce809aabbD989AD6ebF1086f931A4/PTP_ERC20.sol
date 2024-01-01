/*
 * Welcome to P2P Financial
 *
 * website          : https://p2p.financial
 * twitter          : https://twitter.com/P2P_Financial
 * telegram channel : https://t.me/P2PFinancial
 * telegram group   : https://t.me/P2P_Financial
 * docs             : https://docs.p2p.financial
 *
 */

// SPDX-License-Identifier: MIT

import "./PTP_Dividend.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

pragma solidity ^0.8.21;

contract PTP is Ownable, ERC20 {
    uint256 public maxWallet;
    address public uniswapV2Pair;
    IUniswapV2Router02 immutable router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    PTPDividends public dividends;

    uint256 SUPPLY = 1_000_000_000 * 10 ** 18;

    uint256 snipeFee = 30;
    uint256 totalFee = 5;

    bool private inSwap = false;
    address public marketingWallet;

    uint256 public openTradingBlock;

    mapping(address => uint256) public receiveBlock;

    uint256 public swapAt = SUPPLY / 1000; //0.1%

    constructor() payable ERC20("P2P Financial", "PTP") {
        _mint(msg.sender, (SUPPLY * 20) / 1000);
        _mint(address(this), (SUPPLY * 980) / 1000);

        maxWallet = SUPPLY;

        marketingWallet = msg.sender;

        dividends = new PTPDividends();

        dividends.excludeFromDividends(address(0));
        dividends.excludeFromDividends(address(dividends));
        dividends.excludeFromDividends(address(this));
        dividends.excludeFromDividends(owner());
    }

    receive() external payable {}

    /**
     * @dev Checks if the given address is a contract.
     * @param account The address to check.
     * @return True if the address is a contract, false otherwise.
     */
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Updates the dividends contract address.
     * Can only be called by the contract owner.
     * @param _dividends The address of the new dividends contract.
     */
    function updateDividends(address _dividends) external onlyOwner {
        // Cast the _dividends address to PTPDividends contract
        dividends = PTPDividends(payable(_dividends));

        // Exclude certain addresses from receiving dividends
        dividends.excludeFromDividends(address(0)); // Exclude address(0) (burn address)
        dividends.excludeFromDividends(address(dividends)); // Exclude the dividends contract address
        dividends.excludeFromDividends(address(this)); // Exclude the current contract address
        dividends.excludeFromDividends(owner()); // Exclude the contract owner address
        dividends.excludeFromDividends(uniswapV2Pair); // Exclude the Uniswap V2 pair address
        dividends.excludeFromDividends(address(router)); // Exclude the router contract address
    }

    /**
     * @dev Updates the total fee.
     * @param _totalFee The new value for the total fee.
     * Requirements:
     * - `_totalFee` must be less than or equal to 5.
     *   This function can only be used to lower the fee.
     */
    function updateFee(uint256 _totalFee) external onlyOwner {
        require(_totalFee <= 5, "Fee can only be lowered");
        totalFee = _totalFee;
    }

    /**
     * @dev Updates the maximum holding percentage.
     * @param percent The new maximum holding percentage.
     * Requirements:
     * - `percent` must be between 1 and 100 (inclusive).
     */
    function updateMaxHoldingPercent(uint256 percent) public onlyOwner {
        require(percent >= 1 && percent <= 100, "invalid percent");
        maxWallet = (SUPPLY * percent) / 100;
    }

    /**
     * @dev Updates the value of `swapAt` with the given `value`.
     *
     * Requirements:
     * - Only the owner of the contract can call this function.
     * - The `value` must be less than or equal to `SUPPLY / 50`.
     *
     * @param value The new value of `swapAt`.
     */
    function updateSwapAt(uint256 value) external onlyOwner {
        require(
            value <= SUPPLY / 50,
            "Value must be less than or equal to SUPPLY / 50"
        );
        swapAt = value;
    }

    /**
     * @dev Retrieves the withdrawable and total dividends for the specified account.
     * @param account The address of the account to retrieve dividends for.
     * @return withdrawableDividends The amount of dividends that can be withdrawn.
     * @return totalDividends The total amount of dividends earned by the account.
     */
    function stats(
        address account
    )
        external
        view
        returns (uint256 withdrawableDividends, uint256 totalDividends)
    {
        // Call the `getAccount` function from the `dividends` contract and assign the return values to the variables.
        (, withdrawableDividends, totalDividends) = dividends.getAccount(
            account
        );
    }

    // This function allows the caller to claim their dividends.
    function claim() external {
        // Call the claim function of the dividends contract and pass the caller's address.
        dividends.claim(msg.sender);
    }

    /**
     * @dev Function to go to the moon.
     * Only the contract owner can call this function.
     * Adds liquidity to the router and updates some variables.
     */
    function goToTheMoon() external onlyOwner {
        address pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _approve(address(this), address(router), balanceOf(address(this)));
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        uniswapV2Pair = pair;
        openTradingBlock = block.number;
        dividends.excludeFromDividends(address(router));
        dividends.excludeFromDividends(pair);

        updateMaxHoldingPercent(1);
    }

    /**
     * @dev Internal transfer function.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Check if uniswapV2Pair is not set
        if (uniswapV2Pair == address(0)) {
            require(
                from == address(this) ||
                    from == address(0) ||
                    from == owner() ||
                    to == owner(),
                "Not started"
            );
            super._transfer(from, to, amount);
            return;
        }

        // Check if transferring from uniswapV2Pair and the recipient is not a contract address or the owner
        if (
            from == uniswapV2Pair &&
            to != address(this) &&
            to != owner() &&
            to != address(router)
        ) {
            require(super.balanceOf(to) + amount <= maxWallet, "max wallet");
        }

        // Calculate the amount to swap
        uint256 swapAmount = balanceOf(address(this));

        if (swapAmount > swapAt) {
            swapAmount = swapAt;
        }

        // Check if it's time to swap and not in the middle of a swap and not transferring from uniswapV2Pair
        if (
            swapAt > 0 &&
            swapAmount == swapAt &&
            !inSwap &&
            from != uniswapV2Pair
        ) {
            // Start the swap
            inSwap = true;

            // Swap tokens for ETH
            swapTokensForEth(swapAmount);

            // Get the ETH balance of the contract
            uint256 balance = address(this).balance;

            // Withdraw the ETH balance
            if (balance > 0) {
                withdraw(balance);
            }

            // End the swap
            inSwap = false;
        }

        // Calculate the fee
        uint256 fee;

        // Check if it's within a certain block range and transferring from uniswapV2Pair
        if (block.number <= openTradingBlock + 4 && from == uniswapV2Pair) {
            require(!isContract(to));
            fee = snipeFee;
        } else if (totalFee > 0) {
            fee = totalFee;
        }

        // Apply the fee if applicable
        if (
            fee > 0 &&
            from != address(this) &&
            from != owner() &&
            from != address(router)
        ) {
            uint256 feeTokens = (amount * fee) / 100;
            amount -= feeTokens;

            super._transfer(from, address(this), feeTokens);
        }

        // Transfer the tokens
        super._transfer(from, to, amount);

        // Update the dividend balances
        dividends.updateBalance(payable(from));
        dividends.updateBalance(payable(to));
    }

    /**
     * @dev Swaps tokens for ETH using the Uniswap router.
     * @param tokenAmount The amount of tokens to swap.
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        // Define the path for the swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // Swap tokens for ETH
        // Using `swapExactTokensForETHSupportingFeeOnTransferTokens` for tokens that have a fee on transfer
        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Sends funds to the specified user.
     * @param user The address of the user to send funds to.
     * @param value The amount of funds to send.
     */
    function sendFunds(address user, uint256 value) private {
        // Check if the value is greater than 0
        if (value > 0) {
            // Send the funds to the user
            (bool success, ) = user.call{value: value}("");
            success; // Ignoring the success result for now
        }
    }

    /**
     * @dev Withdraws the specified amount.
     * @param amount The amount to withdraw.
     */
    function withdraw(uint256 amount) private {
        // Calculate the amount to send to the marketing wallet (20%)
        uint256 toMarketing = amount / 5;

        // Calculate the amount to send to the dividends wallet (80%)
        uint256 toDividends = amount - toMarketing;

        // Send funds to the marketing wallet
        sendFunds(marketingWallet, toMarketing);

        // Send funds to the dividends wallet
        sendFunds(address(dividends), toDividends);
    }

    /**
     * @dev If the dividend contract needs to be updated, we can close
     * this one, and let people claim for a month
     * After that is over, we can take the remaining funds and
     * use for the project
     */
    function closeDistribution() external onlyOwner {
        // Call the close function of the dividends contract
        dividends.close();
    }

    // This function allows the owner of the contract to collect funds
    // It can only be called if the contract has been closed for a month
    function collect() external onlyOwner {
        // Call the collect function of the dividends contract
        dividends.collect();
    }

    /**
     * @dev Sets the marketing wallet address.
     * @param _marketingWallet The new marketing wallet address.
     */
    function setMarketingWallet(address payable _marketingWallet) external {
        // Only the current marketing wallet address can call this function
        require(msg.sender == marketingWallet, "Not authorized");
        // Update the marketing wallet address
        marketingWallet = _marketingWallet;
    }
}
