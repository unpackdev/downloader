// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.20;

/**
  An error emitted if an address that is not the Bonkler NFT attempts to
  emit a redemption event.
*/
error NotBonkler ();

/**
  @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
  @title A stub contract for emitting Bonkler redemption events.
  @author Tim Clancy <tim-clancy.eth>
  @custom:version 1.0

  This basic contract allows the configured Bonkler NFT to call out and
  emit redemption events. This is required to keep Bonkler v1 redemption
  active after decoupling from the original auction proxy.

  @custom:date September 14th, 2023.
*/
contract RedeemStub {

  /// The address of the Bonkler NFT contract.
  address public bonkler;
  
  /**
    Emit this event whenever a Bonkler is redeemed to unlock its underlying
    reserve Ether.

    @param bonklerId The ID of the specific Bonkler being redeemed.
  */
  event BonklerRedeemed (
    uint256 indexed bonklerId
  );

  /**
    Construct a redemption stub contract supporting the Bonkler NFT contract.

    @param _bonkler The address of the Bonkler NFT contract.
  */
  constructor (
    address _bonkler
  ) {
    bonkler = _bonkler;
  }

  /**
    Allow the Bonkler NFT contract to signal Bonkler redemption.

    @param _bonklerId The ID of the Bonkler being redeemed.
  */
  function emitBonklerRedeemedEvent (
    uint256 _bonklerId
  ) external {
    if (msg.sender != bonkler) {
      revert NotBonkler();
    }
    emit BonklerRedeemed(_bonklerId);
  }
}

