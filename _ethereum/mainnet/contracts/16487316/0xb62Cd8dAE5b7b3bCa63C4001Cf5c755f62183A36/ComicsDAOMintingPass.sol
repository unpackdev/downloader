// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SlicerPurchasableConstructor.sol";
import "./ERC721A.sol";
import "./IERC2981.sol";
import "./Ownable.sol";

/// @title ComicsDAO Minting passes, integrated with Slice stores
/// @notice ERC721A NFTs, exchangeable for a set of ComicsDAO NFT collectibles
/// @author Dom-Mac
/// @author jacopo <jacopo@slice.so>
contract ComicsDAOMintingPass is ERC721A, Ownable, SlicerPurchasableConstructor, IERC2981 {
  // =============================================================
  //                          Errors
  // =============================================================

  error Invalid();

  // =============================================================
  //                          Storage
  // =============================================================

  // Max percentage possible for the royalties
  uint256 public constant MAX_ROYALTY = 10_000;
  // Royalties amount
  uint256 public royaltyFraction;
  // Token metadata uri
  string public uri;
  // Receiver of the royalties
  address public receiver;

  // =============================================================
  //                        Constructor
  // =============================================================

  /**
   * @notice Initializes the contract.
   *
   * @param productsModuleAddress_ {ProductsModule} address
   * @param slicerId_ ID of the slicer linked to this contract
   * @param name_ Name of the ERC721 contract
   * @param symbol_ Symbol of the ERC721 contract
   * @param royaltyFraction_ ERC2981 royalty amount, to be divided by 10000
   * @param tokenURI_ URI which is returned as token URI
   */
  constructor(
    address productsModuleAddress_,
    uint256 slicerId_,
    string memory name_,
    string memory symbol_,
    uint256 royaltyFraction_,
    string memory tokenURI_,
    address deployer_
  ) SlicerPurchasableConstructor(productsModuleAddress_, slicerId_) ERC721A(name_, symbol_) {
    // Override ownable's default owner due to CREATE3 deployment
    _transferOwnership(deployer_);

    // set the amount reserved
    royaltyFraction = royaltyFraction_;

    // Set the receiver of the royalties
    receiver = deployer_;

    // Set the uri if provided
    if (bytes(tokenURI_).length != 0) uri = tokenURI_;
  }

  // =============================================================
  //                      Purchase hook
  // =============================================================

  /**
   * @notice Override function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
   */
  function onProductPurchase(
    uint256 slicerId,
    uint256,
    address buyer,
    uint256 quantity,
    bytes memory,
    bytes memory
  ) public payable virtual override onlyOnPurchaseFrom(slicerId) {
    // mint one or a defined quantity of tokens in batch
    _mint(buyer, quantity);
  }

  // =============================================================
  //                         IERC2981
  // =============================================================

  /**
   * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
   * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
   */
  function royaltyInfo(
    uint256,
    uint256 salePrice
  ) external view override returns (address _receiver, uint256 _royaltyAmount) {
    // return the receiver from storage
    _receiver = receiver;

    // calculate and return the _royaltyAmount
    _royaltyAmount = (salePrice * royaltyFraction) / MAX_ROYALTY;
  }

  // =============================================================
  //                      IERC721Metadata
  // =============================================================

  /**
   * @dev See {ERC721A}
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    // check if the token exists, otherwise revert
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return uri;
  }

  // =============================================================
  //                      External setter
  // =============================================================

  /**
   * @dev Transfer tokens in batch
   *
   */
  function safeBatchTransferFrom(address from, address to, uint256[] memory tokenIds) external {
    // loop through the tokenIds and perform a single transfer
    for (uint256 i; i < tokenIds.length; ) {
      safeTransferFrom(from, to, tokenIds[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Set royalty receiver and fraction to be paid, only Owner is allowed
   *
   */
  function setRoyaltyInfo(address receiver_, uint256 royaltyFraction_) external onlyOwner {
    // check if the royaltyFraction_ is above the limit, if so revert
    if (royaltyFraction_ > MAX_ROYALTY) revert Invalid();

    receiver = receiver_;
    royaltyFraction = royaltyFraction_;
  }

  /**
   * @dev Set token URI, only Owner is allowed
   *
   */
  function setTokenURI(string memory uri_) external onlyOwner {
    uri = uri_;
  }

  // =============================================================
  //                           IERC165
  // =============================================================

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30000 gas.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC165) returns (bool) {
    // The interface IDs are constants representing the first 4 bytes
    // of the XOR of all function selectors in the interface.
    // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
    // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
    return ERC721A.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
  }
}
