// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";
import "./PullPayment.sol";

contract ChineseCat is ERC721, Ownable, PullPayment {
  // Constants
  uint256 public constant totalSupply = 10_000;
  uint256 public constant freePrice = 0 ether;
  uint256 public constant maxFreeMint = 5;
  uint256 public constant buyPrice = 1 ether;

  mapping(address => uint256) public freeMintCount;

  uint256 private freeTokenId = 2_000;
  uint256 private buyTokenId = 0;
  uint256 private maxBuyTokenId = 1_000;
  uint256 private ownerTokenId = 1_000;
  uint256 private maxOwnerTokenId = 2_000;

  constructor() ERC721("ChineseCat", "Cat") {}

  /// @dev One address can mint 5 tokens free, pay according to mood
  function freeMints(uint256 amount, address recipient) public payable {
    require(amount > 0 && amount <= maxFreeMint && freeMintCount[recipient] + amount <= maxFreeMint, "One address only can mint 5 tokens");

    require(freeTokenId + amount <= totalSupply, "Max free supply reached");

    require(msg.value >= freePrice, "Transaction value cannot be less than the mint price");

    unchecked {
      freeMintCount[recipient] += amount;
    }

    _asyncTransfer(owner(), msg.value);

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(recipient, ++freeTokenId);
    }
  }

  /// @dev Users can choose to buy the first 1000 NFTs
  function buyMint(address recipient) public payable {
    require(freeTokenId == totalSupply, "Buy mint is not currently available");

    require(buyTokenId < maxBuyTokenId, "Max buy supply reached");

    require(msg.value >= buyPrice, "Transaction value cannot be less than the mint price");

    _asyncTransfer(owner(), msg.value);

    _safeMint(recipient, ++buyTokenId);
  }

  /// @dev Owner can mint 1000 - 2000 NFTs
  function ownerMints() public onlyOwner {
    require(freeTokenId == totalSupply && buyTokenId == maxBuyTokenId, "Owner mint is not currently available");

    require(ownerTokenId < maxOwnerTokenId, "Max owner supply reached");

    for (uint256 i = ownerTokenId; i < maxOwnerTokenId; i++) {
      _safeMint(owner(), ++ownerTokenId);
    }
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return "https://nftstorage.link/ipfs/bafybeid23ysfh3oi4okk5ys5aijzkyqe2vi2nmfxjwfss7rolhmdubeqva/";
  }

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments(address payable payee) public override onlyOwner virtual {
    super.withdrawPayments(payee);
  }
}
