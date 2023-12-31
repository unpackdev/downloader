// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.20;

import "./Ownable.sol";

/**
  An error emitted if we are about to interact with an unexpected
  implementation of the Bonkler proxy.
*/
error UnexpectedImplementation ();

/// A ProxyAdmin contract interface.
interface IProxyAdmin {
  function getProxyImplementation (
    address
  ) external view returns (address);
}

/// A Bonkler NFT contract interface.
interface IBonklerNFT {
  function setMinter (
    address
  ) external;
  function transferOwnership (
    address
  ) external;
}

/// A Bonkler auction proxy contract interface.
interface IBonklerAuction {
  function settleAuction () external;
}

/**
  @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
  @title A contract for safely rescuing the proxy contract's
    trapped Bonkler.
  @author Tim Clancy <tim-clancy.eth>
  @custom:version 1.0

  This contract allows an owner to conditionally bundle Bonkler NFT mint
  delegation with auction settlement. This contract will only permit a 
  rescue attempt if the targeted Bonkler auction proxy has the expected
  implementation address.

  @custom:date October 4th, 2023
  @custom:terry "Is this too much voodoo for the next ten centuries?"
*/
contract BonklerRescue is Ownable {

  /// The address of the original Bonkler auction proxy contract.
  address public auction;

  /// The address of the Bonkler NFT contract.
  address public bonkler;

  /**
    Construct a migration contract targeting the original Bonkler auction
    and NFT contracts.

    @param _auction The address of the Bonkler auction contract to migrate from.
    @param _bonkler The address of the Bonkler NFT contract.
  */
  constructor (
    address _auction,
    address _bonkler
  ) {
    auction = _auction;
    bonkler = _bonkler;
  }

  /**
    Attempt a rescue; the rescue is only performed if there is no chance that
    the underlying proxy contract may have been maliciously upgraded.
    
    @param _intended If the Bonkler auction proxy implementation address
      matches this value, proceed with the rescue attempt.
  */
  function rescue (
    address _intended
  ) external onlyOwner {
    if (
      IProxyAdmin(
        0x6bCe3918a8E516fd4264a8e3f962ea0a3F2dEC99
      ).getProxyImplementation(
        0xF421391011Dc77c0C2489d384C26e915Efd9e2C5
      ) != _intended
    ) {
      revert UnexpectedImplementation();
    }
    IBonklerNFT(bonkler).setMinter(auction);
    IBonklerAuction(auction).settleAuction();
    IBonklerNFT(bonkler).setMinter(
      0x3033FDC27098D0006a72CcACCb850F3e7d700C00
    );
    IBonklerNFT(bonkler).transferOwnership(
      0xB520F068a908A1782a543aAcC3847ADB77A04778
    );
  }

  /**
    Allow the rightful owner of the Bonkler NFT to assume control.
  */
  function clawback () external {
    IBonklerNFT(bonkler).transferOwnership(
      0xB520F068a908A1782a543aAcC3847ADB77A04778
    );
  }
}

