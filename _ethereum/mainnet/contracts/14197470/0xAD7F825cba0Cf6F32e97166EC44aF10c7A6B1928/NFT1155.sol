//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControlEnumerable.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";


contract NFT1155 is ERC1155, Ownable, RoyaltiesV2Impl, AccessControlEnumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    mapping (uint256 => string) private _tokenURIs;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    string public constant name = "PETPAWS";
    string public constant symbol = "PAWS";

    constructor() ERC1155("ipfs://f0") {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupRole(MINTER_ROLE, msg.sender);
      _tokenIdTracker.increment();
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mint(
      address to,
      uint256 amount,
      string memory _uri,
      address payable _royaltiesReceipientAddress,
      uint96 _percentageBasisPoints
    ) public virtual onlyRole(MINTER_ROLE)  {
      uint256 _tokenId = _tokenIdTracker.current();
      _mint(to, _tokenId, amount, "0x");
      _setTokenURI(_tokenId, _uri);
      _tokenIdTracker.increment();
      _setRoyalties(_tokenId,_royaltiesReceipientAddress,_percentageBasisPoints);
    }

    function mintBatch(
      address to,
      uint256[] memory amounts,
      string[] memory _uris,
      address payable _royaltiesReceipientAddress,
      uint96 _percentageBasisPoints
    ) public virtual onlyRole(MINTER_ROLE){

      require(_uris.length == amounts.length, "ERC1155: ids and amounts length mismatch");

      uint256[] memory ids = new uint256[](amounts.length);

      for (uint256 i = 0; i < _uris.length; i++) {
          uint256 _tokenId = _tokenIdTracker.current();
          _setTokenURI(_tokenId, _uris[i]);
          _tokenIdTracker.increment();
          _setRoyalties(_tokenId,_royaltiesReceipientAddress,_percentageBasisPoints);
          ids[i] = _tokenId;
      }

      _mintBatch(to, ids, amounts, '0x');
    }

    function _setRoyalties(uint256 _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControlEnumerable) returns (bool) {
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

    function uri(uint256 _tokenID) override public view returns (string memory) {
      return _tokenURIs[_tokenID];
    }

}
