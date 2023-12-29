// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable2Step.sol";
import "./SafeERC20.sol";
import "./IUniswapRouter02.sol";
import "./IFactory.sol";
import "./IUniswapV2Pair.sol";

contract AlienForm is ERC20, Ownable2Step {
    address payable public marketingFeeAddress;
    address payable public miscFeeAddress;
    address public immutable uniswapPair;
    address public bridgeAddress;

    address[] public botWallets;

    uint16 constant feeDenominator = 1000;
    uint16 constant lpDenominator = 1000;
    uint16 public maxFeeLimit = 300;

    uint16 public buyBurnFee;
    uint16 public buyLiquidityFee = 20;
    uint16 public buyMarketingFee = 40;
    uint16 public buyMiscFee = 30;

    uint16 public sellBurnFee;
    uint16 public sellLiquidityFee = 20;
    uint16 public sellMarketingFee = 40;
    uint16 public sellMiscFee = 30;

    uint16 public transferBurnFee;
    uint16 public transferLiquidityFee = 20;
    uint16 public transferMarketingFee = 40;
    uint16 public transferMiscFee = 30;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingFeeTokensToSwap;
    uint256 private _burnFeeTokens;
    uint256 private _miscFeeTokens;

    uint256 private lpTokens;
    uint256 public minLpBeforeSwapping;

    bool public tradingActive;
    bool private hasLiquidity;
    bool inSwapAndLiquify;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public botWallet;

    IUniswapRouter02 public immutable uniswapRouter;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyBridge() {
        require(
            msg.sender == bridgeAddress,
            "AlienForm: only bridge can trigger this method!"
        );
        _;
    }

    constructor() ERC20("Alien Form", "A4M")  {
        _transferOwnership(0x12926793D4c56AFEB8bC62Ede9842AE1F713a00b);   // LP wallet and owner address
        _mint(owner(), 1e11 * 10**decimals());

        marketingFeeAddress = payable(0xdB35482B43CB01dC62a237E532F85092c32B92b7);
        miscFeeAddress = payable(0x1f9c83D24d5d4df1e9D2f6673a4b216FD0b0122C);

        minLpBeforeSwapping = 10; // this means: 10 / 1000 = 1% of the liquidity pool is the threshold before swapping

        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Mainnet
        // address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Mainnet

        uniswapRouter = IUniswapRouter02(payable(routerAddress));

        uniswapPair = IFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingFeeAddress] = true;
        isExcludedFromFee[miscFeeAddress] = true;

        _approve(owner(), routerAddress, type(uint256).max);
        _setAutomatedMarketMakerPair(uniswapPair, true);
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }

    function mint(address to, uint amount) external onlyBridge() {
        _mint(to, amount);
    }

    function burn(address owner, uint amount) external onlyBridge() {
        _burn(owner, amount);
    }

    function increaseRouterAllowance(address routerAddress) external onlyOwner {
        _approve(address(this), routerAddress, type(uint256).max);
    }

    function migrateBridge(address newAddress) external onlyOwner {
        require(
            newAddress != address(0) && !automatedMarketMakerPairs[newAddress],
            "Can't set this address"
        );
        bridgeAddress = newAddress;
        isExcludedFromFee[newAddress] = true;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function addBotWallet(address wallet) external onlyOwner {
        require(!botWallet[wallet], "Wallet already added");
        botWallet[wallet] = true;
        botWallets.push(wallet);
    }

    function addBotWalletBulk(address[] memory wallets) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; ++i) {
            require(!botWallet[wallets[i]], "Wallet already added");
            botWallet[wallets[i]] = true;
            botWallets.push(wallets[i]);
        }
    }

    function getBotWallets() external view returns (address[] memory) {
        return botWallets;
    }

    function removeBotWallet(address wallet) external onlyOwner {
        require(botWallet[wallet], "Wallet not added");
        botWallet[wallet] = false;
        for (uint256 i = 0; i < botWallets.length; i++) {
            if (botWallets[i] == wallet) {
                botWallets[i] = botWallets[botWallets.length - 1];
                botWallets.pop();
                break;
            }
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function enableTrading(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
    }

    function updateMinLpBeforeSwapping(uint256 minLpBeforeSwapping_)
        external
        onlyOwner
    {
        minLpBeforeSwapping = minLpBeforeSwapping_;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(pair != uniswapPair, "The pair cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function updateMaxFeeLimit(uint16 _maxFeeLimit) external onlyOwner {
        maxFeeLimit = _maxFeeLimit;
    }

    function updateBuyFee(
        uint16 _buyBurnFee,
        uint16 _buyLiquidityFee,
        uint16 _buyMarketingFee,
        uint16 _buyMiscFee
    ) external onlyOwner {
        buyBurnFee = _buyBurnFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        buyMiscFee = _buyMiscFee;
        require(
            _buyBurnFee +
                _buyLiquidityFee +
                _buyMarketingFee +
                _buyMiscFee <=
                maxFeeLimit,
            "Must keep fees below maxFeeLimit"
        );
    }

    function updateSellFee(
        uint16 _sellBurnFee,
        uint16 _sellLiquidityFee,
        uint16 _sellMarketingFee,
        uint16 _sellMiscFee
    ) external onlyOwner {
        sellBurnFee = _sellBurnFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        sellMiscFee = _sellMiscFee;
        require(
            _sellBurnFee +
                _sellLiquidityFee +
                _sellMarketingFee +
                _sellMiscFee <=
                maxFeeLimit,
            "Must keep fees below maxFeeLimit"
        );
    }

    function updateTransferFee(
        uint16 _transferBurnFee,
        uint16 _transferLiquidityFee,
        uint16 _transferMarketingFee,
        uint16 _transferMiscFee
    ) external onlyOwner {
        transferBurnFee = _transferBurnFee;
        transferLiquidityFee = _transferLiquidityFee;
        transferMarketingFee = _transferMarketingFee;
        transferMiscFee = _transferMiscFee;
        require(
            _transferBurnFee +
                _transferLiquidityFee +
                _transferMarketingFee +
                _transferMiscFee <=
                maxFeeLimit,
            "Must keep fees below maxFeeLimit"
        );
    }

    function updateMarketingFeeAddress(address marketingFeeAddress_)
        external
        onlyOwner
    {
        require(marketingFeeAddress_ != address(0), "Can't set 0");
        marketingFeeAddress = payable(marketingFeeAddress_);
    }

    function updateMiscFeeAddress(address miscFeeAddress_)
        external
        onlyOwner
    {
        require(miscFeeAddress_ != address(0), "Can't set 0 address");
        miscFeeAddress = payable(miscFeeAddress_);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!tradingActive) {
            require(
                isExcludedFromFee[from] || isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }
        require(!botWallet[from] && !botWallet[to], "Bot wallet");
        checkLiquidity();

        if (
            hasLiquidity && !inSwapAndLiquify && automatedMarketMakerPairs[to]
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                contractTokenBalance >=
                (lpTokens * minLpBeforeSwapping) / lpDenominator
            ) takeFee(contractTokenBalance);
        }

        uint256 _burnFee;
        uint256 _liquidityFee;
        uint256 _marketingFee;
        uint256 _miscFee;

        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _burnFee = (amount * buyBurnFee) / feeDenominator;
                _liquidityFee = (amount * buyLiquidityFee) / feeDenominator;
                _marketingFee = (amount * buyMarketingFee) / feeDenominator;
                _miscFee = (amount * buyMiscFee) / feeDenominator;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _burnFee = (amount * sellBurnFee) / feeDenominator;
                _liquidityFee = (amount * sellLiquidityFee) / feeDenominator;
                _marketingFee = (amount * sellMarketingFee) / feeDenominator;
                _miscFee = (amount * sellMiscFee) / feeDenominator;
            }
            // Transfer
            else {
                _burnFee = (amount * transferBurnFee) / feeDenominator;
                _liquidityFee = (amount * transferLiquidityFee) / feeDenominator;
                _marketingFee = (amount * transferMarketingFee) / feeDenominator;
                _miscFee = (amount * transferMiscFee) / feeDenominator;
            }
        }

        uint256 _feeTotal = _burnFee +
            _liquidityFee +
            _marketingFee +
            _miscFee;
        uint256 _transferAmount = amount - _feeTotal;
        super._transfer(from, to, _transferAmount);

        if (_feeTotal > 0) {
            super._transfer(from, address(this), _feeTotal);
            _liquidityTokensToSwap += _liquidityFee;
            _marketingFeeTokensToSwap += _marketingFee;
            _burnFeeTokens += _burnFee;
            _miscFeeTokens += _miscFee;
        }
    }

    function takeFee(uint256 contractBalance) private lockTheSwap {
        uint256 totalTokensTaken = _liquidityTokensToSwap +
            _marketingFeeTokensToSwap +
            _burnFeeTokens +
            _miscFeeTokens;
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 initialETHBalance = address(this).balance;
        uint256 toSwap = tokensForLiquidity +
            _marketingFeeTokensToSwap +
            _miscFeeTokens;
        swapTokensForETH(toSwap);
        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForMarketing = (ethBalance * _marketingFeeTokensToSwap) /
            toSwap;
        uint256 ethForLiquidity = (ethBalance * tokensForLiquidity) / toSwap;
        uint256 ethForMisc = (ethBalance * _miscFeeTokens) / toSwap;

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            addLiquidity(_liquidityTokensToSwap - tokensForLiquidity, ethForLiquidity);
        }
        bool success;

        (success, ) = address(marketingFeeAddress).call{
            value: ethForMarketing,
            gas: 50000
        }("");
        (success, ) = address(miscFeeAddress).call{
            value: ethForMisc,
            gas: 50000
        }("");

        if (_burnFeeTokens > 0) {
            _burn(address(this), _burnFeeTokens);
        }

        _liquidityTokensToSwap = 0;
        _marketingFeeTokensToSwap = 0;
        _burnFeeTokens = 0;
        _miscFeeTokens = 0;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    receive() external payable {}

    function checkLiquidity() internal {
        (uint256 r1, uint256 r2, ) = IUniswapV2Pair(uniswapPair).getReserves();

        lpTokens = balanceOf(uniswapPair); // this is not a problem, since contract sell will get that unsynced balance as if we sold it, so we just get more ETH.
        hasLiquidity = r1 > 0 && r2 > 0 ? true : false;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(IERC20 tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            tokenAddress.balanceOf(address(this))
        );
    }
}