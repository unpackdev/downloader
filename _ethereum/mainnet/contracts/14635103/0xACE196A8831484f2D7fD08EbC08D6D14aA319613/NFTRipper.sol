//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./IERC20.sol";
import "./IERC721Metadata.sol";
import "./ERC721.sol";
import "./Ownable.sol";

// NFTRipper.xyz - clone any NFT you want!

contract NFTRipper is ERC721, Ownable {
  uint256 public fee;
  uint256 public nftCount;

  struct NFTReference {
    address nftAddress;
    uint256 nftId;
  }

  mapping(uint256 => string) public nftMetadata;
  mapping(uint256 => NFTReference) public nftReferences;

  event feeChanged(uint256 newFee);

  constructor(address owner_) ERC721("NFTRip", "NFTRIP") {
    Ownable.transferOwnership(owner_);
  }

  function ripReference(address nftAddress, uint256 nftId) external payable {
    if (fee > 0) {
      require(msg.value >= fee, "Service Fee should be paid");
    }
    nftReferences[nftCount] = NFTReference(nftAddress, nftId);
    _mint(msg.sender, nftCount++);
  }

  function ripMetadata(string calldata metadata) external payable {
    if (fee > 0) {
      require(msg.value >= fee, "Service Fee should be paid");
    }
    nftMetadata[nftCount] = metadata;
    _mint(msg.sender, nftCount++);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    NFTReference memory ref = nftReferences[tokenId];
    if (ref.nftAddress == address(0) && ref.nftId == 0) {
      return nftMetadata[tokenId];
    } else {
      return IERC721Metadata(ref.nftAddress).tokenURI(ref.nftId);
    }
  }

  /////////////////////////
  // Owner functions

  function changeFee(uint256 newFee) external onlyOwner {
    fee = newFee;
    emit feeChanged(newFee);
  }

  /// @notice Pays out all Factory ETH balance to owners address
  function payout() external {
    require(payable(owner()).send(address(this).balance));
  }

  /// @notice Pays out all Factory ERC20 token balance to owners address
  /// @param _tokenAddress is an address of the ERC20 token to payout
  function payoutToken(address _tokenAddress) external {
    IERC20 token = IERC20(_tokenAddress);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "Nothing to payout");
    token.transfer(owner(), amount);
  }
}
