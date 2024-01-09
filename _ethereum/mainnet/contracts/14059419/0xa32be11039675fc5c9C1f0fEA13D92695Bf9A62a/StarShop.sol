
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   Asteria                     *
 ****************************************/

import "./StarShopBase.sol";

interface IStarToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StarShop is StarShopBase {
  address public STAR_TOKEN;
  address public TREASURY;

  string public name = "Ethaliens: Star Shop";
  string public symbol = "ESS";

  //payable
  function mint( uint id, uint quantity ) external payable{
    require( exists( id ), "StarRewards: Specified token (id) does not exist" );

    Token memory token = tokens[id];
    require( token.isMintActive, "StarRewards: Sale is not active" );
    require( STAR_TOKEN != address(0), "StarRewards: $STAR address is unset" );
    require( TREASURY != address(0), "StarRewards: Treasury address is unset" );

    uint total = quantity * token.mintPrice;
    address recipient = token.burnStar ?
      0x000000000000000000000000000000000000dEaD : 
      TREASURY;
    if( !IStarToken( STAR_TOKEN ).transferFrom( msg.sender, recipient, total) )
      revert( "StarRewards: $STAR payment failed" );

    _mint( msg.sender, id, quantity, "" );
  }

  //delegated
  function setStarToken( address starToken ) external onlyDelegates{
    STAR_TOKEN = starToken;
  }

  function setTreasury( address treasury ) external onlyDelegates{
    TREASURY = treasury;
  }
}
