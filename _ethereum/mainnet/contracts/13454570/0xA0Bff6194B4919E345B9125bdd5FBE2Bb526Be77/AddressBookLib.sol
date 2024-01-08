// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AddressBook.sol";
import "./Chick.sol";
import "./GovernToken.sol";
import "./IPriceFeed.sol";
import "./IEthVault.sol";
import "./VaultToken.sol";
import "./IERC20.sol";
import "./IUniswapV2Router.sol";

library AddressBookLib {

    function chick(AddressBook ab) public view returns (Chick) {
        return Chick(ab.getAddress(AddressBook.Name.CHICK));
    }

    function governToken(AddressBook ab) public view returns (GovernToken) {
        return GovernToken(ab.getAddress(AddressBook.Name.GOVERN_TOKEN));
    }

    function vaultToken( AddressBook ab) public view returns (VaultToken) {
        return VaultToken(ab.getAddress(AddressBook.Name.VAULT_TOKEN));
    }

    function ethPriceFeed(AddressBook ab) public view returns (IPriceFeed) {
        return IPriceFeed(ab.getAddress(AddressBook.Name.ETH_PRICE_FEED));
    }

    function chickPriceFeed(AddressBook ab) public view returns (IPriceFeed) {
        return IPriceFeed(ab.getAddress(AddressBook.Name.CHICK_PRICE_FEED));
    }

    function gTokenRewardMgr(AddressBook ab) public view returns (IGTokenRewardManager) {
        return IGTokenRewardManager(ab.getAddress(AddressBook.Name.REWARD_MGR));
    }

    function interestMgr(AddressBook ab) public view returns (IInterestManager) {
        return IInterestManager(ab.getAddress(AddressBook.Name.INTEREST_MGR));
    }


    function liquidationMgr(AddressBook ab) public view returns (ILiquidationManager) {
        return ILiquidationManager(ab.getAddress(AddressBook.Name.LIQUIDATION_MGR));
    }


    function router( AddressBook ab ) public view returns( IUniswapV2Router02 ){
        return IUniswapV2Router02( ab.getAddress( AddressBook.Name.ROUTER ) );
    }

    function lp( AddressBook ab ) public view returns( IERC20 ){
        return IERC20( ab.getAddress( AddressBook.Name.LP ) );
    }

}
