// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library CastMath {
    function int256Cast(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "unsafe int256 cast");
        return b;
    }

    function uint256Cast(int256 a) internal pure returns (uint256) {
        require(a >= 0, "unsafe uint256 cast");
        return uint256(a);
    }
}

interface UniSwap {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract DividendContract {

    uint256 constant internal MAGNITUDE = 2**128;
    uint256 internal magnifiedDividendPerShare;
                                                                         
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => uint256) public holderBalance;
 
    uint256 public totalDividends;
    uint256 public totalBloxDividendsDistributed;

    event DividendsDistributed(address indexed from, uint256 amount);
    event DividendWithdrawn(address indexed to, uint256 amount);

    function withdrawnDividendOf(address user) external view returns(uint256) {
        return withdrawnDividends[user];
    }

    function dividendOf(address user) public view returns(uint256) {
        return accumulativeDividendOf(user) - withdrawnDividends[user];
    }

    function accumulativeDividendOf(address user) public view returns(uint256) {
        int256 magnifiedBalance = CastMath.int256Cast(magnifiedDividendPerShare * holderBalance[user]);
        uint256 correctedBalance = CastMath.uint256Cast(magnifiedBalance + magnifiedDividendCorrections[user]);
        return correctedBalance / MAGNITUDE;
    }

    function _distributeDividends(uint amount) internal {
        require(totalDividends > 0, "Nobody to distribute to");
        magnifiedDividendPerShare += (amount * MAGNITUDE) / totalDividends;
        emit DividendsDistributed(msg.sender, amount);
        totalBloxDividendsDistributed += amount;
    }

    function _withdrawDividendOfUser(address payable user) internal  {
        uint256 _withdrawableDividend = dividendOf(user);
        if (_withdrawableDividend == 0) {return;} 
        withdrawnDividends[user] += _withdrawableDividend;
        (bool success,) = user.call{value: _withdrawableDividend}("");
        if (!success) {
            withdrawnDividends[user] -= _withdrawableDividend; //undo withdraw
            return;
        }
        emit DividendWithdrawn(user, _withdrawableDividend);
   } 

  function _updateBalance(address user, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[user];
    holderBalance[user] = newBalance;
    if (newBalance > currentBalance) {
        uint256 increaseAmount = newBalance - currentBalance;
        magnifiedDividendCorrections[user] -= CastMath.int256Cast(magnifiedDividendPerShare * increaseAmount);
        totalDividends += increaseAmount;
    } else if (newBalance < currentBalance) {
        uint256 reduceAmount = currentBalance - newBalance;
        magnifiedDividendCorrections[user] += CastMath.int256Cast(magnifiedDividendPerShare * reduceAmount);
        totalDividends -= reduceAmount;
    }
   }

    function _updateAccountBalance(address payable user, uint256 newBalance) internal {
        _updateBalance(user, newBalance);
    	_withdrawDividendOfUser(user); // auto-send dividends when balance changes (i.e. unstake)
    }
}

contract BloxStaking is DividendContract, ReentrancyGuard {

    IERC20 public immutable bloxToken;
    UniSwap private immutable dexRouter;

    mapping (address => uint256) public holderUnlockTime;
    mapping(address => uint256) internal stakeBlock;
    uint256 public immutable lockDuration;

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);

    constructor(address token, uint256 lockDays) { 
        bloxToken = IERC20(token);
        lockDuration = lockDays * 1 days;
        dexRouter = UniSwap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    receive() external payable {
        revShare();
    }

    function stakeBlox(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount cannot be 0");
        if(holderUnlockTime[msg.sender] == 0) {
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        stakeBlock[msg.sender] = block.timestamp;
        uint256 userAmount = holderBalance[msg.sender];
        uint256 balanceBefore = bloxToken.balanceOf(address(this));
        bloxToken.transferFrom(address(msg.sender), address(this), amount);
        uint256 bought = bloxToken.balanceOf(address(this)) - balanceBefore;
        _updateAccountBalance(payable(msg.sender), userAmount + bought);
        emit Stake(msg.sender, amount);
    }

    function revShare() public payable {
        require(msg.value > 0, "No ETH sent");
        _distributeDividends(msg.value);
    }

    function unstakeBlox(uint256 amount) public nonReentrant  {
        require(amount > 0, "Cannot withdraw 0 tokens");
        require(holderUnlockTime[msg.sender] <= block.timestamp, "Cannot withdraw yet");
        require(stakeBlock[msg.sender] + 1 hours < block.timestamp, "Attack block");
        uint256 userDividends = holderBalance[msg.sender];
        require(amount <= userDividends, "Not enough Blox tokens");
        _updateAccountBalance(payable(msg.sender), userDividends - amount);
        // Everything unstaked = reset stamp to 0, else extend lock
        holderUnlockTime[msg.sender] = userDividends == amount ? 0 : block.timestamp + lockDuration;
        bool success = bloxToken.transfer(address(msg.sender), amount);
        require(success, "Transfer of Blox failed");
        emit Unstake(msg.sender, amount);
    }

    function unstakeAllBlox() external   { 
        uint256 totalTokens = holderBalance[msg.sender];
        unstakeBlox(totalTokens);
    }

    function buyBloxTokens(uint256 weiAmount, uint256 minOut) internal returns(uint256) {
        uint256 initialBalance = bloxToken.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(bloxToken);
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: weiAmount}(
            minOut,
            path,
            address(this),
            block.timestamp
        );
        return bloxToken.balanceOf(address(this)) - initialBalance;
    }

    function claimRewards() external nonReentrant { 
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function compoundBlox(uint256 minOutput) external nonReentrant {
        // Check how much dividend ETH we have
        uint256 accountBalance = holderBalance[msg.sender];
        uint256 dividendETH = dividendOf(msg.sender);
        require(dividendETH > 0, "Nothing to compound");
        withdrawnDividends[msg.sender] += dividendETH; // We use the ETH for buyback
        emit DividendWithdrawn(msg.sender, dividendETH);
        // Use dividend ETH to buy Blox tokens
        uint BloxBought = buyBloxTokens(dividendETH, minOutput); 
        // Update balance
        _updateAccountBalance(payable(msg.sender), accountBalance + BloxBought);
    }

    function getCompoundTokensForWallet(address wallet) external view returns(uint256) {
        uint256 dividendETH = dividendOf(wallet);
        require(dividendETH > 0, "Nothing to compound");
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(bloxToken);
        // Get the tokens we can buy for the given ETH
        return dexRouter.getAmountsOut(dividendETH, path)[1]; 
    }

 }