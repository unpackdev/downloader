// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";

contract ManyHands is ERC721A, Ownable, ERC2981 {
  event MintToggled(bool indexed isActive);

  uint256 public constant SUPPLY_LIMIT = 5000;
  uint256 public constant MINT_PRICE = 0.029 ether;

  address public withdrawalAddress = 0x7f49d10e729451f5C4005A5c66682EcdEDB0E8fa;
  address private financeAdmin = 0xc883F209eAF1EA324D8d757B523a5691DD8D81e3;

  bool public mintActive;

  string public baseURI = "ipfs://bafybeicrtaqzfm7qm75jeznja7epxwnxp5i5ewygoaorlmjcoskowunmxm/";

  constructor() ERC721A("Many Hands NFT", "MH") {
    _setDefaultRoyalty(0x7f49d10e729451f5C4005A5c66682EcdEDB0E8fa, 750); // 7.5% royalties
  }

  function updateRoyaltyConfig(address recipient, uint96 rate) external onlyOwner {
    require(recipient != address(0), "Recipient cannot be zero address");

    _setDefaultRoyalty(recipient, rate);
  }

  function updateWithdrawalAddress(address recipient) external {
    require(msg.sender == financeAdmin, "Sender not authorized");
    require(recipient != address(0), "Recipient cannot be zero address");

    withdrawalAddress = recipient;
  }

  function updateBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function toggleMintActive() external onlyOwner {
    mintActive = !mintActive;

    emit MintToggled(mintActive);
  }

  function mint(uint256 amount) external payable {
    require(mintActive, "Sale not active");
    require(amount > 0, "Cannot mint 0");
    require((totalSupply() + amount) <= SUPPLY_LIMIT, "Out of supply");
    require(msg.value >= (amount * MINT_PRICE), "Insufficient payment");

    _safeMint(msg.sender, amount);
  }

  function reserve(address recipient, uint256 amount) external onlyOwner {
    require((totalSupply() + amount) <= SUPPLY_LIMIT, "Out of supply");

    _safeMint(recipient, amount);
  }

  function withdraw() external {
    require(address(this).balance > 0, "No balance to withdraw");

    (bool success, ) = withdrawalAddress.call{ value: address(this).balance }("");
    require(success, "Failed to withdraw");
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}
