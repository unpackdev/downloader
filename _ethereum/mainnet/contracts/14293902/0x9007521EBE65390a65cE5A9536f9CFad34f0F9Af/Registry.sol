// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./UpgradeableBeacon.sol";
import "./Initializable.sol";
import "./IERC721.sol";

import "./IRegistry.sol";

contract Registry is IRegistry, Initializable {
    UpgradeableBeacon public override listingBeacon;
    UpgradeableBeacon public override brickTokenBeacon;
    UpgradeableBeacon public override buyoutBeacon;
    UpgradeableBeacon public override iroBeacon;
    IERC721 public override propNFT;
    address public override treasuryAddr;

    function initialize(
        address _implListing,
        address _implBrickToken,
        address _implBuyout,
        address _implIRO,
        IERC721 _propNFT,
        address _treasuryAddr
    ) public {
        listingBeacon = new UpgradeableBeacon(_implListing);
        brickTokenBeacon = new UpgradeableBeacon(_implBrickToken);
        buyoutBeacon = new UpgradeableBeacon(_implBuyout);
        iroBeacon = new UpgradeableBeacon(_implIRO);

        // Set beacon owners to be deployer
        // TODO - set to be admin?
        listingBeacon.transferOwnership(msg.sender);
        brickTokenBeacon.transferOwnership(msg.sender);
        buyoutBeacon.transferOwnership(msg.sender);
        iroBeacon.transferOwnership(msg.sender);

        // The PropNFT contract takes care of its own upgrades
        propNFT = _propNFT;

        // The CitaDAO treasury, currently accepts 2% fees
        treasuryAddr = _treasuryAddr;
    }
}
