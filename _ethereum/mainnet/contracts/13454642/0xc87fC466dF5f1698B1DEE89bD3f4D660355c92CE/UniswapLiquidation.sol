// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
import "./IUniswapV2Router.sol";
import "./IWeth9.sol";



contract UniswapLiquidationManager is LiquidationManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    AddressBook mAddressBook;

    constructor( AddressBook addressBook ) public {
        mAddressBook = addressBook;
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
            uint timeStamp
            );

    event liquidateResult( 
        uint256 ethAmount,
        uint256 chickAmount
    );

    function liquidate(  
            uint256 vaultId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward ) payable external override  onlyVault {

        //IUniswapV2Router02 UniswapV2Router02 = IUniswapV2Router02( 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D  );
        Chick chick = AddressBookLib.chick(mAddressBook);
        IUniswapV2Router02 UniswapV2Router02 = AddressBookLib.router( mAddressBook );

        // wrap eth to weth 
        // IWETH9 weth = IWETH9( payable(UniswapV2Router02.WETH()) );                       
        // weth.deposit{ value: msg.value }();

        // sell eth for chick
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router02.WETH();
        path[1] = address(chick);

        emit liquidateEvent( vaultId, addr, ethAmount, chickAmount, interest, reward, msg.value, path[0], path[1], block.timestamp );

        uint[] memory amounts;
        amounts = UniswapV2Router02.swapExactETHForTokens{ value: msg.value }(0, path, address( this ), block.timestamp+15 );

        emit liquidateResult( amounts[0], amounts[1]); 

        // burn chick
        chick.burn( amounts[1]);
        
        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }

    receive() payable external {}

}
