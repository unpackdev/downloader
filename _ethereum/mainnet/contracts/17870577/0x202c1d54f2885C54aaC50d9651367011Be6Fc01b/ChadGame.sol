// SPDX-License-Identifier: MIT

//    █▀▀ █░█ ▄▀█ █▀▄   █▀▀ ▄▀█ █▀▄▀█ █▀▀
//    █▄▄ █▀█ █▀█ █▄▀   █▄█ █▀█ █░▀░█ ██▄

//    BE THE LAST CHAD STANDING!

//    If you buy $GAME and no one else buys after you within 60 minutes, you win ETH from taxes!

//    To play, simply buy $GAME on Uniswap.
//    You must buy at least 1000 GAME to play, or it will revert.

//    The prize pool increases with each sell.
//    9% sell tax is split this way: 3% to the current winner, 3% reserved for future rounds, 3% to the dev.

//    The prize will be sent to you automatically (see line 171).

//    Good luck!

//   +----------------------------------------------------------------------+
//   |  THERE IS NO OFFICIAL WEBSITE OR TWITTER!                            |
//   |  KEEP UPDATED BY JOINING THE TELEGRAM GROUP: https://t.me/ChadGame   |
//   +----------------------------------------------------------------------+

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

contract ChadGame is IERC20, Ownable, ReentrancyGuard {
    string public name = "Chad Game";
    string public symbol = "GAME";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromTax;

    bool public tradingOpen;
    uint256 public sellTax = 9;

    uint256 public minBuy = 1_000e18;
    uint256 public maxWallet = 10_000e18;
    uint256 public lastBuyTimestamp = block.timestamp;
    uint256 public cooldown = 1 hours;
    address public currentWinner;

    IUniswapV2Pair public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address payable public immutable devWallet;

    constructor() {
        totalSupply = 1_000_000e18;
        balanceOf[msg.sender] = totalSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );

        devWallet = payable(0x3FCdF3bd5Bd701268834E577E9218C38E789A92E);

        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[devWallet] = true;
    }

    event WinnerReset(address indexed winner, address indexed prevWinner, uint256 timeLeft);
    event PrizePoolIncreased(uint256 amountIncreased);
    event WinnerPaid(address indexed winner, uint256 amount);

    bool inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingOpen) {
            require(isExcludedFromTax[from], "Can't trade yet");
        }

        uint256 taxAmount = 0;

        if (!isExcludedFromTax[from] && !isExcludedFromTax[to]) {
            if (from == address(uniswapV2Pair) && to != address(uniswapV2Router)) {
                require(amount >= minBuy, "minBuy not satisfied");
                require(balanceOf[to] + amount <= maxWallet, "maxWallet exceeded");

                uint256 timeLeft = getTimeLeft();

                if (timeLeft > 0) {
                    // Get previous winner
                    address prevWinner = currentWinner;

                    // Set buyer as current winner
                    currentWinner = to;

                    // Reset timestamp
                    lastBuyTimestamp = block.timestamp;

                    // Emit event
                    emit WinnerReset(currentWinner, prevWinner, timeLeft);
                } else {
                    // Get winner
                    address winner = currentWinner;

                    // Set buyer as next winner
                    currentWinner = to;

                    // Reset timestamp
                    lastBuyTimestamp = block.timestamp;

                    // Get win amount
                    uint256 winAmount = getWinAmount();

                    // Send eth to winner. Only half will be sent.
                    // Other half is reserved for future rounds
                    (bool success,) = winner.call{value: winAmount}("");

                    // Fallback in case winner is unable to receive ether.
                    // This would only happen if winner is a contract that
                    // does not have a payable fallback function.
                    // In that case winner should contact dev to claim their prize
                    if (!success) {
                        (bool success2,) = devWallet.call{value: winAmount}("");
                        require(success2);
                    }

                    // Emit event
                    emit WinnerPaid(winner, winAmount);
                    emit WinnerReset(currentWinner, winner, timeLeft);
                }
            }

            // Charge 9% tax on sell
            if (to == address(uniswapV2Pair) && from != address(this)) {
                taxAmount = (amount * sellTax) / 100;
            }

            if (taxAmount > 0) {
                balanceOf[address(this)] += taxAmount;
                emit Transfer(from, address(this), taxAmount);
            }

            uint256 contractTokenBalance = balanceOf[address(this)];
            bool canSwap = contractTokenBalance > 0;

            if (canSwap && !inSwap && to == address(uniswapV2Pair)) {
                _swapTokensForEth(min(amount, contractTokenBalance));
            }
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount - taxAmount;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );

        uint256 ethAmount = address(this).balance - balanceBefore;
        uint256 ethToDev = ethAmount / 3;
        uint256 ethToPool = ethAmount - ethToDev;

        (bool success,) = devWallet.call{value: ethToDev}("");
        require(success);

        emit PrizePoolIncreased(ethToPool);
    }

    function manualSwap() external {
        require(_msgSender() == devWallet, "Not authorized");
        uint256 tokenBalance = balanceOf[address(this)];
        if (tokenBalance > 0) {
            _swapTokensForEth(tokenBalance);
        }
    }

    function getWinAmount() public view returns (uint256) {
        return address(this).balance / 2;
    }

    function getTimeLeft() public view returns (uint256) {
        if (lastBuyTimestamp + cooldown > block.timestamp) {
            return (lastBuyTimestamp + cooldown) - block.timestamp;
        } else {
            return 0;
        }
    }

    // Set minimum buy amount
    function setMinBuy(uint256 _minBuy) external onlyOwner {
        minBuy = _minBuy;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet > 10_000e18, "Max wallet must be greater than 10,000");
        maxWallet = _maxWallet;
    }

    // Set cooldown needed to win
    function setCooldown(uint256 _cooldown) external onlyOwner {
        require(_cooldown > 60, "Cooldown must be greater than 60 seconds");
        cooldown = _cooldown;
    }

    // Emergency only
    function withdrawEth() external onlyOwner {
        (bool success,) = devWallet.call{value: address(this).balance}("");
        require(success);
    }

    function openTrading() external payable onlyOwner {
        tradingOpen = true;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
