/**
-------------------------------------

0XGATR is an ERC20 token and dApp solution that gives any user the ability to add utility to any 
ERC20 token or ERC721 NFT by placing premium content behind a web3, token-gated URL.

The 0xGatr project also introduces a unique tokenomics model that adds value to its native token, 
0XGATR which is used to access the token-gating service and pay for gating fees.

Users who visit an 0xGatr URL are prompted to connect their Ethereum wallet to verify they hold 
the minimum quantity of a specified token, and are only given access to premium content if they do.

Only 11,000,000 0XGATR tokens will ever be minted. Users are rewarded for holding larger 
quantities of 0XGATR with reduced fees and premium functionalities.

A 3.5% gratuity is subtracted from buy and sell transactions to reward the development team.

-------------------------------------------
Interact with our dApp at https://0xgatr.io

https://0xgatr.com is also an official 0xGatr website
that we use for marketing and promotional purposes.

--------------------------------------------------
Please join our Official Social Media Channels at:
--------------------------------------------------
Facebook: https://facebook.com/0xgatr
Twitter (X): https://twitter.com/0xgatr
Telegram: https://t.me/oxgatr
YouTube: https://youtube.com/@0xgatr
Friend.tech: @0xgatr
--------------------------------------------------

DISCLOSURE: The 0XGATR ERC20 token is not a security, it is software in the form of a utility 
token that is required to access and use our token-gating dApp, located at 0xgatr.io. Your 
purchase of 0XGATR tokens is with the understanding that no regulatory authority has examined 
or approved the 0XGATR token for sale. The sale of 0XGATR tokens does not imply any elements 
of a contractual relationship or obligation on the part of 0xGatr.io to you, and there is no 
expectation of profit on your part from the business efforts of 0xGatr.

The 0XGATR ERC20 token is a Utility Token required to interact with the 0xGatr.io token-gating 
dApp. Unless expressly stated otherwise, the 0XGATR software is to be considered under 
development and in a "beta" mode. Every effort has been made to provide fully functional 
software at the time of sale, however, your purchase and use of 0XGATR tokens is with the 
understanding and agreement that no warranty regarding the software is expressed or implied, 
including fitness of use.

By purchasing 0XGATR tokens, you agree to indemnify, hold harmless, and defend 0xGatr.io, it's 
owner(s), developer(s), founder(s), programmer(s), employees(s), independent contractors(s), 
hosting service providers, social media platforms, promoters and influencers, from any and all 
liability associated with your purchase and use of the 0XGATR ERC20 token and dApp, even in 
instances of negligance.

Just as buying any other software does not entitle you to voting rights or a share in a 
companies revenue, holding 0XGATR does not provide you with any governance rights or entitle you 
to share in any revenue generated from the sale of 0XGATR or use of the token-gating service. 

By purchasing 0XGATR you indicate you understand and accept that crypto currencies are considered 
a highly volatile, speculative asset, and there is always the risk that the value of any crypto 
currency you purchase, including 0XGATR, could go to zero. Your purchase of 0XGATR tokens indicates 
you understand and accept the financial risk associated with purchasing crypto currencies. You are 
advised to contact an independent professional advisor before relying on, or making any commitments 
or transactions based on, any material published on our websites or shared on social media channels 
by 0xGatr or others.

You agree your purchase of 0XGATR and use of our dApp is further subject to our Privacy Policy and 
Terms of Use published on 0xgatr.io.
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC20.sol";
import "./TokenAccess.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";

/// @title 0XGATR Token
contract GatrToken is ERC20, TokenAccess {
    /// @notice UniswapV2 Router interface
    IUniswapV2Router02 public router;
    /// @notice 0XGATR/wETH pair address
    address public pair;
    /// @notice Fee swapping in progress?
    bool private swapping;
    /// @notice Trading enabled?
    bool public swapEnabled;
    /// @notice Contract balance requirement before swapping fees to ETH
    uint256 public swapThreshold;
    /// @notice 0XGATR marketing wallet address
    address public marketingWallet;
    /// @notice Buy tax (1 decimal)
    uint256 public buyTax;
    /// @notice Sell tax (1 decimal)
    uint256 public sellTax;
    /// @notice Seconds to wait between trades (buy/sell)
    uint256 public cooldownPeriod;

    /// @notice user => excluded from fee/tax? mapping
    mapping(address => bool) public excludedFromFees;
    /// @notice user => last trade (buy/sell) mapping
    mapping(address => uint256) public lastTradeTimestamp;

    /// @notice Event emitted when trading is enabled
    event SwapEnabled();
    /// @notice Event emitted when `swapThreshold` is updated
    event SwapThresholdSet(uint256 swapThreshold);
    /// @notice Event emitted when `buyTax` is updated
    event BuyTaxSet(uint256 buyTax);
    /// @notice Event emitted when `sellTax` is updated
    event SellTaxSet(uint256 sellTax);
    /// @notice Event emitted when `marketingWallet` is updated
    event MarketingWalletSet(address marketingWallet);
    /// @notice Event emitted when `cooldownPeriod` is updated
    event CooldownPeriodSet(uint256 cooldownPeriod);
    /// @notice Event emitted when address is excluded from fees/taxes
    event ExcludedFromFeesSet(address wallet, bool isExcluded);
    /// @notice Event emitted when locked/stuck ERC20 tokens are withdrawn from the contract
    event WithdrawLockedToken(address token, uint256 amount);
    /// @notice Event emitted when locked/stuck ETH is withdrawn from the contract
    event WithdrawLockedETH(uint256 amount);

    /// @param _router UniswapV2 router address
    /// @param _swapThreshold Contract balance requirement before swapping fees to ETH
    /// @param _marketingWallet 0XGATR marketing wallet address
    /// @param _buyTax Buy tax (1 decimal)
    /// @param _sellTax Sell tax (1 decimal)
    /// @param _cooldownPeriod Seconds to wait between trades (buy/sell)
    constructor(
        IUniswapV2Router02 _router,
        uint256 _swapThreshold,
        address _marketingWallet,
        uint256 _buyTax,
        uint256 _sellTax,
        uint256 _cooldownPeriod
    )
        ERC20("0XGATR", "0XGATR")
        onlyLimitedThreshold(_swapThreshold)
        onlyLimitedTax(_buyTax)
        onlyLimitedTax(_sellTax)
    {
        _mint(msg.sender, 11_000_000 ether);

        swapThreshold = _swapThreshold;
        marketingWallet = _marketingWallet;
        buyTax = _buyTax;
        sellTax = _sellTax;
        cooldownPeriod = _cooldownPeriod;

        excludedFromFees[msg.sender] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;

        router = _router;
        pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override onlyCooledDown(sender, recipient) {
        require(
            amount > 0,
            "GatrToken: Transfer amount must be greater than zero"
        );

        if (
            !excludedFromFees[sender] &&
            !excludedFromFees[recipient] &&
            !swapping
        ) {
            require(swapEnabled, "GatrToken: Trading not active yet");
        }

        uint256 fee;

        if (isViolator[sender]) {
            fee = amount;
        } else if (isBlacklisted[sender] || isBlacklisted[recipient]) {
            revert("GatrToken: User Blacklisted");
        } else if (
            swapping || excludedFromFees[sender] || excludedFromFees[recipient]
        ) {
            fee = 0;
        } else {
            if (recipient == pair) {
                fee = (amount * sellTax) / 1000;
                lastTradeTimestamp[sender] = block.timestamp;
            } else if (sender == pair) {
                fee = (amount * buyTax) / 1000;
                lastTradeTimestamp[recipient] = block.timestamp;
            } else fee = 0;
        }

        if (swapEnabled && !swapping && sender != pair && fee > 0)
            swapForFees();

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) super._transfer(sender, address(this), fee);
    }

    /// @notice Swap contract tokens to ETH if `swapThreshold` is reached
    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance >= swapThreshold || msg.sender == owner()) {
            uint256 initialBalance = address(this).balance;

            swapTokensForETH(contractBalance);

            uint256 deltaBalance = address(this).balance - initialBalance;

            if (deltaBalance > 0) {
                payable(marketingWallet).transfer(deltaBalance);
            }
        }
    }

    /// @notice Swap contract tokens to ETH
    /// @param tokenAmount Amount of tokens to swap
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice Enable trading
    /// @dev Callable by owner
    /// @dev Callable only once
    function launch() external onlyOwner {
        require(!swapEnabled, "Trading already active");
        swapEnabled = true;
        emit SwapEnabled();
    }

    /// @notice Set the `swapThreshold`
    /// @dev Callable by owner
    /// @dev `_swapThreshold` must be within limits
    /// @param _swapThreshold Contract balance requirement before swapping fees to ETH
    function setSwapThreshold(
        uint256 _swapThreshold
    ) external onlyOwner onlyLimitedThreshold(_swapThreshold) {
        swapThreshold = _swapThreshold;
        emit SwapThresholdSet(_swapThreshold);
    }

    /// @notice Set the `buyTax`
    /// @dev Callable by owner
    /// @dev `_buyTax` must be within limits
    /// @param _buyTax Buy tax (1 decimal)
    function setBuyTax(
        uint256 _buyTax
    ) external onlyOwner onlyLimitedTax(_buyTax) {
        buyTax = _buyTax;
        emit BuyTaxSet(_buyTax);
    }

    /// @notice Set the `sellTax`
    /// @dev Callable by owner
    /// @dev `_sellTax` must be within limits
    /// @param _sellTax Sell tax (1 decimal)
    function setSellTax(
        uint256 _sellTax
    ) external onlyOwner onlyLimitedTax(_sellTax) {
        sellTax = _sellTax;
        emit SellTaxSet(_sellTax);
    }

    /// @notice Set the `marketingWallet`
    /// @dev Callable by owner
    /// @param _marketingWallet 0XGATR marketing wallet address
    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        excludedFromFees[marketingWallet] = false;
        require(
            _marketingWallet != address(0),
            "GatrToken: Marketing Wallet cannot be zero address"
        );
        marketingWallet = _marketingWallet;
        excludedFromFees[marketingWallet] = true;
        emit MarketingWalletSet(_marketingWallet);
    }

    /// @notice Exclude/Include addresses from fees/taxes
    /// @dev Callable by owner
    /// @param wallet Address to exclude/include
    /// @param isExcluded Should exclude from fee/tax?
    function setExcludedFromFees(
        address wallet,
        bool isExcluded
    ) external onlyOwner {
        excludedFromFees[wallet] = isExcluded;
        emit ExcludedFromFeesSet(wallet, isExcluded);
    }

    /// @notice Set the `cooldownPeriod`
    /// @dev Callable by owner
    /// @param _cooldownPeriod Seconds to wait between trades (buy/sell)
    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyOwner {
        cooldownPeriod = _cooldownPeriod;
        emit CooldownPeriodSet(_cooldownPeriod);
    }

    /// @notice Manually swap the collected token fees/taxes to ETH
    /// @dev Callable by owner
    function swapFee() external onlyOwner {
        swapForFees();
    }

    /// @notice Withdraw locked/stuck ERC20 tokens
    /// @dev Callable by owner
    /// @param token Address of token to withdraw
    /// @param to Address to withdraw tokens to
    function withdrawLockedToken(address token, address to) external onlyOwner {
        require(
            token != address(this),
            "GatrToken: Can't withdraw 0XGATR tokens"
        );
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
        emit WithdrawLockedToken(token, balance);
    }

    /// @notice Withdraw locked/stuck ETH tokens
    /// @param to Address to withdraw ETH to
    function withdrawLockedEth(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
        emit WithdrawLockedETH(balance);
    }

    /// @notice Prevents reentrancy of `swapForFees()`
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    /// @notice Reverts if `swapThreshold` is outside limits
    modifier onlyLimitedThreshold(uint256 threshold) {
        require(threshold >= 11000 ether, "GatrToken: Threshold too low");
        require(threshold <= 1100000 ether, "GatrToken: Threshold too high");
        _;
    }

    /// @notice Reverts if `buyTax` or `sellTax` is outside limits
    modifier onlyLimitedTax(uint256 tax) {
        require(tax <= 200, "GatrToken: Tax too high");
        _;
    }

    /// @notice Reverts if cooldown is active
    modifier onlyCooledDown(address sender, address recipient) {
        if (recipient == pair || sender == pair) {
            require(
                (block.timestamp -
                    lastTradeTimestamp[
                        recipient == pair ? sender : recipient
                    ]) > cooldownPeriod,
                "GatrToken: Cooldown period active"
            );
        }
        _;
    }

    receive() external payable {}
}
