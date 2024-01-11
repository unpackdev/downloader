// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC1155.sol";
import "./ERC165.sol";

contract SicilianKissBurn is AdminControl, ICreatorExtensionTokenURI {

  address private _creator;
  uint private burnableTokenId;
  uint private startingTokenId;
  bool private initialized;
  string[] private assetURIs = new string[](4);

  address public sicilianKissContract;
  uint256 public deactivationTimestamp = 0;


  constructor(address creator) {
    _creator = creator;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
    return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
  }

  /*
   * Allows us to set the contract and token ID eligible for burning
   */
  function setBurnableContractAndToken(address theContract, uint tokenId) public adminRequired {
    sicilianKissContract = theContract;
    burnableTokenId = tokenId;
  }

  /*
   * Pushes the deactivation time to 24hrs past the call's blocktime
   */
  function setActive() public adminRequired {
    deactivationTimestamp = block.timestamp + 86400;
  }

  /*
   * Can only be called once.
   * Creates the four base tokens that users will later mint via burn-redeem.
   */
  function initialize() public adminRequired {
    require(!initialized, 'Initialized');
    initialized = true;

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;
    uint256[] memory amount = new uint256[](4);
    amount[0] = 1;
    amount[1] = 1;
    amount[2] = 1;
    amount[3] = 1;
    string[] memory uris = new string[](4);
    uris[0] = "";
    uris[1] = "";
    uris[2] = "";
    uris[3] = "";

    // forge four completely separate 1155 tokens that this extension can mint
    uint256[] memory mintedTokenIds = IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amount, uris);
    startingTokenId = mintedTokenIds[0]; // record the first token ID we mint
  }

  /*
   * Public minting function with burn-redeem mechanism.
   * User must burn 10 Sicilian Kiss to receive 1 of each of the 4 new tokens.
   * If the user burns a multiple of 10, they will get that multiple of each of the new tokens.
   *
   * Ex: I burn 20 kisses so I get 2 of each of the new 4 pieces/tokens totaling 8 new tokens.
   */
  function mint(uint256 amount) public {
    require(IERC1155(sicilianKissContract).balanceOf(msg.sender, burnableTokenId) >= 10 * amount, "Must own 10x Kisses");
    require(IERC1155(sicilianKissContract).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");
    require(block.timestamp < deactivationTimestamp, "Inactive");
    require(amount > 0, "None");

    uint[] memory tokenIds = new uint[](1);
    tokenIds[0] = burnableTokenId;

    uint[] memory burnAmounts = new uint[](1);
    burnAmounts[0] = 10 * amount;

    try IERC1155CreatorCore(sicilianKissContract).burn(msg.sender, tokenIds, burnAmounts) {
    } catch (bytes memory) {
        revert("BurnRedeem: Burn failure");
    }

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;

    uint[] memory numToSend = new uint[](4);
    numToSend[0] = amount;
    numToSend[1] = amount;
    numToSend[2] = amount;
    numToSend[3] = amount;

    uint[] memory tokenToSend = new uint[](4);
    tokenToSend[0] = startingTokenId;
    tokenToSend[1] = startingTokenId + 1;
    tokenToSend[2] = startingTokenId + 2;
    tokenToSend[3] = startingTokenId + 3;
    IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
  }

  /*
   * Sets the URIs for the 4 tokens minted and controlled by this extension.
   */
  function setAssetURIs(string memory uri1, string memory uri2, string memory uri3, string memory uri4) public adminRequired {
    assetURIs[0] = uri1;
    assetURIs[1] = uri2;
    assetURIs[2] = uri3;
    assetURIs[3] = uri4;
  }

  /*
   * See {ICreatorExtensionTokenURI-tokenURI}
   */
  function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
    require(creator == _creator, "Invalid token");
    require(tokenId >= startingTokenId && tokenId <= startingTokenId + 3, "Invalid token");
    return assetURIs[tokenId - startingTokenId];
  }
}
