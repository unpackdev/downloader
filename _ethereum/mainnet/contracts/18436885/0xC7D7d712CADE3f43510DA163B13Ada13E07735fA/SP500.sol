//SPDX-License-Identifier: MIT

/***********************************************************
 *          TradFi tools for the DeFi market.              *
 *                          WAGMI                          *
 *      WEB: https://www.sp500erc.com/                     *                             *
 * TELEGRAM: https://t.me/SandPoop500                      *
 *  TWITTER: https://twitter.com/SandPoop500               *                               *
 **********************************************************/

pragma solidity 0.8.20;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";


interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


contract SP500 is ERC20, Ownable {
    
mapping(address => bool) private excluded;
mapping (address => Stake) public stakes;

address public devWallet = 0x73686ef0E8D6cD2Af8D46eeF11125c4891Cc601d;
address public revenueShareWallet = 0x3EB9Cb9B33941e2930597b07E1dA73F5F8Bf7E17;
address public stakeWallet = 0x5F533F7121e6CF642777986C2796ef2Ab1a1D74E;

DexRouter public immutable uniswapRouter;
address public immutable pairAddress;

bool public swapAndLiquifyEnabled = true;
bool public isSwapping = false;
bool public tradingEnabled = false;

uint256 public constant _totalSupply = 500_000_000 * 1e18;
uint256 public maxWallet = (_totalSupply * 3) / 100;

uint256 public minStake = 5000000 * 10**18; //1% of total supply
uint256 public maxStake = 15000000 * 10**18; //3% of total supply
uint256 public minHoldingPercentage = 1250000; //0.25% of total supply
uint256 public minStakeTime = 1 days;
uint256 public swapThreshold = (_totalSupply * 5) / 1000;

struct taxes {
    uint256 devRevTax;
}

taxes public transferTax = taxes(0);
taxes public buyTax = taxes(20);
taxes public sellTax = taxes(25);


struct Stake {
        uint256 amount;
        uint256 unlockTime;
        bool locked;
}


event TokenStaked (address indexed account, uint256 amount, uint256 unlockTime);
event UnstakeToken (address indexed staker);



    constructor() ERC20("SP500", "SP500") {


       uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       pairAddress = DexFactory(uniswapRouter.factory()).createPair(address(this),uniswapRouter.WETH());

        excluded[msg.sender] = true;
        excluded[address(devWallet)] = true;
        excluded[address(revenueShareWallet)] = true;
        excluded[address(stakeWallet)] = true;
        excluded[address(uniswapRouter)] = true;
        excluded[address(this)] = true;       
        
        _mint(msg.sender, _totalSupply);
 
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
    }

    function swapToETH(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function tokenSwap() internal {
        isSwapping = true;
        uint256 taxAmount = balanceOf(address(this)); 
        if (taxAmount == 0) {
            return;
        }
        swapToETH(balanceOf(address(this)));
        uint256 devShareAmount = (address(this).balance)/2;
        uint256 revShareAmount = (address(this).balance)/2;
        payable(devWallet).transfer(devShareAmount);
        payable(revenueShareWallet).transfer(revShareAmount);
        isSwapping = false;
        
    }

    function handleTax(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (excluded[from] || excluded[to]) {
            return amount;
        }

        uint256 totalTax = transferTax.devRevTax;

        if (to == pairAddress) {
            totalTax = sellTax.devRevTax;
        } else if (from == pairAddress) {
            totalTax = buyTax.devRevTax;
        }

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (amount * totalTax) / 100;
            super._transfer(from, address(this), tax);
        }
        return (amount - tax);
    }

    function _transfer(
    address from,
    address to,
    uint256 amount
) internal virtual override {
    require(from != address(0), "transfer from address zero");
    require(to != address(0), "transfer to address zero");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (!excluded[from] && !excluded[to] && to != address(0) && to != address(this) && to != pairAddress) {
        require(balanceOf(to) + amount <= maxWallet, "Exceeds maximum wallet amount");
    }

    uint256 amountToTransfer = handleTax(from, to, amount);

    bool canSwap = balanceOf(address(this)) >= swapThreshold;
    if (!excluded[from] && !excluded[to]) {
        require(tradingEnabled, "Trading not active");
        if (pairAddress == to && swapAndLiquifyEnabled && canSwap && !isSwapping) {
            tokenSwap();
        }
    }

    super._transfer(from, to, amountToTransfer);
}

    function updateBuyTax(uint256 _devRevTax) external onlyOwner {
        buyTax.devRevTax = _devRevTax;
        require(_devRevTax <= 30);
       
    }

    function updateSellTax(uint256 _devRevTax) external onlyOwner {
        sellTax.devRevTax = _devRevTax;
        require(_devRevTax <= 40);
       
    }

    function updateSwapThreshold(uint256 amount) external onlyOwner {
        swapThreshold = (_totalSupply * amount) / 1000;
        
    }

    function updateMaxWallet(uint256 amount) external onlyOwner {
        maxWallet = (_totalSupply * amount) / 100;
    }

    function excludeWallet(address wallet, bool value) external onlyOwner {
        excluded[wallet] = value;
    }

    function stakeTokens(uint256 amount, uint256 lockDurationInDays) external {

    require(!stakes[msg.sender].locked, "You are already staked");

    amount = amount * 10**18;

    require(amount >= minStake && amount <= maxStake, "min stake = 1% total supply, max stake = 3% total supply");
    require(lockDurationInDays >= 1);

    uint256 lockDurationInSeconds = lockDurationInDays * 1 days;
    
    uint256 unlockTime = block.timestamp + lockDurationInSeconds;

    super._transfer(msg.sender, stakeWallet, amount); 

    stakes[msg.sender] = Stake(amount, unlockTime, true);

    emit TokenStaked(msg.sender, amount, unlockTime);
    
}

    function unstakeTokens() external {
    Stake storage userStake = stakes[msg.sender];
    require(userStake.amount > 0, "You have nothing staked");
    require(block.timestamp >= userStake.unlockTime, "Tokens still locked");

    userStake.locked = false;

    super._transfer(stakeWallet, msg.sender, stakes[msg.sender].amount); 

    delete stakes[msg.sender];

    emit UnstakeToken(msg.sender);
}

    function unstakeTokens(address wallet) external onlyOwner {

    Stake storage userStake = stakes[wallet];
    require(userStake.amount > 0, "You have nothing staked");
    userStake.locked = false;
    super._transfer(stakeWallet, wallet, stakes[wallet].amount); 
    delete stakes[wallet];
    emit UnstakeToken(wallet);

}

    function updateStakingConditions(uint256 _minStake, uint256 _maxStake, uint256 _minHoldingPercentage, uint256 _minStakeTime) external onlyOwner {

    minStake = _minStake;
    maxStake = _maxStake;
    minHoldingPercentage = _minHoldingPercentage;
    minStakeTime = _minStakeTime * 1 days;

}

    function withdrawStuckTokens() external {
    require(msg.sender == devWallet);
    uint256 balance = IERC20(address(this)).balanceOf(address(this));
    IERC20(address(this)).transfer(msg.sender, balance);
    payable(msg.sender).transfer(address(this).balance);
}

    function withdrawStuckEth() external {
    require(msg.sender == devWallet);
    bool success;
    (success,) = address(msg.sender).call{value: address(this).balance}("");
}

receive() external payable {}

}


