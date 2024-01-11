//	SPDX-License-Identifier: MIT
/// @title  Background Logo Elements
/// @notice Generative on-chain SVG
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IDescriptor {
  function getSvg(uint256 tokenId) external view returns (string memory);
  function getSvgFromSeed(uint256 seed) external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract BackgroundLogoElement is ERC721A, ReentrancyGuard, Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  address public descriptorAddress;
  IDescriptor public descriptor;

  bool public mintIsActive = false;

  uint256 price = 0.02 ether;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, "Contract is sealed");
    _;
  }

  constructor() ERC721A('Backgrounds by Logo', 'BACKGROUND', 100) Ownable() {
  }

  /// @notice Sets price for mint, initially set at 0 ether
  /// @param _price, the new price
  function setPrice(uint256 _price) external onlyOwner onlyWhileUnsealed {
    price = _price;
  }

  function setDescriptorAddress(address _address) external onlyOwner onlyWhileUnsealed {
    descriptorAddress = _address;
    descriptor = IDescriptor(_address);
  }

  function mint(uint256 quantity) external payable nonReentrant {
    require(mintIsActive, 'Mint is not active');
    require(totalSupply() + quantity <= 10000, 'Exceeded supply');
    require(quantity <= 10, 'Only 10 tokens can be minted at once');
    require(msg.value == price * quantity, 'Incorrect eth amount sent');
    require(msg.sender == tx.origin, 'Contract cannot mint');

    _safeMint(msg.sender, quantity);
  }

  /// @notice Owner mint, allows owner to mint tokens up to 100 at a time
  /// @param to, address list to mint to
  /// @param quantity, number of tokens to mint
  function mintAdmin(address[] memory to, uint256 quantity) external onlyOwner nonReentrant {
    for (uint i; i < to.length; i++) {
      require(totalSupply() + quantity <= 10000, "Exceeded Supply");
      _safeMint(to[i], quantity);
    }
  }

  /// @notice Toggles the mint state
  function toggleMint() external onlyOwner onlyWhileUnsealed {
    mintIsActive = !mintIsActive;
  }

  /// @notice Specifies whether or not non-owners can use a token for their logo layer
  /// @dev Required for any element used for a logo layer
  function mustBeOwnerForLogo() external view returns (bool) {
    return true;
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    return descriptor.getSvg(tokenId);
  }

  function getSvgFromSeed(uint256 seed) public view returns (string memory) {
    return descriptor.getSvgFromSeed(seed);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return descriptor.tokenURI(tokenId);
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }

  function sendValue(address payable recipient, uint256 amount) external onlyOwner {
    require(address(this).balance >= amount, 'Address: insufficient balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}