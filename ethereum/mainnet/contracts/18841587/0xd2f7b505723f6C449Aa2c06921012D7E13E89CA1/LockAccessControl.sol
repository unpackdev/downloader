// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import "./Ownable.sol";

import "./ITokenVault.sol";
import "./IFNFT.sol";
import "./IRedemptionTreasury.sol";
import "./ILockAddressRegistry.sol";

error MODERATOR_ONLY();

contract LockAccessControl is Ownable {
    ILockAddressRegistry internal addressProvider;

    /* ======= CONSTRUCTOR ======= */

    constructor(address provider) {
        addressProvider = ILockAddressRegistry(provider);
    }

    /* ======= MODIFIER ======= */

    modifier onlyModerator() {
        if (!addressProvider.isModerator(msg.sender)) revert MODERATOR_ONLY();
        _;
    }   

   function setAddressProvider(address provider) external onlyOwner {
        addressProvider = ILockAddressRegistry(provider);
    }

    ///////////////////////////////////////////////////////
    //               MANAGER CALLED FUNCTIONS            //
    ///////////////////////////////////////////////////////
    function getTokenVault() internal view returns (ITokenVault) {
        return ITokenVault(addressProvider.getTokenVault());
    }

    function getRNFT() internal view returns (IRedemptionNFT) {
        return IRedemptionNFT(addressProvider.getRNFT());
    }

    function getTreasury() internal view returns (IRedemptionTreasury) {
        return IRedemptionTreasury(addressProvider.getTreasury());
    }

    function getRedeemToken() internal view returns (address) {
        return addressProvider.getRedeemToken();
    }

}
