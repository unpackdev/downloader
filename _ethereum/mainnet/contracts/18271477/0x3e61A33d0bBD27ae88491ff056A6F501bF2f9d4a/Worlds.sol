/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC721Upgradeable.sol";

import "./IERC165Upgradeable.sol";
import "./IWorldsDropMarket.sol";
import "./IWorldsNFTMarket.sol";
import "./IWorldsSharedMarket.sol";

import "./ERC4906.sol";
import "./ERC721UserRoles.sol";
import "./FoundationTreasuryNode.sol";
import "./NFTDropMarketNode.sol";
import "./NFTMarketNode.sol";
import "./RouterContextDouble.sol";

import "./WorldsAllowlist.sol";
import "./WorldsAllowlistBySeller.sol";
import "./WorldsCore.sol";
import "./WorldsInventoryByCollection.sol";
import "./WorldsInventoryByNft.sol";
import "./WorldsManagement.sol";
import "./WorldsMetadata.sol";
import "./WorldsNftMarketExhibitionMigration.sol";
import "./WorldsPaymentInfo.sol";
import "./WorldsTransfer2Step.sol";
import "./WorldsUserRoles.sol";

error Worlds_Not_Implemented();

/**
 * @title Worlds are NFTs which aggregate collections of curated content.
 * @author HardlyDifficult & reggieag
 */
contract Worlds is
  NFTMarketNode,
  NFTDropMarketNode,
  IWorldsDropMarket,
  IWorldsNFTMarket,
  FoundationTreasuryNode,
  IWorldsSharedMarket,
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  RouterContextDouble,
  ERC721Upgradeable,
  ERC4906,
  ERC721UserRoles,
  WorldsCore,
  WorldsUserRoles,
  WorldsMetadata,
  WorldsPaymentInfo,
  WorldsAllowlistBySeller,
  WorldsAllowlist,
  WorldsInventoryByCollection,
  WorldsInventoryByNft,
  WorldsManagement,
  WorldsTransfer2Step,
  WorldsNftMarketExhibitionMigration
{
  ////////////////////////////////////////////////////////////////
  // Setup
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Set immutable variables for the implementation contract.
   * @param treasury Foundation's treasury contract address.
   * @param nftMarket Foundation's NFTMarket contract address.
   * @param nftDropMarket Foundation's NFTDropMarket contract address.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   */
  constructor(
    address payable treasury,
    address nftMarket,
    address nftDropMarket
  )
    RouterContextDouble(nftMarket, nftDropMarket)
    FoundationTreasuryNode(treasury)
    NFTMarketNode(nftMarket)
    NFTDropMarketNode(nftDropMarket)
  {
    _disableInitializers();
  }

  /**
   * @notice Initialize the upgradeable proxy contract for Worlds.
   */
  function initialize() external initializer {
    // Assign the NFT's name and symbol.
    __ERC721_init_unchained("Worlds", "WORLD");
  }

  ////////////////////////////////////////////////////////////////
  // Not Implemented Overrides
  // (standard features which are currently disabled)
  ////////////////////////////////////////////////////////////////

  /**
   * @notice [NOT IMPLEMENTED] Use `beginTransfer` instead.
   * @dev Override the default transfer behavior to prevent direct transfers.
   * Direct transfers are disabled to prevent a user from spamming a user with unwanted worlds.
   * Direct transfers will be implemented once the use-case for them becomes clear.
   */
  function safeTransferFrom(
    address /* from */,
    address /* to */,
    uint256 /* tokenId */,
    bytes memory /* data */
  ) public pure override {
    revert Worlds_Not_Implemented();
  }

  /**
   * @notice [NOT IMPLEMENTED] Use `beginTransfer` instead.
   * @dev Override the default transfer behavior to prevent direct transfers.
   * Direct transfers are disabled to prevent a user from spamming a user with unwanted worlds.
   * Direct transfers will be implemented once the use-case for them becomes clear.
   */
  function transferFrom(address /* from */, address /* to */, uint256 /* tokenId */) public pure override {
    revert Worlds_Not_Implemented();
  }

  ////////////////////////////////////////////////////////////////
  // Inheritance Requirements
  // (no-ops to avoid compile errors)
  ////////////////////////////////////////////////////////////////

  /// @inheritdoc IERC165Upgradeable
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(
      ERC165Upgradeable,
      ERC721Upgradeable,
      ERC4906,
      WorldsMetadata,
      WorldsManagement,
      WorldsNftMarketExhibitionMigration
    )
    returns (bool isSupported)
  {
    isSupported = super.supportsInterface(interfaceId);
  }

  /// @inheritdoc WorldsMetadata
  function tokenURI(
    uint256 worldId
  )
    public
    view
    override(ERC721Upgradeable, WorldsMetadata, WorldsManagement, WorldsNftMarketExhibitionMigration)
    returns (string memory uri)
  {
    uri = super.tokenURI(worldId);
  }

  /// @inheritdoc ERC721Upgradeable
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable, WorldsTransfer2Step) {
    super._afterTokenTransfer(from, to, firstTokenId, batchSize);
  }

  /// @inheritdoc ERC721Upgradeable
  function _burn(
    uint256 worldId
  )
    internal
    override(
      ERC721Upgradeable,
      WorldsPaymentInfo,
      WorldsMetadata,
      WorldsAllowlistBySeller,
      WorldsManagement,
      WorldsNftMarketExhibitionMigration
    )
  {
    super._burn(worldId);
  }

  /// @inheritdoc ContextUpgradeable
  function _msgSender() internal view override(ContextUpgradeable, RouterContextDouble) returns (address sender) {
    sender = super._msgSender();
  }
}
