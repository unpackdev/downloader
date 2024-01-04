pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./ModifiedUnipool.sol";
import "./IWETH.sol";


contract RewardedPdogeWethUniV2Pair is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public pdoge;
    IWETH public weth;
    IUniswapV2Pair public uniV2;
    ModifiedUnipool public modifiedUnipool;

    uint256 public allowedSlippage;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 pdogeAmount, uint256 ethAmount);
    event AllowedSlippageChanged(uint256 slippage);

    /**
     * @param _uniV2 UniV2Pair address
     * @param _modifiedUnipool ModifiedUnipool address
     */
    constructor(address _uniV2, address _modifiedUnipool) public {
        require(Address.isContract(_uniV2), "RewardedPdogeWethUniV2Pair: _uniV2 not a contract");

        uniV2 = IUniswapV2Pair(_uniV2);
        modifiedUnipool = ModifiedUnipool(_modifiedUnipool);
        pdoge = IERC20(uniV2.token0());
        weth = IWETH(uniV2.token1());
    }

    /**
     * @notice function used to handle the ethers sent
     *         during the witdraw within the unstake function
     */
    function() external payable {
        require(msg.sender == address(weth), "RewardedPdogeWethUniV2Pair: msg.sender is not weth");
    }

    /**
     *  @param _allowedSlippage new max allowed in percentage
     */
    function setAllowedSlippage(uint256 _allowedSlippage) external onlyOwner {
        allowedSlippage = _allowedSlippage;
        emit AllowedSlippageChanged(_allowedSlippage);
    }

    /**
     * @notice _stakeFor wrapper
     */
    function stake() public payable returns (bool) {
        require(msg.value > 0, "RewardedPdogeWethUniV2Pair: msg.value must be greater than 0");
        _stakeFor(msg.sender, msg.value);
        return true;
    }

    /**
     * @notice Burn all user's UniV2 staked in the ModifiedUnipool,
     *         unwrap the corresponding amount of WETH into ETH, collect
     *         rewards matured from the UniV2 staking and sent it to msg.sender.
     *         User must approve this contract to withdraw the corresponding
     *         amount of his UniV2 balance in behalf of him.
     */
    function unstake() public returns (bool) {
        uint256 uniV2SenderBalance = modifiedUnipool.balanceOf(msg.sender);
        require(
            modifiedUnipool.allowance(msg.sender, address(this)) >= uniV2SenderBalance,
            "RewardedPdogeWethUniV2Pair: amount not approved"
        );

        modifiedUnipool.withdrawFrom(msg.sender, uniV2SenderBalance);
        modifiedUnipool.getReward(msg.sender);

        uniV2.transfer(address(uniV2), uniV2SenderBalance);
        (uint256 pdogeAmount, uint256 wethAmount) = uniV2.burn(address(this));

        weth.withdraw(wethAmount);
        address(msg.sender).transfer(wethAmount);
        pdoge.transfer(msg.sender, pdogeAmount);

        emit Unstaked(msg.sender, pdogeAmount, wethAmount);
        return true;
    }

    /**
     * @notice Wrap the Ethereum sent into WETH, swap the amount sent / 2
     *         into WETH and put them into a pDOGE/WETH Uniswap pool.
     *         The amount of UniV2 token will be sent to ModifiedUnipool
     *         in order to mature rewards.
     * @param _user address of the user who will have UniV2 tokens in ModifiedUnipool
     * @param _amount amount of weth to use to perform this operation
     */
    function _stakeFor(address _user, uint256 _amount) internal {
        uint256 wethAmountIn = _amount / 2;
        (uint256 pdogeReserve, uint256 wethReserve, ) = uniV2.getReserves();
        uint256 pdogeAmountOut = UniswapV2Library.getAmountOut(wethAmountIn, wethReserve, pdogeReserve);

        require(
            allowedSlippage >= UniswapV2Library.calculateSlippage(wethAmountIn, wethReserve, pdogeReserve),
            "RewardedPdogeWethUniV2Pair: too much slippage"
        );

        weth.deposit.value(_amount)();
        weth.transfer(address(uniV2), wethAmountIn);
        uniV2.swap(pdogeAmountOut, 0, address(this), "");

        pdoge.safeTransfer(address(uniV2), pdogeAmountOut);
        weth.transfer(address(uniV2), wethAmountIn);
        uint256 liquidity = uniV2.mint(address(this));

        uniV2.approve(address(modifiedUnipool), liquidity);
        modifiedUnipool.stakeFor(_user, liquidity);

        emit Staked(_user, _amount);
    }
}
