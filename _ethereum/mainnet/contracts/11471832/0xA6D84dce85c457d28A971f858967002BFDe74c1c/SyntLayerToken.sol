// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
//Import abstractions
import "./Balancer.sol";
import "./ReflectToken.sol";
import "./TransferHelper.sol";
//Import uniswap interfaces
import "./IUniswapFactory.sol";
import "./IUniswapV2Pair.sol";

contract SyntLayer is REFLECTBase {
    using SafeMath for uint256;

    event Rebalance(uint256 tokenBurnt);
    event RewardLiquidityProviders(uint256 liquidityRewards);

    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapV2Pair = address(0);
    address payable public treasury;

    mapping(address => bool) public unlockedAddr;

    IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);
    IUniswapV2Pair iuniswapV2Pair = IUniswapV2Pair(uniswapV2Pair);
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    uint256 public minRebalanceAmount;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval;
    uint256 public liqAddBalance = 0;

    uint256 constant INFINITE_ALLOWANCE = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;


    uint256 public lpUnlocked;
    bool public locked;
    //Use CHI to save on gas on rebalance
    bool public useCHI = false;
    bool approved = false;
    bool doAddLiq = true;

    /// @notice Liq Add Cut fee at 1% initially
    uint256 public LIQFEE = 100;
    /// @notice LiqLock is set at 0.2%
    uint256 public LIQLOCK = 20;
    /// @notice Rebalance amount is 2.5%
    uint256 public REBALCUT = 250;
    /// @notice Caller cut is at 2%
    uint256 public CALLCUT = 200;
    /// @notice Fee BASE
    uint256 constant public BASE = 10000;

    IBalancer balancer;

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 *
                           msg.data.length;
        if(useCHI){
            if(chi.balanceOf(address(this)) > 0) {
                chi.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);
            }
            else {
                chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
            }
        }
    }

    constructor(address balancerAddr) public {
        lastRebalance = block.timestamp;
        rebalanceInterval = 1 seconds;
        lpUnlocked = block.timestamp + 90 days;
        minRebalanceAmount = 20 ether;
        treasury = msg.sender;
        balancer = IBalancer(balancerAddr);
        locked = true;
        unlockedAddr[msg.sender] = true;
        unlockedAddr[balancerAddr] = true;
        isFeeless[address(this)] = true;
        isFeeless[balancerAddr] = true;
        isFeeless[msg.sender] = true;
    }

    function setBalancer(address newBalancer) public onlyOwner {
        balancer = IBalancer(newBalancer);
        isFeeless[newBalancer] = true;
        unlockedAddr[newBalancer] = true;
    }

    /* Fee getters */
    function getLiqAddBudget(uint256 amount) public view returns (uint256) {
        return amount.mul(LIQFEE).div(BASE);
    }

    function getLiqLockBudget(uint256 amount) public view returns (uint256) {
        return amount.mul(LIQLOCK).div(BASE);
    }


    function getRebalanceCut(uint256 amount) public view returns (uint256) {
        return amount.mul(REBALCUT).div(BASE);
    }

    function getCallerCut(uint256 amount) public view returns (uint256) {
        return amount.mul(CALLCUT).div(BASE);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        //First remove feelet set for current owner
        toggleFeeless(owner());
        //Remove unlock flag for current owner
        toggleUnlockable(owner());
        //Add feeless for new owner
        toggleFeeless(newOwner);
        //Add unlocked for new owner
        toggleUnlockable(newOwner);
        //Transfer ownersip
        super.transferOwnership(newOwner);
    }

    // transfer function with liq add and liq rewards
    function _transfer(address from, address to, uint256 amount) internal override  {
        // calculate liquidity lock amount
        // dont transfer burn from this contract
        // or can never lock full lockable amount
        if(locked && !unlockedAddr[from])
            revert("Locked until end of distribution");

        if (!isFeeless[from] && !isFeeless[to] && !locked) {
            uint256 liquidityLockAmount = getLiqLockBudget(amount);
            uint256 LiqPoolAddition = getLiqAddBudget(amount);
            //Transfer to liq add amount
            super._transfer(from, address(this), LiqPoolAddition);
            liqAddBalance = liqAddBalance.add(LiqPoolAddition);
            //Transfer to liq lock amount
            super._transfer(from, address(this), liquidityLockAmount);
            //Amount that is ending up after liq rewards and liq budget
            uint256 totalsub = LiqPoolAddition.add(liquidityLockAmount);
            super._transfer(from, to, amount.sub(totalsub));
        }
        else {
            super._transfer(from, to, amount);
        }
    }

    // receive eth from uniswap swap
    receive () external payable {}

    function initPair() public {
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        //Set uniswap pair interface
        iuniswapV2Pair = IUniswapV2Pair(uniswapV2Pair);
    }

    function setUniPair(address pair) public onlyOwner {
        uniswapV2Pair = pair;
        iuniswapV2Pair = IUniswapV2Pair(uniswapV2Pair);
    }

    function unlock() public onlyOwner {
        locked = false;
    }

    function setTreasury(address treasuryN) public onlyOwner {
        treasury = payable(treasuryN);
        balancer.setTreasury(treasuryN);
    }

    /* Fee setters */
    function setLiqFee(uint newFee) public onlyOwner {
        LIQFEE = newFee;
    }
    function setLiquidityLockCut(uint256 newFee) public onlyOwner {
        LIQLOCK = newFee;
    }

    function setRebalanceCut(uint256 newFee) public onlyOwner {
        REBALCUT = newFee;
    }
    function setCallerRewardCut(uint256 newFee) public onlyOwner {
        CALLCUT = newFee;
    }

    function toggleCHI() public onlyOwner {
        useCHI = !useCHI;
    }

    function setRebalanceInterval(uint256 _interval) public onlyOwner {
        rebalanceInterval = _interval;
    }

    function _transferLP(address dest,uint256 amount) internal{
        iuniswapV2Pair.transfer(dest, amount);
    }

    function unlockLPPartial(uint256 amount) public onlyOwner {
        require(block.timestamp > lpUnlocked, "Not unlocked yet");
        _transferLP(msg.sender,amount);
    }

    function unlockLP() public onlyOwner {
        require(block.timestamp > lpUnlocked, "Not unlocked yet");
        uint256 amount = iuniswapV2Pair.balanceOf(address(this));
        _transferLP(msg.sender, amount);
    }

    function toggleFeeless(address _addr) public onlyOwner {
        isFeeless[_addr] = !isFeeless[_addr];
    }

    function toggleUnlockable(address _addr) public onlyOwner {
        unlockedAddr[_addr] = !unlockedAddr[_addr];
    }

    function setMinRebalanceAmount(uint256 amount_) public onlyOwner {
        minRebalanceAmount = amount_;
    }

    function rebalanceable() public view returns (bool) {
        return block.timestamp > lastRebalance.add(rebalanceInterval);
    }

    function hasMinRebalanceBalance(address addr) public view returns (bool) {
        return balanceOf(addr) >= minRebalanceAmount;
    }

    function _rewardLiquidityProviders(uint256 liquidityRewards) private {
        super._transfer(address(this), uniswapV2Pair, liquidityRewards);
        iuniswapV2Pair.sync();
        emit RewardLiquidityProviders(liquidityRewards);
    }

    function remLiquidity(uint256 lpAmount) private returns(uint ETHAmount) {
        iuniswapV2Pair.approve(uniswapV2Router, lpAmount);
        (ETHAmount) = router
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                lpAmount,
                0,
                0,
                address(balancer),
                block.timestamp
            );
    }

    function ApproveInf(address tokenT,address spender) internal{
        TransferHelper.safeApprove(tokenT,spender,INFINITE_ALLOWANCE);
    }

    function toggleAddLiq() public onlyOwner {
        doAddLiq = !doAddLiq;
    }

    function rebalanceLiquidity() public discountCHI {
        require(hasMinRebalanceBalance(msg.sender), "!hasMinRebalanceBalance");
        require(rebalanceable(), '!rebalanceable');
        lastRebalance = block.timestamp;

        if(!approved) {
            ApproveInf(address(this),uniswapV2Router);
            ApproveInf(uniswapV2Pair,uniswapV2Router);
            approved = true;
        }
        //Approve CHI incase its enabled
        if(useCHI) ApproveInf(address(chi),address(chi));
        // lockable supply is the token balance of this contract minus the liqaddbalance
        if(lockableSupply() > 0)
            _rewardLiquidityProviders(lockableSupply());

        uint256 amountToRemove = getRebalanceCut(iuniswapV2Pair.balanceOf(address(this)));
        // Sell half of balance tokens to eth and add liq
        if(balanceOf(address(this)) >= liqAddBalance && liqAddBalance > 0 && doAddLiq) {
            //Send tokens to balancer
            super._transfer(address(this),address(balancer),liqAddBalance);
            require(balancer.AddLiq(),"!AddLiq");
            liqAddBalance = 0;
        }
        // needed in case contract already owns eth
        remLiquidity(amountToRemove);
        uint _locked = balancer.rebalance(msg.sender);
        //Sync after changes
        iuniswapV2Pair.sync();
        emit Rebalance(_locked);
    }

    // returns token amount
    function lockableSupply() public view returns (uint256) {
        return balanceOf(address(this)) > 0 ? balanceOf(address(this)).sub(liqAddBalance,"underflow on lockableSupply") : 0;
    }

    // returns token amount
    function lockedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = iuniswapV2Pair.totalSupply();
        uint256 lpBalance = lockedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _lockedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _lockedSupply;
    }

    // returns token amount
    function burnedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = iuniswapV2Pair.totalSupply();
        uint256 lpBalance = burnedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _burnedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _burnedSupply;
    }

    // returns LP amount, not token amount
    function burnableLiquidity() public view returns (uint256) {
        return iuniswapV2Pair.balanceOf(address(this));
    }

    // returns LP amount, not token amount
    function burnedLiquidity() public view returns (uint256) {
        return iuniswapV2Pair.balanceOf(address(0));
    }

    // returns LP amount, not token amount
    function lockedLiquidity() public view returns (uint256) {
        return burnableLiquidity().add(burnedLiquidity());
    }
}