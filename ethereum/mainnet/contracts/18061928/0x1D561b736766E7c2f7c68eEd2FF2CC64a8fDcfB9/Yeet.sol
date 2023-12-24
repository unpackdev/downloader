/*                                                                                                                                                                          
                                                                                                                                                                                                                                                                                            |   |                                                  
░░    ░░ ░░░░░░░ ░░░░░░░ ░░░░░░░░     ░░░░░░      ░░░░░░  
 ▒▒  ▒▒  ▒▒      ▒▒         ▒▒             ▒▒    ▒▒  ▒▒▒▒ 
  ▒▒▒▒   ▒▒▒▒▒   ▒▒▒▒▒      ▒▒         ▒▒▒▒▒     ▒▒ ▒▒ ▒▒ 
   ▓▓    ▓▓      ▓▓         ▓▓        ▓▓         ▓▓▓▓  ▓▓ 
   ██    ███████ ███████    ██        ███████ ██  ██████  


It's time to go up only.

Website: https://yeetzejeet.com
Docs: https://docs.yeetzejeet.com
Telegram: https://t.me/YeetZeJeet
Twitter: https://twitter.com/YeetZeJeet

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

contract Yeet is IERC20, Ownable, ReentrancyGuard {
    string public name = "Yeet ze Jeet 2.0";
    string public symbol = "YEET";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromTax;

    bool public isTimeToYeet;
    bool public tradingOpen;
    bool public dynamicTaxOn = true;

    uint256 public baseSellTax = 10e12; // 10%
    uint256 public maxWallet;

    uint256 public floorYeetReserve;
    uint256 public floorEthReserve;
    uint256 public yeetCooldown = 24 hours;
    uint256 public lastYeetTimestamp;

    IUniswapV2Pair public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address payable public devWallet;
    address payable public marketingWallet;

    constructor() {
        totalSupply = 2_000_000e18;
        balanceOf[msg.sender] = totalSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );

        devWallet = payable(0x4783c30AEa0A1a467aD4662a2e19e742d00865D9);
        marketingWallet = payable(0xCc3E3C5044e461ECe6cC6D0577c146998D3eD37A);

        maxWallet = totalSupply / 50; // 2%

        isExcludedFromTax[owner()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[devWallet] = true;
        isExcludedFromTax[marketingWallet] = true;
        isExcludedFromTax[0xAbc1508B730c7Edd3811e31591f66616d71271Ea] = true; // Presale addr
        isExcludedFromTax[0x2c952eE289BbDB3aEbA329a4c41AE4C836bcc231] = true; // Wentokens addr
    }

    event Yeeted(
        uint256 prevYeetReserve,
        uint256 prevEthReserve,
        uint256 newYeetReserve,
        uint256 newEthReserve,
        uint256 prevPrice,
        uint256 newPrice,
        uint256 yeetBurned
    );
    event NewFloorSet(uint256 prevFloorPrice, uint256 newFloorPrice);
    event JeetDetected(address who, uint256 amountSold, uint256 taxPaid);

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

        if (isTimeToYeet && !isExcludedFromTax[from] && !isExcludedFromTax[to]) {
            if (from == address(uniswapV2Pair) && to != address(uniswapV2Router)) {
                require(balanceOf[to] + amount <= maxWallet, "Max wallet exceeded");
            }

            if (to == address(uniswapV2Pair) && from != address(this)) {
                taxAmount = getTaxAmount(amount);
                emit JeetDetected(from, amount, taxAmount);
            }

            if (taxAmount > 0) {
                balanceOf[address(this)] += taxAmount;
                emit Transfer(from, address(this), taxAmount);
            }

            uint256 contractTokenBalance = balanceOf[address(this)];
            bool canSwap = contractTokenBalance > 0;

            if (canSwap && !inSwap && to == address(uniswapV2Pair)) {
                swapAndBurn(contractTokenBalance);
            }
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount - taxAmount;
    }

    function swapAndBurn(uint256 tokenAmount) private lockTheSwap {
        (uint256 toSwap, uint256 toBurn) = getSwapAndBurnAmounts(tokenAmount);
        burnFrom(address(this), toBurn);
        swapTokensForEth(toSwap);
    }

    function burnFrom(address account, uint256 amount) private {
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        balanceOf[account] -= amount;
        balanceOf[deadAddress] += amount;
        emit Transfer(account, deadAddress, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );

        uint256 contractEth = address(this).balance;
        uint256 ethToDev = (contractEth * 70) / 100;
        uint256 ethToMarketing = contractEth - ethToDev;

        (bool success1,) = devWallet.call{value: ethToDev}("");
        require(success1);

        (bool success2,) = marketingWallet.call{value: ethToMarketing}("");
        require(success2);
    }

    function manualSwap() external {
        require(_msgSender() == devWallet, "Not authorized");
        uint256 tokenBalance = balanceOf[address(this)];
        if (tokenBalance > 0) {
            swapAndBurn(tokenBalance);
        }
    }

    /**
     * This function both sets new floor and maintains it by yeeting
     */
    function yeet() public nonReentrant {
        require(isTimeToYeet, "Yeet machine broke");
        require(getTimeLeft() == 0, "Yeet cooldown not met");

        // Sync first in case pair is disbalanced
        uniswapV2Pair.sync();

        // Get $yeet price
        uint256 currentPrice = getCurrentPrice();
        uint256 floorPrice = getFloorPrice();

        // Get LP reserves
        (uint112 prevYeetReserve, uint112 prevEthReserve) = getReserves();

        // If we dump below floor, proceed with yeeting
        if (floorPrice > currentPrice) {
            // Burn $yeet from lp
            uint256 toBurn = getBurnAmount();
            burnFrom(address(uniswapV2Pair), toBurn);

            // Sync again
            uniswapV2Pair.sync();

            // Get reserves after burn
            (uint112 newYeetReserve, uint112 newEthReserve) = getReserves();

            // Let everyone know
            emit Yeeted(
                prevYeetReserve, prevEthReserve, newYeetReserve, newEthReserve, currentPrice, getCurrentPrice(), toBurn
            );
        } else {
            // Set new floor
            floorYeetReserve = prevYeetReserve;
            floorEthReserve = prevEthReserve;

            // Let everyone know
            emit NewFloorSet(floorPrice, currentPrice);
        }

        // Reset cooldown
        lastYeetTimestamp = block.timestamp;
    }

    /**
     * VIEW FUNCS
     */

    /**
     * Returns amount to swap and burn
     * When dynamic tax is on, we want to keep swap amount at fixed
     * 5% rate and burn the rest
     */
    function getSwapAndBurnAmounts(uint256 tokenAmount) public view returns (uint256, uint256) {
        uint256 sellTax = getSellTax();
        uint256 toSwap;
        uint256 toBurn;
        if (sellTax > baseSellTax) {
            toSwap = ((tokenAmount * ((baseSellTax * 1e12) / sellTax)) / 1e12) / 2;
            toBurn = tokenAmount - toSwap;
        } else {
            toSwap = tokenAmount / 2;
            toBurn = tokenAmount - toSwap;
        }
        return (toSwap, toBurn);
    }

    /**
     * A helper function that returns exact amount to tax
     */
    function getTaxAmount(uint256 amount) public view returns (uint256 taxAmount) {
        uint256 sellTax = getSellTax();
        return (amount * sellTax) / 100e12;
    }

    /**
     * Dynamic tax mechanism
     * If price dumps further than 10% under floor sell tax will be equal
     * to exact % of the dump percent value
     * Returns percent value of tax (divide by 1e12)
     */
    function getSellTax() public view returns (uint256 actualSellTax) {
        if (dynamicTaxOn) {
            uint256 dumpAmount = getDumpAmount();
            if (dumpAmount > baseSellTax) {
                return dumpAmount;
            } else {
                return baseSellTax;
            }
        } else {
            return baseSellTax;
        }
    }

    /**
     * Returns the percent value of how much price is down below floor
     * for use in dynamic tax calculation. Divide output by 1e12
     */
    function getDumpAmount() public view returns (uint256 pumpAmount) {
        uint256 currentPrice = getCurrentPrice();
        uint256 floorPrice = getFloorPrice();
        if (floorPrice > currentPrice) {
            return (100 * 1e12) - (((currentPrice * 1e12) / floorPrice) * 100);
        } else {
            return 0;
        }
    }

    /**
     * Returns the percent difference between current price and floor
     * Purely for front end purposes. Divide output by 1e12
     */
    function getPumpAmount() public view returns (uint256 pumpAmount) {
        uint256 currentPrice = getCurrentPrice();
        uint256 floorPrice = getFloorPrice();
        if (floorPrice > currentPrice) {
            return (((floorPrice * 1e12) / currentPrice) - 1e12) * 100;
        } else {
            return 0;
        }
    }

    /**
     * Returns exact amount of YEET to burn to bring price back up
     */
    function getBurnAmount() public view returns (uint256 toBurn) {
        (uint112 currentYeetReserve, uint112 currentEthReserve) = getReserves();
        uint256 targetYeetReserve = (currentEthReserve * 1e12) / getFloorPrice();
        if (currentYeetReserve > targetYeetReserve) {
            return currentYeetReserve - targetYeetReserve;
        } else {
            return 0;
        }
    }

    /**
     * Returns floor price in ETH
     * Divide the output by 1e12 and multiply by ETH price to get USD price
     */
    function getFloorPrice() public view returns (uint256 floorPrice) {
        return (floorEthReserve * 1e12) / floorYeetReserve;
    }

    /**
     * Returns current price in ETH
     * Divide the output by 1e12 and multiply by ETH price to get USD price
     */
    function getCurrentPrice() public view returns (uint256 currentPrice) {
        (uint112 currentYeetReserve, uint112 currentEthReserve) = getReserves();
        return (currentEthReserve * 1e12) / currentYeetReserve;
    }

    /**
     * Debug only, this should always be equal to floor price
     * Divide the output by 1e12 and multiply by ETH price to get USD price
     */
    function getPriceAfterYeet() public view returns (uint256 currentPrice) {
        (uint112 currentYeetReserve, uint112 currentEthReserve) = getReserves();
        uint256 toBurn = getBurnAmount();
        return (currentEthReserve * 1e12) / (currentYeetReserve - toBurn);
    }

    /**
     * Returns time left in seconds until yeet button becomes available
     */
    function getTimeLeft() public view returns (uint256 timeLeft) {
        if (lastYeetTimestamp + yeetCooldown > block.timestamp) {
            return (lastYeetTimestamp + yeetCooldown) - block.timestamp;
        } else {
            return 0;
        }
    }

    /**
     *  This function always returns currentYeetReserve at first slot of the tuple,
     *  which is not always the case with calling pair for reserves
     */
    function getReserves() public view returns (uint112, uint112) {
        (uint112 reserve0, uint112 reserve1,) = uniswapV2Pair.getReserves();
        bool isYeetReserve = address(this) < uniswapV2Router.WETH();
        uint112 yeetReserve = isYeetReserve ? reserve0 : reserve1;
        uint112 ethReserve = !isYeetReserve ? reserve0 : reserve1;
        return (yeetReserve, ethReserve);
    }

    /**
     * OWNER FUNCS
     */

    /**
     * Sets initial floor price at launch
     */
    function setFloorPrice() public onlyOwner {
        (uint112 yeetReserve, uint112 ethReserve) = getReserves();
        floorYeetReserve = yeetReserve;
        floorEthReserve = ethReserve;
        if (lastYeetTimestamp == 0) {
            lastYeetTimestamp = block.timestamp;
        }
    }

    /**
     * Emergency only, toggles dynamic tax system on/off
     */
    function toggleDynamicTax() public onlyOwner {
        dynamicTaxOn = !dynamicTaxOn;
    }

    /**
     * Start the protocol
     */
    function timeToYeet(bool isIt) public onlyOwner {
        isTimeToYeet = isIt;
    }

    /**
     * Add liquidity
     */
    function addLiquidity(uint256 tokenAmount) public payable onlyOwner {
        this.transferFrom(owner(), address(this), tokenAmount);
        this.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
        setFloorPrice();
    }

    /**
     * Open trading on Uniswap
     * Can never be disabled once called
     */
    function openTrading() public payable onlyOwner {
        tradingOpen = true;
    }

    function setDevWallet(address _devWallet) public onlyOwner {
        devWallet = payable(_devWallet);
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        maxWallet = _maxWallet;
    }

    function addExcludedFromTax(address toBeExcluded) public payable onlyOwner {
        isExcludedFromTax[toBeExcluded] = true;
    }

    function removeExcludedFromTax(address toBeRemoved) public payable onlyOwner {
        isExcludedFromTax[toBeRemoved] = false;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
