// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Pausable.sol";

import "./SafeDecimalMath.sol";
import "./EthReward.sol";
import "./IPriceFeed.sol";
import "./IEthVault.sol";
import "./AddressBook.sol";
import "./AddressBookLib.sol";
import "./LiquidationManager.sol";
import "./IUniswapV3Router.sol";
import "./IWeth9.sol";



contract UniswapLiquidatorV3 is LiquidationManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    Chick mChick;
    ISwapRouter public mRouter;
    IERC20 public mMidToken;
    uint public mLiquidateRequired;
    uint public mOverLiquidated;
    bool public mLiquidateByMidToken;

    // we will set the pool fee to 1.0%.
    uint24 public constant poolFee = 10000;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "only admin");
        _;
    }

    constructor( Chick chick, IERC20 midToken, ISwapRouter router ) public {
        mChick = chick;
        mMidToken = midToken;
        mRouter = router;
        mLiquidateByMidToken = true;
    }

    event liquidateEvent( 
            uint256 vaultId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward,
            uint256 ethValue,
            address wethAddress,
            address chickAddress,
            uint timeStamp,
            uint result
            );

    event liquidateByMidTokenEvent( 
            uint256 vaultId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward,
            uint256 ethValue,
            address wethAddress,
            address chickAddress,
            uint timeStamp,
            uint midTokenAmount
            );


    event secondaryLiquidateEvent( 
        uint256 ethAmount,
        uint256 chickAmount,
        uint timeStamp,
        uint result
    );

    function liquidate(  
            uint256 vaultId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward ) payable external override  onlyVault {

        if( mLiquidateByMidToken ){
            // first liquidate by middle token: USDC
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: address(mMidToken),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            uint amountOut = mRouter.exactInputSingle{ value: msg.value }(params);
            emit liquidateByMidTokenEvent( vaultId, addr, ethAmount, chickAmount, interest, reward, msg.value, WETH9, address(mChick), block.timestamp, amountOut );

            // then swap to eurp
            params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(mMidToken),
                tokenOut: address(mChick),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountOut,
                amountOutMinimum: chickAmount,
                sqrtPriceLimitX96: 0
            });
            
            mMidToken.approve( address(mRouter), amountOut );

            try mRouter.exactInputSingle(params) returns ( uint amountOut2 ){
                // amountOut2 >= chickAmount
                liquidateAmount( amountOut2, chickAmount );    
                emit liquidateEvent( vaultId, addr, ethAmount, chickAmount, interest, reward, msg.value, WETH9, address(mChick), block.timestamp, amountOut2 );
            }
            catch{
                addLiquidateRequired( chickAmount );
                emit liquidateEvent( vaultId, addr, ethAmount, chickAmount, interest, reward, msg.value, WETH9, address(mChick), block.timestamp, 0 );
            }

        }else{
            // liquidate eurp 
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(WETH9, poolFee, mMidToken, poolFee, mChick),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: ethAmount,
                    amountOutMinimum: chickAmount
                });            
            
            // Executes the swap.
            try mRouter.exactInput{ value: msg.value }(params) returns ( uint amountOut ){
                liquidateAmount( amountOut, chickAmount );    
                emit liquidateEvent( vaultId, addr, ethAmount, chickAmount, interest, reward, msg.value, WETH9, address(mChick), block.timestamp, amountOut );
            }
            catch{
                addLiquidateRequired( chickAmount );
                emit liquidateEvent( vaultId, addr, ethAmount, chickAmount, interest, reward, msg.value, WETH9, address(mChick), block.timestamp, 0 );
            }
        }        
    }

    event SecondaryLiquidateEvent( uint midAmount, uint chickAmount, uint chickAmountResult, uint remainLiquidation );

    function secondaryLiquidateDirectly( uint ethAmount, uint chickAmount ) external onlyAdmin {
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(WETH9, poolFee, mMidToken, poolFee, mChick),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethAmount,
                amountOutMinimum: chickAmount
            });            

        // Executes the swap.
        uint amountOut = mRouter.exactInput{ value: ethAmount }(params);
        liquidateAmount( amountOut, 0 );
        emit secondaryLiquidateEvent( ethAmount, chickAmount, amountOut, mLiquidateRequired );
    }

    event SecondaryLiquidateByMidTokenEvent( uint midAmount, uint chickAmount, uint chickAmountResult, uint remainLiquidation );

    function secondaryLiquidateByMidToken( uint midTokenAmount, uint chickAmount ) external onlyAdmin {
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(mMidToken),
                tokenOut: address(mChick),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: midTokenAmount,
                amountOutMinimum: chickAmount,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap.
        mMidToken.approve( address(mRouter), midTokenAmount );
        uint amountOut = mRouter.exactInputSingle(params);
        liquidateAmount( amountOut, 0 );
        emit SecondaryLiquidateByMidTokenEvent( midTokenAmount, chickAmount, amountOut, mLiquidateRequired );
    }


    event SetLiquidateByMidTokenEvent( bool bSet);

    function setLiquidateByMidToken( bool bSet ) external onlyAdmin {
        mLiquidateByMidToken = bSet;
        emit SetLiquidateByMidTokenEvent( bSet );
    }

    function liquidateAmount( uint amount, uint required ) internal {
        mChick.burn( amount );
        if( amount >= required ){
            subLiquidateRequired( amount - required );
        }else{
            addLiquidateRequired( required - amount );
        }
    }


    function subLiquidateRequired( uint amount ) internal {
        if( mLiquidateRequired >= amount ){
            mLiquidateRequired = mLiquidateRequired - amount;
        }else{
            mOverLiquidated = mOverLiquidated.add( amount ).sub( mLiquidateRequired );
            mLiquidateRequired = 0;
        }
    }

    function addLiquidateRequired( uint amount ) internal {
        if( mOverLiquidated >= amount ){
            mOverLiquidated = mOverLiquidated - amount;
        }else{
            mLiquidateRequired = mLiquidateRequired.add( amount ).sub( mOverLiquidated );
            mOverLiquidated = 0;            
        }
    }


    receive() payable external {}

}
