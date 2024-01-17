// SPDX-License-Identifier: MIT

//DeSpace NFT marketplace contract 2022.8 */
//** Author: Henry Onyebuchi */

import "./DeSpace_Auction_721.sol";
import "./DeSpace_InstantTrade_721.sol";

pragma solidity 0.8.16;

contract DeSpace_Marketplace_721 is
    DeSpace_Auction_721,
    DeSpace_InstantTrade_721
{
    bool internal deployed;

    //Deployer
    function initialize(
        address _des,
        address _wallet,
        uint256 _desFee, // 1% = 1000
        uint256 _nativeFee // 1% = 1000
    ) external initializer {
        if (_des == address(0) || _wallet == address(0))
            revert DeSpace_Marketplace_WrongAddressInput();
        if (deployed) revert DeSpace_Marketplace_AlreadyInitialized();
        OwnableUpgradeable.__Ownable_init();
        des = _des;
        _setWallet(_wallet);
        _setFee(_desFee, _nativeFee);
        deployed = true;
    }
}
