// SPDX-License-Identifier: MIT LICENSE  

pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721.sol";
import "./FarmerGem.sol";

contract GemRedemption is 
  Initializable, 
  OwnableUpgradeable,
  PausableUpgradeable
{
  /*

  Security notes
  ==============

  - Bit packing gems into mapping with 4 bits each is safe because max gem ID is 6 which is < 2^4 (could do 3, but isn't as cleanly divided)

  */

  IERC721 public farmerContract;
  FarmerGem public gemContract;

  mapping(uint256 => uint256) public redemptions;

  event Redemption(
    address sender,
    uint256[] farmerIds,
    uint256[] gemIds
  );

  /**
   * instantiates contract
   * @param _farmers address of farmer ERC721 contract
   * @param _gems address of gem ERC1155 contract
   */
  function initialize(address _farmers, address _gems) external initializer {
    __Ownable_init();
    __Pausable_init();

    farmerContract = IERC721(_farmers);
    gemContract = FarmerGem(_gems);
  }

  /** EXTERNAL */

  /**
   * allows user to apply a gem to a farmer
   * @param farmerIds the farmer to apply the gem to
   * @param gemIds the gem type to apply to the farmer
   */
  function redeem(uint256[] calldata farmerIds, uint256[] calldata gemIds) external whenNotPaused {
    require(farmerIds.length == gemIds.length, "MISTMATCHED INPUT");
    for (uint256 i = 0; i < farmerIds.length; i++) {
      require(farmerContract.ownerOf(farmerIds[i]) == _msgSender(), "NOT YOUR FARMER");
      require(getGemApplied(farmerIds[i]) == 0, "CANT APPLY 2 GEMS TO 1 FARMER");
      _applyGem(farmerIds[i], gemIds[i]);
      gemContract.burn(_msgSender(), gemIds[i], 1);
    }
    emit Redemption(_msgSender(), farmerIds, gemIds);
  }

  /**
   * gets the applied gem to a farmer
   * @param farmerId the ID of the farmer
   */
  function getGemApplied(uint256 farmerId) public view returns (uint256) {
    // get the packed int that contains the redemption for this farmer
    // 4 bits per farmer = 64 farmers / 256 bits
    uint256 packed = redemptions[farmerId / 64];
    // return whether 4 (claimId % 64)th bits are set
    return ((packed >> ((farmerId % 64) * 4)) & 0xF);
  }

  /**
   * applies a gem to a farmer
   * @param farmerId the type of claim
   * @param gemId the ID of the claim
   */
  function _applyGem(uint256 farmerId, uint256 gemId) internal {
    // reduce ID-space to packed 256 bit ints
    uint256 packed = redemptions[farmerId / 64];
    // set the (claimId % 64)th bits to the gem id
    redemptions[farmerId / 64] = packed | (gemId << ((farmerId % 64) * 4));
  }

  /**
   * enables owner to pause / unpause claiming
   */
  function setPaused(bool _p) external onlyOwner {
    if (_p) _pause();
    else _unpause();
  }

}