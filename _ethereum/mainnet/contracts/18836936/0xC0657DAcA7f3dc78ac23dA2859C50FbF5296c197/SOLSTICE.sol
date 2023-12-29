/***
**** Tune in to spaces with Elon Musk & Cathie Wood talking about AI, Space, 
**** Bitcoin, Crypto, Winter Solstice and so much more.
**** Spaces:   https://x.com/CathieDWood/status/1737890686425350576?s=20
**** -------------------------------------------
**** Telegram: https://t.me/solsticecoin
**** Website:  https://www.solstice-coin.com
**** Twitter:  https://twitter.com/solsticecoin
**** -------------------------------------------
***/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract SOLSTICE is ERC20("Solstice Coin", "SOLSTICE"), Ownable {
    IUniswapV2Factory public constant UNISWAP_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    uint256 constant TOTAL_SUPPLY = 690420000 ether;
    uint256 public tradingOpenedOnTime;

    bool private swapping;

    address public taxWallet;
    address public devWallet;
    address public team1Wallet;
    address public team2Wallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public fetchFees = true;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;
    uint256 public tokenSwapThreshold;
    uint256 public maxTaxSell;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public taxedTokens;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    event EnabledTrading(bool tradingActive);
    event RemovedLimits();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event MaxTransactionExclusion(address _address, bool excluded);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() {
        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);

        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = 6904200 * 10**decimals();
        maxSellAmount = 6904200 * 10**decimals();
        maxWalletAmount = 6904200 * 10**decimals();
        tokenSwapThreshold = (totalSupply() * 60) / 10000;
        maxTaxSell = 6904200 * 10**decimals();

        devWallet = msg.sender;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}

    function setWallets(
        address _taxAddress,
        address _team1Address,
        address _team2Address,
        address _devAddress
    ) public {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        require(
            (_taxAddress != address(0) ||
                _team1Address != address(0) ||
                _team2Address != address(0) ||
                _devAddress != address(0)),
            "Invalid Wallet"
        );
        devWallet = _devAddress;
        team1Wallet = _team1Address;
        team2Wallet = _team2Address;
        taxWallet = _taxAddress;
    }

    function setNewMaxTaxSell(uint256 _maxSell) public {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        require(
            _maxSell >= tokenSwapThreshold,
            "ERROR: Max cant be lower than threshold"
        );
        maxTaxSell = _maxSell;
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: Cannot set max buy amount lower than 0.1%"
        );
        maxBuyAmount = newNum;
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: Cannot set max sell amount lower than 0.1%"
        );
        maxSellAmount = newNum;
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "ERROR: Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum;
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "ERROR: Swap amount cannot be lower than 0.001% total supply."
        );

        tokenSwapThreshold = newAmount;
    }

    function removeLimits() external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded)
        private
    {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function openTrading() public onlyOwner {
        require(
            tradingOpenedOnTime == 0,
            "ERROR: Token state is already live !"
        );
        tradingOpenedOnTime = block.timestamp;
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading(tradingActive);
    }

    function getFees() internal {
        require(tradingOpenedOnTime > 0, "Trading not live");
        uint256 currentBlock = block.timestamp;
        uint256 taxTimeTier1 = tradingOpenedOnTime + (5 * 60);
        uint256 taxTimeTier2 = taxTimeTier1 + (5 * 60);
        uint256 limitsTime = tradingOpenedOnTime + (30 * 60);
        if (currentBlock <= taxTimeTier1) {
            buyTotalFees = 20;
            sellTotalFees = 30;
        } else if (currentBlock <= taxTimeTier2) {
            buyTotalFees = 10;
            sellTotalFees = 20;
        } else {
            buyTotalFees = 2;
            sellTotalFees = 2;
        }
        if (currentBlock >= limitsTime) {
            fetchFees = false;
            maxBuyAmount = 20712600 * 10**decimals();
            maxSellAmount = 20712600 * 10**decimals();
            maxWalletAmount = 20712600 * 10**decimals();            
        }
    }

    function disableDynamicTaxes() public {
        require(fetchFees, "taxes already disabled");
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        fetchFees = false;
    }

    function setNewFees(uint256 newBuyFees, uint256 newSellFees) external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        buyTotalFees = newBuyFees;
        sellTotalFees = newSellFees;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] ||
                            _isExcludedMaxTransactionAmount[to],
                        "ERROR: Trading is not active."
                    );
                    require(from == owner(), "ERROR: Trading is not enabled");
                }

                if (
                    from == UNISWAP_V2_PAIR &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyAmount,
                        "ERROR: Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: Cannot Exceed max wallet"
                    );
                } else if (
                    to == UNISWAP_V2_PAIR &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxSellAmount,
                        "ERROR: Sell transfer amount exceeds the max sell."
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: Cannot Exceed max wallet"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= tokenSwapThreshold;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !(from == UNISWAP_V2_PAIR) &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (fetchFees) {
                getFees();
            }

            // Sell
            if (to == UNISWAP_V2_PAIR && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                taxedTokens += fees;
            }
            // Buy
            else if (from == UNISWAP_V2_PAIR && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                taxedTokens += fees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        // make the swap
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensToSwap = taxedTokens;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > maxTaxSell) {
            contractBalance = maxTaxSell;
        }

        bool successDev;
        bool successTeam1;
        bool successTeam2;
        bool successTax;

        swapTokensForEth(contractBalance);
        uint256 ethBalance = address(this).balance;
        uint256 teamBalance = (ethBalance * 30) / 100;
        uint256 devBalance = (ethBalance * 10) / 100;
        uint256 taxBalance = ethBalance -
            teamBalance -
            teamBalance -
            devBalance;
        if (devBalance > 0) {
            (successDev, ) = address(devWallet).call{value: devBalance}("");
        }
        if (teamBalance > 0) {
            (successTeam1, ) = address(team1Wallet).call{value: teamBalance}(
                ""
            );
            (successTeam2, ) = address(team2Wallet).call{value: teamBalance}(
                ""
            );
        }
        if (taxBalance > 0) {
            (successTax, ) = address(taxWallet).call{value: taxBalance}("");
        }
    }

    function manualSwap(uint256 amount) public {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        require(amount <= balanceOf(address(this)));
        bool successDev;
        bool successTeam1;
        bool successTeam2;
        bool successTax;
        swapTokensForEth(amount);
        uint256 ethBalance = address(this).balance;
        uint256 teamBalance = (ethBalance * 30) / 100;
        uint256 devBalance = (ethBalance * 10) / 100;
        uint256 taxBalance = ethBalance -
            teamBalance -
            teamBalance -
            devBalance;
        if (devBalance > 0) {
            (successDev, ) = address(devWallet).call{value: devBalance}("");
        }
        if (teamBalance > 0) {
            (successTeam1, ) = address(team1Wallet).call{value: teamBalance}(
                ""
            );
            (successTeam2, ) = address(team2Wallet).call{value: teamBalance}(
                ""
            );
        }
        if (taxBalance > 0) {
            (successTax, ) = address(taxWallet).call{value: taxBalance}("");
        }
    }

    function withdrawStuckToken(address _token) external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(msg.sender, balance);
    }

    function withdrawStuckEth() external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "ERROR: Not authorized"
        );
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "ERROR: failed to withdraw funds");
    }
}
