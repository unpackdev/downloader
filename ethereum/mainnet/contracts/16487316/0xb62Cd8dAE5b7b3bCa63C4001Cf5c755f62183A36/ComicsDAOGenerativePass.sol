// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ComicsDAOMintingPass.sol";

/// @title ComicsDAO Generative Minting passes
/// @notice Basic {ComicsDAOMintingPass} with a MAX_SUPPLY setted
/// @author Dom-Mac
/// @author jacopo <jacopo@slice.so>

contract ComicsDAOGenerativePass is ComicsDAOMintingPass {
  // =============================================================
  //                          Errors
  // =============================================================

  error MaxSupplyReached();

  // =============================================================
  //                          Storage
  // =============================================================

  // Token max supply available
  uint256 public constant MAX_SUPPLY = 2_000;

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
  )
    ComicsDAOMintingPass(
      productsModuleAddress_,
      slicerId_,
      name_,
      symbol_,
      royaltyFraction_,
      tokenURI_,
      deployer_
    )
  {}

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
  ) public payable override onlyOnPurchaseFrom(slicerId) {
    // check if there are enough tokens to mint, otherwise revert
    if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyReached();

    // mint one or a defined quantity of tokens in batch
    super.onProductPurchase(slicerId, 0, buyer, quantity, '', '');
  }
}
