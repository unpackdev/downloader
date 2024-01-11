// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface IERC721BaseURI is IERC721 {
  function baseURI() external view returns (string memory);
  function tokenURI(uint256 id) external view returns (string memory);
}

contract MutantApeYachtClub is
  ERC721,
  IERC721BaseURI,
  IERC721Receiver,
  Pausable,
  Ownable
{
  event Wrapped(uint256 indexed tokenId);
  event Unwrapped(uint256 indexed tokenId);

  IERC721BaseURI immutable bayc;

  constructor(
    address originalContractAddress,
    string memory name,
    string memory symbol
  )
    ERC721(name, symbol)
  {
    bayc = IERC721BaseURI(originalContractAddress);
  }

  function baseURI() public view override returns (string memory) {
    return bayc.baseURI();
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, IERC721BaseURI)
    returns (string memory)
  {
    return bayc.tokenURI(tokenId);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function wrap(uint256[] calldata tokenIds_) external {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      bayc.safeTransferFrom(msg.sender, address(this), tokenIds_[i]);
    }
  }

  function unwrap(uint256[] calldata tokenIds_) external {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      safeTransferFrom(msg.sender, address(this), tokenIds_[i], "");
    }
  }

  function _flip(
    address who_,
    bool isWrapping_,
    uint256 tokenId_
  ) private {
    if (isWrapping_) {
      if (_exists(tokenId_) && ownerOf(tokenId_) == address(this)) {
        safeTransferFrom(address(this), who_, tokenId_, "");
      } else {
        _safeMint(who_, tokenId_);
      }
      emit Wrapped(tokenId_);
    } else {
      bayc.safeTransferFrom(address(this), who_, tokenId_);
      emit Unwrapped(tokenId_);
    }
  }

  // Notice: You must use safeTransferFrom in order to properly wrap/unwrap
  function onERC721Received(
    address operator_,
    address from_,
    uint256 tokenId_,
    bytes memory data_
  ) external override returns (bytes4) {
    require(
      msg.sender == address(bayc) || msg.sender == address(this),
      "must be original NFT or wrapped NFT"
    );

    bool isWrapping = msg.sender == address(bayc);
    _flip(from_, isWrapping, tokenId_);

    return this.onERC721Received.selector;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(IERC721, ERC721) {
    require(to != address(this), "Can't use transferFrom to contract");
    _transfer(from, to, tokenId);
  }

  fallback() external payable {}

  receive() external payable {}

  function withdraw() external onlyOwner() {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}