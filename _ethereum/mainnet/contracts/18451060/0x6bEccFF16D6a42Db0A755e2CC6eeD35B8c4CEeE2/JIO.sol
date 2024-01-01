// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC721AUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC2981.sol";

error RevealLimitExceeded();
error RevealNotActive();
error NotOwnerOfTokens();
error UnapprovedForTokenTransfer();
error BaseTokenURINotSet();

contract JIO is ERC721AUpgradeable, OwnableUpgradeable, ERC2981 {
  address public constant CAPSULE_CONTRACT_ADDRESS = 0xaD858bB4fb0A65AA5D5678e5977Cc6247f693E26;
  address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
  
  string private baseTokenURI;
  bool public revealActive;
  uint256 public revealLimit;

  function initialize() initializerERC721A initializer public {
    __ERC721A_init('JIO', 'JIO');
    __Ownable_init();
    _setDefaultRoyalty(msg.sender, 500);
    revealActive = false;
    revealLimit = 10;
  }

  event RevealMinted(address indexed from, uint256 tokenIdBeforeMint, uint256 tokensMinted);

  function revealNFT(uint256[] calldata tokenIds) external {
    if (!revealActive) revert RevealNotActive();
    if (tokenIds.length > revealLimit) revert RevealLimitExceeded();
    IERC721AUpgradeable capsuleContract = IERC721AUpgradeable(CAPSULE_CONTRACT_ADDRESS);
    if (!capsuleContract.isApprovedForAll(msg.sender, address(this))) revert UnapprovedForTokenTransfer();
    for (uint256 i; i < tokenIds.length; i++) {
      address tokenOwner = capsuleContract.ownerOf(tokenIds[i]);
      if (tokenOwner != msg.sender) revert NotOwnerOfTokens();
    }
    for (uint256 i; i < tokenIds.length; i++) {
      capsuleContract.transferFrom(msg.sender, burnAddress, tokenIds[i]);
    }
    uint256 tokenIdBeforeMint = totalSupply();
    _safeMint(msg.sender, tokenIds.length, "");
    emit RevealMinted(msg.sender, tokenIdBeforeMint, tokenIds.length);
  }

  function setRevealActive(bool value) external onlyOwner {
    if (value && bytes(baseTokenURI).length == 0) revert BaseTokenURINotSet();
    revealActive = value;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function setRevealLimit(uint256 number) external onlyOwner {
    revealLimit = number;
  }

  function tokenURI(uint256 tokenId) public view virtual override (ERC721AUpgradeable) returns (string memory) {
    return string(abi.encodePacked(baseTokenURI, _toString(tokenId), '.json'));
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (ERC721AUpgradeable, ERC2981)
    returns (bool)
  {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }
}
