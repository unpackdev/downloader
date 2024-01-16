// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./TwoStage.sol";

contract Bubblefriends is TwoStage {
  function initialize(
    bytes32 whitelistMerkleTreeRoot_,
    address royaltiesRecipient_,
    uint256 royaltiesValue_,
    address[] memory shareholders,
    uint256[] memory shares
  ) public initializerERC721A initializer {
    __ERC721A_init("BubbleFriends", "BubbleFriends");
    __Ownable_init();
    __AdminManager_init_unchained();
    __Supply_init_unchained(3333);
    __AdminMint_init_unchained();
    __Whitelist_init_unchained();
    __BalanceLimit_init_unchained();
    __UriManager_init_unchained(
      "https://ipfs.io/ipfs/QmRWJvDQjsk8MtUAyevJVy8cDZo5u2c3UE65c2RGqMyVeq/",
      ".json"
    );
    __CustomPaymentSplitter_init(shareholders, shares);
    __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
    updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
    updateBalanceLimit(uint8(Stage.Whitelist), 2);
    updateBalanceLimit(uint8(Stage.Public), 2);
    setPrice(uint8(Stage.Whitelist), 0.033 ether);
    setPrice(uint8(Stage.Public), 0.033 ether);
  }
}
