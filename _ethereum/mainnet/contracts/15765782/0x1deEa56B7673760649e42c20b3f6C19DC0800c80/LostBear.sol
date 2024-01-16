// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./MultiStage.sol";

contract LostBear is MultiStage {
  function _startTokenId()
    internal
    pure
    override(ERC721AUpgradeable)
    returns (uint256)
  {
    return 1;
  }

  function initialize(
    bytes32 goldListMerkleTreeRoot_,
    bytes32 whiteListMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_
  ) public initializerERC721A initializer {
    __ERC721A_init("Lost Bear by FLUFF", "LostBear");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(3500);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      "https://ipfs.io/ipfs/QmNUhi3ek27nZ5oW1nyeVQoEcQx4SgbtJBwyMgKhkLA8bH/",
      ".json"
    );
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    // GoldenWL
    updateBalanceLimit(2, 4);
    setPrice(2, 0);
    updateMerkleTreeRoot(2, goldListMerkleTreeRoot_);
    // WhiteList
    updateBalanceLimit(3, 1);
    setPrice(3, 0);
    updateMerkleTreeRoot(3, whiteListMerkleTreeRoot_);
    // Public
    updateBalanceLimit(1, 5);
    setPrice(1, 0);
  }
}
