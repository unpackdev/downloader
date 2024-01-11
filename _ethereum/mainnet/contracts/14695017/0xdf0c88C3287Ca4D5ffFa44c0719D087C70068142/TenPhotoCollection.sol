/// @title Photo collection 
/// @author Transmental
/// @notice Change this contract at will to fit your needs
/// @dev DadlessNsad || 0xOrphan

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
// import "./IERC165.sol";

contract Foundnone is ERC721A, Ownable {

  bool public paused = true;

  string public baseURI;
  string public baseExtension = ".json";

  uint256 public maxSupply = 4;

  constructor(string memory _baseURI, uint256 _amount) ERC721A("SaddleMountain", "FSM") {
    baseURI = _baseURI;
    _preMint(_amount);
    // _registerInterface(_INTERFACE_ID_ERC2981);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setBaseExtension(string memory _baseExtension) public onlyOwner {
    baseExtension = _baseExtension;
  }

  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    maxSupply = _newMaxSupply;
  }

  function _preMint(uint256 _amount) private {
    require(_amount <= maxSupply, "Max Supply Reached");
    _safeMint(msg.sender, _amount);
  } 


  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(
      abi.encodePacked(
        baseURI,
        Strings.toString(_tokenId),
        baseExtension
      )
    );
  }

  // Delete this function if you want tokenId to start at 0
  function _startTokenId() internal view override virtual returns (uint256) {
    return 1;
  }

}
