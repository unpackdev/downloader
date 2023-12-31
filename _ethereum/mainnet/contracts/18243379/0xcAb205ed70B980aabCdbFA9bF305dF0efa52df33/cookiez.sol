// SPDX-License-Identifier: MIT

/*

🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪

$COOKIEZ CLICKER REIMAGINED FOR WEB3 - We are reinventing the iconic, and incredibly addictive browser game that so many internet users know and love.

Telegram: https://t.me/CookiezClicker
Twitter: https://x.com/COOKIEZErc
Documentation: https://cookiez-clicker.gitbook.io/untitled/
Website: https://cookiez.io
Game: https://cookiezgame.xyz/

🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪🍪

*/ 


import "./ERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

pragma solidity 0.8.20;

contract COOKIEZ is ERC20("Cookiez Clicker", "COOKIEZ"), Ownable {
    using Address for address payable;

    IUniswapV2Router02 public router;
    address public pair;

    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    bool private _liquidityMutex = false;
    bool private providingLiquidity = false;
    bool public tradingEnabled = false;
    bool public claimEnable = true;

    uint256 public claimTime = 86400;
    uint256 private tokenLiquidityThreshold = 60_000 * 10 ** 18;
    uint256 public maxWalletLimit = 100_000 * 10 ** 18;
    uint256 public maxClaim = 5_000 * 10 ** 18;
    uint256 public minBalance = 10_000 * 10 ** 18;

    uint256 private genesis_block;
    uint256 private deadline = 6;
    uint256 private launchtax = 25;
    address private marketingWallet;
    address private devWallet;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 dev;
    }

    Taxes public taxes = Taxes(3, 0, 0);
    Taxes public sellTaxes = Taxes(3, 0, 0);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) private isearlybuyer;
    mapping(address => bool) public controller;
    mapping(address => uint256) public claimDate;

    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

    constructor() {
        marketingWallet = msg.sender;
        devWallet = msg.sender;
        controller[msg.sender] = true;

        _mint(msg.sender, 100_000_00 * 10 ** 18);

        IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
       );

        router = _router;
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[devWallet] = true;
        exemptFee[0x0000000000000000000000000000000000000000] = true;

        _approve(address(this), address(router), type(uint256).max);
    }

    // CLAIM COOKIEZ
    function claimRewards(address _account, uint256 _amount) public {
        require(claimEnable, "Cookiez claim is not active yet.");
        require(balanceOf(_account) > minBalance, "Only COOKIEZ holders can claim.");

        uint256 claimRecord = claimDate[_account];
        require(block.timestamp - claimRecord > claimTime, "Please wait 24hs between claims.");

        if (_amount > maxClaim) {
            _amount = maxClaim;
            }

        super.transferFrom(devWallet, _account, _amount);
        claimDate[_account] = block.timestamp;
    }

    // SET MAX CLAIM
    function setMaxClaim(uint256 _amount) public {
        require(controller[msg.sender], "Not a controller.");
        maxClaim = _amount;
    }

    // MIN BALANCE TO CLAIM
    function setMinBalance(uint256 _amount) public {
        require(controller[msg.sender], "Not a controller.");
        minBalance = _amount;
    }

    // CLAIM STATE
    function setClaimState(bool _state) public {
        require(controller[msg.sender], "Not a controller.");
        claimEnable = _state;
    }

    // ADD CONTROLLERS
    function setController(address _account) public {
        require(controller[msg.sender], "Not a controller.");
        controller[_account] = true;
    }

    function setPair(address pairAddress) external onlyOwner {
        pair = pairAddress;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        _approve(_msgSender(), spender, currentAllowance + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);

        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance < zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be > zero");
        require(!isearlybuyer[sender] && !isearlybuyer[recipient], "You can't xfer tokens");

        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading isnt enabled");
        }

        if (sender == pair && !exemptFee[recipient] && !_liquidityMutex) {
            require(balanceOf(recipient) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
        }

        if (sender != pair && !exemptFee[recipient] && !exemptFee[sender] && !_liquidityMutex) {
            if (recipient != pair) {
                require(balanceOf(recipient) + amount <= maxWalletLimit, "You are exceeding maxWalletLimit");
            }
        }

        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        Taxes memory currentTaxes;

        bool useLaunchFee = !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < genesis_block + deadline;

        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient]) {
            fee = 0;
        } else if (recipient == pair && !useLaunchFee) {
            feeswap = sellTaxes.liquidity + sellTaxes.marketing + sellTaxes.dev;
            feesum = feeswap;
            currentTaxes = sellTaxes;
        } else if (!useLaunchFee) {
            feeswap = taxes.liquidity + taxes.marketing + taxes.dev;
            feesum = feeswap;
            currentTaxes = taxes;
        } else if (useLaunchFee) {
            feeswap = launchtax;
            feesum = launchtax;
        }

        fee = (amount * feesum) / 100;

        if (providingLiquidity && sender != pair) {
            handle_fees(feeswap, currentTaxes);
        }

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {
            if (feeswap > 0) {
                uint256 feeAmount = (amount * feeswap) / 100;
                super._transfer(sender, address(this), feeAmount);
            }
        }
    }

    function handle_fees(uint256 feeswap, Taxes memory swapTaxes) private mutexLock {
        if (feeswap == 0) {
            return;
        }

        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            if (tokenLiquidityThreshold > 1) {
                contractBalance = tokenLiquidityThreshold;
            }

            uint256 denominator = feeswap * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance *
                swapTaxes.liquidity) / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance /
                (denominator - swapTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * swapTaxes.liquidity;

            if (ethToAddLiquidityWith > 0) {
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }

            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if (marketingAmt > 0) {
                payable(marketingWallet).sendValue(marketingAmt);
            }

            uint256 devAmt = unitBalance * 2 * swapTaxes.dev;
            if (devAmt > 0) {
                payable(devWallet).sendValue(devAmt);
            }
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH { value: ethAmount } (address(this), tokenAmount, 0, 0, devWallet, block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateLiquidityProvide(bool state) external onlyOwner {
        providingLiquidity = state;
    }

    function UpdateBuyTaxes(uint256 _marketing, uint256 _liquidity, uint256 _dev) external onlyOwner {
        taxes = Taxes(_marketing, _liquidity, _dev);
    }

    function SetSellTaxes(uint256 _marketing, uint256 _liquidity, uint256 _dev) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity, _dev);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading enabled");
        tradingEnabled = true;
        providingLiquidity = true;
        genesis_block = block.number;
    }

    function updateExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }

    function updateMaxWalletLimit(uint256 maxWallet) external onlyOwner {
        maxWalletLimit = maxWallet * 10 ** decimals();
    }

    function rescueETH(uint256 weiAmount) external {
        payable(devWallet).transfer(weiAmount);
    }

    receive() external payable {}
}
