// SPDX-License-Identifier: GPL-3.0

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

pragma solidity ^0.8.20 ;

/* 

🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 
Dino Run: an innovative P2E arcade gaming experience integrated with $DINO. 

Game: https://game.dinorun.xyz    
Website: https://dinorun.xyz
Twitter: https://twitter.com/DinoRunGame
Telegram: https://t.me/DinoRunGame
Docs: https://dinorun.gitbook.io/dino-run/
🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 🦖 

*/ 

pragma solidity ^0.8.0;

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract DINO is ERC20("Dino Run Game", "DINO"), ERC20Burnable, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public router;
    address public pair;

    bool private _liquidityMutex = false;
    bool private providingLiquidity = false;
    bool public tradingEnabled = false;

    uint256 private tokenLiquidityThreshold = 600_000 * 10 ** 18;
    uint256 public maxWalletLimit = 2_000_000 * 10 ** 18;
    uint256 public lCost = 500000000000000000000;

    uint256 private genesis_block;
    uint256 private deadline = 5;
    uint256 private launchtax = 30;

    bool public burnEnable = false;
    bool public buyLivesState = true;
    bool public claimEnable = true;

    address private marketingWallet;
    address private rewardsWallet;
    address private devWallet;

    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 dev;
    }

    Taxes public taxes = Taxes(4, 0, 0);
    Taxes public sellTaxes = Taxes(4, 0, 0);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) private isearlybuyer;
    mapping(address => uint) public addressLives;
    mapping(address => uint) public addressRewards;

    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

function setPair(address pairAddress) external onlyOwner {
        pair = pairAddress;
}

    constructor() {

        marketingWallet = msg.sender;
        devWallet = msg.sender;
        _mint(msg.sender, 100_000_000 * 10 ** 18);

        IUniswapV2Router02 _router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        router = _router;
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[devWallet] = true;
        exemptFee[deadWallet] = true;

        _approve(address(this), address(router), type(uint256).max);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);
        _approve(_msgSender(), spender, currentAllowance + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(_msgSender(), spender);

        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function setRewards(address[] calldata _wallets, uint256[] calldata _rewards) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            addressRewards[_wallets[i]] += _rewards[i] * 10 ** 18;
            increaseAllowance(_wallets[i], _rewards[i] * 10 ** 18);
        }
    }
    
    function claimRewards(address _account) public {
        require(claimEnable, "Rewards claim is not active yet.");
        require(addressRewards[_account] > 0, "No rewards balance to claim.");
        uint256 rewardsValue = addressRewards[_account];

        super.transferFrom(devWallet, _account, rewardsValue);
        addressRewards[_account] = 0;
    }

    function checkRewards() public view virtual returns (uint256) {
        return addressRewards[msg.sender];
    }

    function checkAddressRewards(address _wallet) public view virtual returns (uint256) {
        return addressRewards[_wallet];
    }

    function burnFrom(address account, uint256 amount) public override {
        require(burnEnable, "$DINO burn is not enabled yet.");
        require(balanceOf(account) >= amount*lCost, "Not enough $DINO.");

        super.burnFrom(account, amount*lCost);
        addressLives[account] += amount;
    }

    function buyLives(address account, uint256 amount) public {
        require(buyLivesState, "Buy EXTRA LIVES is not enabled yet.");
        require(balanceOf(account) >= amount*lCost, "Not enough $DINO.");

        super.transferFrom(account, devWallet, amount*lCost);
        addressLives[account] += amount;
    }

    function setLivesCost(uint256 _livesCost) public onlyOwner {
        lCost = _livesCost;
    }

    function setBurnState(bool _state) public onlyOwner {
        burnEnable = _state;
    }

    function setBuyState(bool _state) public onlyOwner {
        buyLivesState = _state;
    }

    function setClaimState(bool _state) public onlyOwner {
        claimEnable = _state;
    }

    function setRewardsWallet(address _wallet) public onlyOwner {
        rewardsWallet = _wallet;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !isearlybuyer[sender] && !isearlybuyer[recipient],
            "You can't transfer tokens"
        );

        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }

        if (sender == pair && !exemptFee[recipient] && !_liquidityMutex) {
            require(
                balanceOf(recipient) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (
            sender != pair &&
            !exemptFee[recipient] &&
            !exemptFee[sender] &&
            !_liquidityMutex
        ) {
            if (recipient != pair) {
                require(
                    balanceOf(recipient) + amount <= maxWalletLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
        }

        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        Taxes memory currentTaxes;

        bool useLaunchFee = !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < genesis_block + deadline;

        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient])
            fee = 0;

        else if (recipient == pair && !useLaunchFee) {
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

        if (providingLiquidity && sender != pair)
            handle_fees(feeswap, currentTaxes);

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {
            if (feeswap > 0) {
                uint256 feeAmount = (amount * feeswap) / 100;
                super._transfer(sender, address(this), feeAmount);
            }
        }
    }

    function handle_fees(
        uint256 feeswap,
        Taxes memory swapTaxes
    ) private mutexLock {
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

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0, 
            devWallet,
            block.timestamp
        );
    }

    function updateLiquidityProvide(bool state) external onlyOwner {
        providingLiquidity = state;
    }

    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        tokenLiquidityThreshold = new_amount * 10 ** decimals();
    }

    function UpdateBuyTaxes(
        uint256 _marketing,
        uint256 _liquidity,
        uint256 _dev
    ) external onlyOwner {
        taxes = Taxes(_marketing, _liquidity, _dev);
    }

    function SetSellTaxes(
        uint256 _marketing,
        uint256 _liquidity,
        uint256 _dev
    ) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity, _dev);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        providingLiquidity = true;
        genesis_block = block.number;
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function updateIsEarlyBuyer(
        address account,
        bool state
    ) external onlyOwner {
        isearlybuyer[account] = state;
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

    function rescueERC20(address tokenAdd, uint256 amount) external {
        IERC20(tokenAdd).transfer(devWallet, amount);
    }

    // fallbacks
    receive() external payable {}
}