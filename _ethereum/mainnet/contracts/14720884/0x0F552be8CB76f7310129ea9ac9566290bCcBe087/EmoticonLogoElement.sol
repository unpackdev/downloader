//	SPDX-License-Identifier: MIT
/// @title  Emoticon Logo Elements
/// @notice On-chain SVG
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./LogoHelper.sol";
import "./SvgText.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IDescriptor {
  function txtVals(uint256 tokenId) external view returns (string memory);
  function txtFonts(uint256 tokenId) external view returns (string memory link, string memory name);
  function getSvg(uint256 tokenId) external view returns (string memory);
  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) external view returns (string memory);
  function getSvgFromSeed(uint256 seed, string memory txt, string memory font, string memory fontLink) external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function setTxtVal(uint256 tokenId, string memory val) external;
  function setFont(uint256 tokenId, string memory link, string memory font) external;
}


contract EmoticonLogoElement is ERC721A, ReentrancyGuard, Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  address public descriptorAddress;
  IDescriptor public descriptor;

  bool public mintIsActive = false;

  uint256 price = 0 ether;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, "Contract is sealed");
    _;
  }

  constructor() ERC721A('Emoticons by Logo', 'EMOTICON', 100) Ownable() {
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
    require(totalSupply() + quantity <= 500, 'Exceeded supply');
    require(quantity <= 2, 'Only 2 tokens can be minted at once');
    require(msg.value == price * quantity, 'Incorrect eth amount sent');
    require(msg.sender == tx.origin, 'Contract cannot mint');

    _safeMint(msg.sender, quantity);
  }

  /// @notice Owner mint, allows owner to mint tokens up to 100 at a time
  /// @param to, the address to mint to
  /// @param quantity, number of tokens to mint
  function mintAdmin(address to, uint256 quantity) external onlyOwner nonReentrant {
    require(totalSupply() + quantity <= 500, "Exceeded Supply");
    _safeMint(to, quantity);
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

  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) public view returns (string memory) {
    return descriptor.getSvg(tokenId, txt, font, fontLink);
  }

  function getSvgFromSeed(uint256 seed, string memory txt, string memory font, string memory fontLink) public view returns (string memory) {
    return descriptor.getSvgFromSeed(seed, txt, font, fontLink);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return descriptor.tokenURI(tokenId);
  }

  function getTxtVal(uint256 tokenId) public view returns (string memory) {
    return descriptor.txtVals(tokenId);
  }

  function getTxtFont(uint256 tokenId) public view returns (string memory link, string memory name) {
    (link, name) = descriptor.txtFonts(tokenId);
    return (link, name);
  }

  function setTxtVal(uint256 tokenId, string memory val) public {
    descriptor.setTxtVal(tokenId, val);
  }

  function setFont(uint256 tokenId, string memory link, string memory font) public {
    descriptor.setFont(tokenId, link, font);
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