//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract EtherIcons is ERC721, Ownable, RoyaltiesV2Impl {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  using Strings for uint256;

  event PermanentURI(string _value, uint256 indexed _id);

  mapping(uint256 => string) private _tokenURIs;
  mapping(uint256 => string) private _tokenNAMEs;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721("EtherIcons", "EIC") {}

  function mint(address _to, string memory _tokenURI)
    public
    onlyOwner
    returns (uint256)
  {
    uint256 newItemId = _tokenIds.current();
    _tokenIds.increment();
    _safeMint(_to, newItemId);
    _setTokenURI(newItemId, _tokenURI);
    emit PermanentURI(_tokenURI, newItemId);

    return (newItemId);
  }

  function contractURI() public pure returns (string memory) {
    return
      "https://gateway.ipfs.io/ipfs/QmPtuhjhtFtMv2sUS4VxcLitLSK5ntRRzBSzSJ53wUHKoJ";
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: Cant read because _tokenId doesnt exist."
    );
    string memory _tokenURI = _tokenURIs[_tokenId];
    return
      string(
        abi.encodePacked(
          abi.encodePacked("https://gateway.ipfs.io/ipfs/", _tokenURI)
        )
      );
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
    _tokenURIs[tokenId] = _tokenURI;
  }

  function tokenNAME(uint256 _tokenId) public view returns (string memory) {
    require(
      _exists(_tokenId),
      "ERC721Metadata: _tokenNAME with _tokenId doesnt exist."
    );
    string memory _tokenNAME = _tokenNAMEs[_tokenId];
    return string(abi.encodePacked(_tokenNAME));
  }

  function _setTokenNAME(uint256 tokenId, string memory _tokenNAME) public {
    require(_exists(tokenId), "ERC721Metadata: _tokenId doesnt exist.");
    require(
      msg.sender == ownerOf(tokenId),
      "ERC721Metadata: you are not owner."
    );
    string memory __tokenNAME = _tokenNAMEs[tokenId];
    require(
      bytes(__tokenNAME).length == 0,
      "ERC721Metadata: _tokenNAME for _tokenId already set."
    );
    _tokenNAMEs[tokenId] = _tokenNAME;
  }

  function setRoyalties(
    uint256 _tokenId,
    address payable _royaltiesReceipientAddress,
    uint96 _percentageBasisPoints
  ) public onlyOwner {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesReceipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if (_royalties.length > 0) {
      return (
        _royalties[0].account,
        (_salePrice * _royalties[0].value) / 10000
      );
    } else {
      return (address(0), 0);
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }
}
