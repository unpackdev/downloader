// SPDX-License-Identifier: MIT

/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&#BGGPPPPPP55PPPPPPPGGGB##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&BPP5555555PPPPPP55555555555PPGGB##&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&GP555555PGGBBBBBBBBGGPP555555555PPGGGB#@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@#P555555PBBBBBGGGGGGGGGBBGP555555555PPGGGG#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@B5555555G&#BBBBBBBBBBBBBBGGBP5555555555PGGGGB&@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&P555555P#GPPPPPPPPGGGGGGGGG#B55555555555PGGGGG&@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&#GGBBBBGBBGGGGGBBGGGGGPPPPPPG#555555555555GGGGG##BBBBB##&&@@@@@@
@@@@@@@@@@@@&BGPPPPPPPPGGGGGGGBBGP5PPPPPGGBB##PPPP55555555PGGGGBBGGGGGGGGGB#&@@@
@@@@@@@@@@@&P5GPY7:~JYJ7?J5PB&B5YJ7: .!???77J5GBBBBBGGPP55PGGGGBBGGGGGGGGGGGGB&@
@@@@@@@@@@@G^#Y?&&^PY7P#^ ^~#J5B?G@G.G5!7G&J  :!?JJ5BPGGGGBBGGG#BGGGGGGGGGGGGGB@
@@@@@@@@@@&^~@PPBP..7?5&: :!Y:@B5B#J :7??5@7    :?J5P55555PPGGB#BBGGGGGGGGBBB#&@
@@@@@@@@@@&:.&J:. ^~..5P  :55.@Y^:  ::.  ^@5  .~PGP55555555555PPB&@&&&&&&@@@@@@@
@@@@@@@@@@@G!?5   !YYYJ!7YG&#?5Y    7PYJJ5J^~?5GGG5555555555555PPG&@@@@@@@@@@@@@
@@@@@@@@@@@@#GPP5555PPGB##GPPBB5?7!~~~!7?JYPBBGP5555555555555555PPG&@@@@@@@@@@@@
@@@@@@@@@@@@@@&#BBBBBBGGP55555PGBBBBGGGGGGGGPP5PPGG55555555555555PPB@@@@@@@@@@@@
@@@@@@@@@@@@@&GPP5555555555555555PPGGBGGGGGGGGPPP55555555PP5555555PG&@@@@@@@@@@@
@@@@@@@@@@@@&P5555555555555555555555555555555555555PPPPPPPBG555555PP&@@@@@@@@@@@
@@@@@@@@@@@#PPPPP55555555555555555555555555PPPPPPPP55YYYPG5GP55555PP#@@@@@@@@@@@
@@@@@@@@@@@#G555PPPPPPPPPP5555PPPPPPPPPPPP555555555PGPYY5B55555555PP#@@@@@@@@@@@
@@@@@@@@@@@@@&#BGPPPPPPPPPPPPPP55555555555PPPGGGGGGBB5YPBP55555555PP&@@@@@@@@@@@
@@@@@@@@@@@@@@&BGBBPY5555G#BBGGGGGGGGGGBBBBGGPPGGGG55PBG555555555PPB@@@@@@@@@@@@
@@@@@@@@@@@@@BY5BY7!~~!7Y&GGPPPPPPPPGBBGP55G#&#G555GGG5555555555PPGB##&@@@@@@@@@
@@@@@@@@@@@@&PJ5B?~^~~~~7B#GPPPGGBBG5J!!7?5PP5Y5PGGP5555555555PPBG?J~~!7J5G#@@@@
@@@@@@@@@@@@@#PJYP5J7!~~~~?5PPPP5Y???J55P555PGGGP55555555555PGGBP??~~~~~^^^~7YB@
@@@@@@@@@@@@@@@#BP5PP555YYYYYYY55555555PPGGGGP55555555555PPGBGG5??~~~~~~~~~~~^~7
@@@@@@@@@@@@@@@@@@#GGGGGPPPPPPPPPPGGGGGGPP555555555555PGGGGPPPY?7~~~~~~~~~~~~~~~
@@@@@@@@@@@@@@@#GY?YPPPPPPPPPPPPPP555555555555555PPGGGGGPPPP5J?!~~~~~~~~~~~~~~~~
@@@@@@@@@@@@#P?~~^^?JGGGGPPP555555555555555PPPGGGGGGPP5555JJ?~:...::^~~~~~~~~~~~
@@@@@@@@@@#Y~::...^J7P555PPGGGGGGGGGGGGGGGGGGGPPP5555555J7!^.         .:^~~~~~~~
@@@@@@@@@5~.      .?^P555555555555PPPP5555555555555555J7~:               .^~~~~~
@@@@@@@&J:         ^7~5555555555555555555555555555YJ?!:.                   .^~~~
@@@@@@@Y.           ^!~J55555555555555555555555Y?7~:                         ^~~
@@@@@@#~              ^~~7JYY55555555555YYJ?7!~:.                             ^~
@@@@@@G.                .::^~~!!777!!!~~^:..                                   ^
@@@@@@P                      ........                                          .

Website : https://p3p3.wtf/
Twitter : https://twitter.com/p3p3
Telegram : https://t.me/p3p3entry

*/ 


import "./ERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

pragma solidity 0.8.20;

contract P3P3 is ERC20("Inverse Pepe", "P3P3"), Ownable {
    using Address for address payable;

    IUniswapV2Router02 public router;
    address public pair;

    bool private _liquidityMutex = false;
    bool private providingLiquidity = false;
    bool public tradingEnabled = false;

    uint256 private tokenLiquidityThreshold = 70_000 * 10 ** 18;
    uint256 public maxWalletLimit = 100_000 * 10 ** 18;

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

    Taxes public taxes = Taxes(2, 0, 0);
    Taxes public sellTaxes = Taxes(2, 0, 0);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) private isearlybuyer;

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
        _mint(msg.sender, 100_000_00 * 10 ** 18);

        IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  

        router = _router;
        exemptFee[address(this)] = true;
        exemptFee[msg.sender] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[devWallet] = true;
        exemptFee[0x0000000000000000000000000000000000000000] = true;

        _approve(address(this), address(router), type(uint256).max);
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
