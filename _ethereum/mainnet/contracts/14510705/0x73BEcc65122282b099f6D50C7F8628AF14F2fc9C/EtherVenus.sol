// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./base64.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract EtherVenus is  ERC721,ERC721URIStorage, Ownable, RoyaltiesV2Impl,ERC721Enumerable {
  uint256 public tokenCounter;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;
  Counters.Counter private supply;

  uint256 public maxSupply;

    event CreatedEtherVenus(uint256 indexed tokenId, string tokenURI);
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    constructor() ERC721("EtherVenus", "ETHV")
    {
        tokenCounter = 1;
        maxSupply = 777;
    }

   function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

    function mint(address _to) public onlyOwner {
        super._mint(_to, _tokenIdTracker.current());
        _tokenIdTracker.increment();        
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
        
    {
        return super.tokenURI(tokenId);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
        }
        return (address(0), 0);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function create(string memory svg) public {
        require(_tokenIdTracker.current() < maxSupply, "Total supply reached");
        _tokenIdTracker.increment();
        _safeMint(msg.sender, tokenCounter);
        string memory imageURI = svgToImageURI(svg);
        _setTokenURI(tokenCounter, formatTokenURI(imageURI));
        tokenCounter = tokenCounter + 1;
        emit CreatedEtherVenus(tokenCounter, svg);
    }

    // You could also just upload the raw SVG and have solildity convert it!
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        // example:
        // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
        // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI) public pure returns (string memory) {
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "", // You can add whatever name here
                                '", "description":"EtherVenus is an on-chain art collection.", "attributes":"", "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    }
}