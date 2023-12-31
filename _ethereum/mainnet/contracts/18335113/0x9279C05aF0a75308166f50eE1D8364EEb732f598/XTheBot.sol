//                     ░░░░░░░░░░░░░░░░
//               ░░░░░░░░░░░░░░░░░░░░░░░░░░
//            ░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░
//        ░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░
//      ░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░
//     ▒▒▒░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░
//    ▒▒▒▒▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░      Website:    https://www.xthebot.com/
//   ▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░     Telegram:   https://t.me/XTheBotTeam
//   ▒▒▒▒██▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░     X:          https://x.com/XTheBotTeam
//   ▒▒▒▒███▓▓▓██     ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒     ▒▒▒▒▒▒▒▒░░░░     Medium:     https://medium.com/@XTheBotTeam
//   ▒▒▒▒████▓▓███        ▒▒▒▒▒▒▒▒▒▒        ▒▒▒▒▒▒▒▒▒░░░░     Email:      business@xthebot.com
//   ░▒▒▒▒████▓▓▓██                        ▒▒▒▒▒▒▒▒▒░░░░░
//    ▒▒▒▒██████▓▓▓█████              ▓▓▓▒▒▒▒▒▒▒▒▒▒▒░░░░
//     ▒▒▒▒███████▓▓▓▓                  ▓▓▓▓▓▓▓▓▓▓▓░░░░
//      ▒▒▒▒▒████████       █▓▓███       ▓▓▓▓▓▓▓▓░░░░░
//        ▒▒▒▒▒█████    █▓▓▓▓▓▓▓▓▓▓███    ▓▓▓▓▓▒▒▒▒▒
//          ▒▒▒▒▒▒███████████▓▓▓▓▓▓▓▓▓▓██▓▓▓▒▒▒▒▒▒
//            ░▒▒▒▒▒▒▒██████████████████▒▒▒▒▒▒▒░
//                ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
//                      ▒▒▒▒▒▒▒▒▒▒▒▒▒▒

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

contract XTheBot is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;
    address payable public marketing;

    bool swapping;
    bool public tradingEnabled;

    uint256 public tax = 300; // 3%

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => mapping(uint256 => bool)) public isTransferred;
    mapping(address => bool) public isBlacklist;

    uint256 public blacklistTime;
    uint256 public swapTaxesAtAmount;

    constructor(
        address _routerAddress,
        address payable _marketing
    ) ERC20("XTheBot", "XTB") {
        IUniswapRouter _router = IUniswapRouter(_routerAddress);

        marketing = _marketing;

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;

        pair = _pair;

        swapTaxesAtAmount = 50_000 * 10 ** 18;

        _approve(address(this), address(_router), type(uint256).max);

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[_marketing] = true;
        isExcludedFromFees[address(this)] = true;

        _mint(owner(), 10_000_000 * (10 ** 18));
    }

    function setSwapTaxesAtAmount(uint256 amount) public onlyOwner {
        swapTaxesAtAmount = amount;
    }

    function fiveMinutesBlacklist(
        address[] calldata _addresses
    ) external onlyOwner {
        require(
            block.timestamp <= blacklistTime || !tradingEnabled,
            "Can only add blacklist in the first 5 minutes"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            isBlacklist[_addresses[i]] = true;
        }
    }

    function removeBlacklist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isBlacklist[_addresses[i]] = false;
        }
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setMarketingAddress(
        address payable _newMarketing
    ) external onlyOwner {
        require(_newMarketing != address(0), "Can not set zero address");
        marketing = _newMarketing;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        blacklistTime = block.timestamp + 300;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklist[from] && !isBlacklist[to], "In blacklist");

        if (!isExcludedFromFees[from] && !isExcludedFromFees[to] && !swapping) {
            require(tradingEnabled, "Trading is not enabled");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (tx.origin == from || tx.origin == to) {
            require(!isTransferred[tx.origin][block.number], "Robot!");
            isTransferred[tx.origin][block.number] = true;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTaxesAtAmount;
        address pairAddress = pair;

        if (
            canSwap &&
            !swapping &&
            tradingEnabled &&
            (to == pairAddress) &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;

            _swapAndSend();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if ((to != pairAddress) && (from != pairAddress)) takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            feeAmt = (amount * tax) / 10000;
            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }

        super._transfer(from, to, amount);
    }

    function _swapAndSend() internal {
        _swapTokensForETH(swapTaxesAtAmount);
        uint256 currentbalance = address(this).balance;
        (marketing).transfer(currentbalance);
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
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

    receive() external payable {}
}
