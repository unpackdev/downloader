// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// Contracts
import "./ERC721Enumerable.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./Ownable.sol";

contract OdesseyPeptoshiNFT is ERC721PresetMinterPauserAutoId, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721PresetMinterPauserAutoId(_name, _symbol, _initBaseURI) {
    setBaseURI(_initBaseURI);

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    for (uint256 i = 0; i < 11; i++) {
      mint(_msgSender());
    }
    burn(0);
  }

  //only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : "";
  }
}
