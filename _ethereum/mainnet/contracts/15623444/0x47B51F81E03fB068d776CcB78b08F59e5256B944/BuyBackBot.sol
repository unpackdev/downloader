// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IStakingPool.sol";
import "./ISwapRouter.sol";

/**
              :~7J5PGGGGGGGGGGGGGGG^  JGGGGGGG^ :GGGGPPY?!^.                            
          .!5B&DIDDIDDIDDIDDIDDIDID~  PDIDDIDD^ ^DIDDIDDIDD#GJ^                         
        :Y#DIDDIDDIDDIDDIDDIDDIDDID~  PDIDDIDD^ ^DIDDIDDIDDIDIDG7                       
       ?&DIDDIDID&BPYJJJJJJBDIDDIDD~  !JJJJJJJ: .JJJY5G#DIDDIDDIDG^                     
      YDIDDIDIDP!:         PDIDDIDD~                   .^J#DIDDIDD&~                    
     ?DIDDIDD&!            PDIDDIDD~  JGPPPPGG^           .5DIDDIDD#.                   
    .BDIDDIDD!             PDIDDIDD~  PDIDDIDD~             PDIDDIDD?                   
    ^&DIDDIDB.             PDIDDIDD~  PDIDDIDD~             7DIDDIDD5                   
    :&DIDDID#.             PDIDDIDD~  PDIDDIDD~             ?DIDDIDD5                   
     GDIDDIDDJ             PDIDDIDD~  PDIDDIDD~            .BDIDDIDD7                   
     ~DIDDIDIDY.           !???????:  PDIDDIDD~           ~BDIDDIDDP                    
      7DIDDIDID&5!^.                  PDIDDIDD~      .:~?GDIDDIDIDG.                    
       ^GDIDDIDDIDD#BGGGGGGGGGGGGGG^  PDIDDIDDBGGGGGB#&DIDDIDDID&J.                     
         !P&DIDDIDDIDDIDDIDDIDDIDID~  PDIDDIDDIDDIDDIDDIDDIDID#J:                       
           :7YG#DIDDIDDIDDIDDIDDIDD~  PDIDDIDDIDDIDDIDDID&#PJ~.                         
               .^~!??JJJJJJJJJJJJJJ:  !JJJJJJJJJJJJJJ?7!^:.                             
                                                                                                   
**/

interface IWETH {
    function deposit() external payable ;
    function withdraw(uint wad) external ;
    function totalSupply() external view returns (uint) ;
    function approve(address guy, uint wad) external returns (bool) ;
    function transfer(address dst, uint wad) external returns (bool) ;
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}


abstract contract WETHWrap is Ownable {
    IWETH public WETH;
    constructor (address WETHAddr) {
        require(WETHAddr != address(0), "WETH is the zero address");
        WETH = IWETH(WETHAddr);
    }

    function wrap(uint256 Amount) public onlyOwner{
        WETH.deposit{value:Amount}();
    }
    function unwrap(uint256 Amount) public onlyOwner{
        if (Amount != 0) {
            WETH.withdraw(Amount);
        }
    }
}

contract BuyBackBot is Pausable, ReentrancyGuard, WETHWrap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);
    event ConversionToDID(uint256 amountSold, uint256 amountReceived);
    event FailedConversion();

    IERC20 public DegenIDToken;
    IERC20 public rewardToken;
    ISwapRouter public uniswapRouter;
    address stakePoolContract;
    IStakingPool public stakingPool;
    uint24 public tradingFeeUniswapV3;
    uint256 public maxPriceDIDInWETH;

    constructor(
        address _DID,
        address _WETH,
        address _uniswapRouter,
        address _stakePool,
        uint256 _maxPrice
    ) WETHWrap(_WETH) {
        DegenIDToken = IERC20(_DID);
        rewardToken = IERC20(_WETH);
        stakePoolContract = _stakePool;
        stakingPool = IStakingPool(_stakePool);
        tradingFeeUniswapV3 = 3000;
        maxPriceDIDInWETH = _maxPrice;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        IERC20(_WETH).approve(_uniswapRouter, type(uint256).max);
    }

    function updateMaxPriceOfDIDInWETH(uint256 _newMaxPriceDIDInWETH) external onlyOwner {
        maxPriceDIDInWETH = _newMaxPriceDIDInWETH;
    }

    function updateTradingFeeUniswapV3(uint24 _newTradingFeeUniswapV3) external onlyOwner {
        require(
            _newTradingFeeUniswapV3 == 10000 || _newTradingFeeUniswapV3 == 3000 || _newTradingFeeUniswapV3 == 500,
            "Owner: Fee invalid"
        );
        tradingFeeUniswapV3 = _newTradingFeeUniswapV3;
    }

    function buyBackDID(uint256 amount) public onlyOwner returns (uint256){
        return _sellRewardTokenToDID(amount);
    }

    function distributeDID(uint256 amount) public onlyOwner {
        require(DegenIDToken.balanceOf(address(this)) >= amount);
        DegenIDToken.safeTransfer(stakePoolContract,amount);
        uint256 round = stakingPool.getCurrentRound();
        stakingPool.deliverReward(round, 0, amount);
    }

    function _sellRewardTokenToDID(uint256 _amount) internal returns (uint256) {
        uint256 amountOutMinimum = maxPriceDIDInWETH != 0 ? (_amount * 1e18) / maxPriceDIDInWETH : 0;

        // Set the order parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(rewardToken), // tokenIn
            address(DegenIDToken), // tokenOut
            tradingFeeUniswapV3, // fee
            address(this), // recipient
            block.timestamp, // deadline
            _amount, // amountIn
            amountOutMinimum, // amountOutMinimum
            0 // sqrtPriceLimitX96
        );

        // Swap on Uniswap V3
        uniswapRouter.exactInputSingle(params);
        return amountOutMinimum;
    }

    receive() external payable {}

    fallback() external payable {}

    function mutipleSendETH(
        address[] memory receivers,
        uint256[] memory ethValues
    ) public nonReentrant onlyOwner {
        require(receivers.length == ethValues.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bool sent = payable(receivers[i]).send(ethValues[i]);
            require(sent, "Failed to send Ether");
        }
    }

    function withdrawOtherCurrency(address _currency)
        external
        nonReentrant
        onlyOwner
    {
        require(
            _currency != address(DegenIDToken),
            "Owner: Cannot withdraw $DID"
        );

        uint256 balanceToWithdraw = IERC20(_currency).balanceOf(address(this));

        // Transfer token to owner if not null
        require(balanceToWithdraw != 0, "Owner: Nothing to withdraw");
        IERC20(_currency).safeTransfer(msg.sender, balanceToWithdraw);

        emit OtherTokensWithdrawn(_currency, balanceToWithdraw);
    }


}