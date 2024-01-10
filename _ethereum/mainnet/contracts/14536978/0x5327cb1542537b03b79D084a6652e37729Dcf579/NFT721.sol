//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";


contract NFT721 is ERC721, Ownable, RoyaltiesV2Impl, AccessControlEnumerable {
    mapping (uint256 => string) private _tokenURIs;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() ERC721("Metasense", "PLOT") {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupRole(MINTER_ROLE, msg.sender);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "Nfttoken: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nfttoken: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function mint(
      address _to,
      uint256 tokenId,
      string memory _tokenURI,
      address payable _royaltiesReceipientAddress,
      uint96 _percentageBasisPoints) public onlyRole(MINTER_ROLE) {
        require(!_exists(tokenId), "Nfttoken: token already exist");
        super._mint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _setRoyalties(tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
    }

    function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControlEnumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981){
          return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount){
      LibPart.Part[] memory _royalties = royalties[_tokenId];
      if(_royalties.length > 0){
        return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
      }
      return (address(0), 0);
    }

}
