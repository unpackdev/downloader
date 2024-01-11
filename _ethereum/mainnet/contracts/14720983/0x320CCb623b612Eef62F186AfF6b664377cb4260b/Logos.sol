//	SPDX-License-Identifier: MIT
/// @title  Logos
/// @notice Configurable logo containers which fetch on-chain assets to compose an SVG
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./LogoModel.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


/*
      ___       ___           ___           ___           ___     
     /\__\     /\  \         /\  \         /\  \         /\  \    
    /:/  /    /::\  \       /::\  \       /::\  \       /::\  \   
   /:/  /    /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\ \  \  
  /:/  /    /:/  \:\  \   /:/  \:\  \   /:/  \:\  \   _\:\ \ \  \ 
 /:/__/    /:/__/ \:\__\ /:/__/ \:\__\ /:/__/ \:\__\ /\ \:\ \ \__\
 \:\  \    \:\  \ /:/  / \:\  /\ \/__/ \:\  \ /:/  / \:\ \:\ \/__/
  \:\  \    \:\  /:/  /   \:\ \:\__\    \:\  /:/  /   \:\ \:\__\  
   \:\  \    \:\/:/  /     \:\/:/  /     \:\/:/  /     \:\/:/  /  
    \:\__\    \::/  /       \::/  /       \::/  /       \::/  /   
     \/__/     \/__/         \/__/         \/__/         \/__/   
*/

interface ILogoDescriptor {
  function getMetaDataForKeys(uint tokenId, string[] memory keys) external returns (string[] memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function getSvg(uint256 tokenId) external view returns (string memory);
  function getLogoSvg(Model.Logo memory logo, string memory overrideTxt, string memory overrideFont, string memory overrideFontLink) external view returns (string memory);
}

contract Logos is ERC721A, ReentrancyGuard, Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  bool public mintIsActive = false;
  uint256 public nextTokenId = 0;

  address public logoDescriptorAddress;
  ILogoDescriptor public logoDescriptor;
  
  uint256 price = 0 ether;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, 'Contract is sealed');
    _;
  }

  constructor() ERC721A('Deglomerate Logos', 'LOGO', 10) Ownable() {}


  /// @notice Sets price of a logo container, initially set at 0 ether
  /// @param _price, the new price of a logo container
  function setPrice(uint256 _price) external onlyOwner onlyWhileUnsealed {
    price = _price;
  }

  /// @notice Sets the address of the contract which manages the logos
  function setDescriptorAddress(address _address) external onlyOwner onlyWhileUnsealed {
    logoDescriptorAddress = _address;
    logoDescriptor = ILogoDescriptor(_address);
  }

  /// @notice Mints a new logo container
  /// @param quantity, number of logo containers to mint
  function mint(uint256 quantity) external payable nonReentrant {
    require(mintIsActive, 'Mint is not active');
    require(msg.value == price * quantity, 'Incorrect eth amount sent');
    require(quantity <= 10, 'Cannot mint more than 10');
    require(msg.sender == tx.origin, 'Contract cannot mint');
    _safeMint(msg.sender, quantity);
  }

  /// @notice Owner mint, allows owner to mint tokens up to 10 at a time
  /// @param to, address list to mint to
  /// @param quantity, number of tokens to mint
  function mintAdmin(address[] memory to, uint256 quantity) external onlyOwner nonReentrant onlyWhileUnsealed {
    for (uint i; i < to.length; i++) {
      _safeMint(to[i], quantity);
    }
  }

  /// @notice Toggles the mint state
  function toggleMint() external onlyOwner onlyWhileUnsealed {
    mintIsActive = !mintIsActive;
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return logoDescriptor.tokenURI(tokenId);
  }

  /// @notice Returns svg of a specified logo
  /// @param tokenId, logo container tokenId
  function getSvg(uint256 tokenId) public view returns (string memory) {
    return logoDescriptor.getSvg(tokenId);
  }

  /// @notice Returns svg of a logo with given configuration, used for preview purposes
  /// @param logo, configuration of logo which svg should be generated
  /// @param overrideTxt, text to use for the text element of the logo
  /// @param overrideFont, font to use for the text element of the logo, optional - use emptry string for default
  /// @param overrideFontLink, a url with the font specification for the chosen font, optional - use emptry string for default
  function getLogoSvg(Model.Logo memory logo, string memory overrideTxt, string memory overrideFont, string memory overrideFontLink) public view returns (string memory) {
    return logoDescriptor.getLogoSvg(logo, overrideTxt, overrideFont, overrideFontLink);
  }

  /// @notice Returns specified logo metadata
  function getMetaDataForKeys(uint tokenId, string[] memory keys) public returns (string[] memory) {
    return logoDescriptor.getMetaDataForKeys(tokenId, keys);
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }

  function sendValue(address payable recipient, uint256 amount) external onlyOwner {
    require(address(this).balance >= amount, 'Address: insufficient balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Unable to send value, recipient may have reverted');
  }
}