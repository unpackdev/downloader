// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Counters.sol";
import "./PullPayment.sol";
import "./Ownable.sol";

contract NFT is ERC721, PullPayment, Ownable {
  using Counters for Counters.Counter;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 10_000;
  uint256 public constant MINT_PRICE = 0.08 ether;

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

  /// @dev Is guest can mint nft.
  uint256 public guestMint = 0;

  /// @dev guest mint price
  uint256 public mintPrice = MINT_PRICE;

  constructor() ERC721("Fool Rich Pig", "FRP") {
    baseTokenURI = "";
  }

  /// @dev total supply
  function totalSupply() public pure returns (uint256) {
    return TOTAL_SUPPLY;
  }

  /// @dev batch mint
  function batchMintTo(address _recipient, uint256 _count) public onlyOwner {
    for(uint256 i; i < _count; i++) {
      _mintTo(_recipient);
    }
  }

  /// @dev single mint
  function singleMintTo(address recipient) public payable returns (uint256) {
    // if not owner need mint price
    if (owner() != _msgSender()) {
        require(guestMint == 1, "Guest cant mint NFT.");
        require(msg.value == mintPrice, "Transaction value did not equal the mint price");
        // if user use eth to mint, send nft to the sender.
        recipient = _msgSender();
    }
    
    uint256 newItemId = _mintTo(recipient);

    // deposit eth to owner
    if (msg.value > 0) {
        _asyncTransfer(owner(), msg.value);
    }

    return newItemId;
  }

  function _mintTo(address recipient) private returns (uint256) {
    uint256 tokenId = currentTokenId.current();
    require(tokenId < TOTAL_SUPPLY, "Max supply reached");

    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  function totalMinted() public view returns (uint256) {
    return currentTokenId.current();
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments(address payable payee) public override onlyOwner virtual {
      super.withdrawPayments(payee);
  }

  /// @dev set is guest can mint function
  function setGuestMint(uint256 _guestMint) public onlyOwner {
      guestMint = _guestMint;
  }

  /// @dev set guest mint price function
  function setMintPrice(uint256 _mintPrice) public onlyOwner {
      mintPrice = _mintPrice;
  }
}