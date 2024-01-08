pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";


interface XMONS {
  function balanceOf(address) external view returns (uint256);
  function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
}

contract EmbodimentOfCommunity is Context, AccessControlEnumerable, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;

    mapping (uint => bool) public _claimed;

    XMONS public xmons = XMONS(0x0427743DF720801825a5c82e0582B1E915E0F750);
    uint public endTimestamp;

    constructor(
        string memory name,
        string memory symbol, 
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        endTimestamp = block.timestamp + 1 weeks;
    }

    function changeBaseURI(string memory baseTokenURI) onlyRole(DEFAULT_ADMIN_ROLE) public {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function canClaim(address claimer) view public returns (bool) {
      uint balance = xmons.balanceOf(claimer);
      bool claimable = true;
      if (block.timestamp >= endTimestamp) return false;
      for (uint i = 0; i < balance; i++) {
        uint tokenId = xmons.tokenOfOwnerByIndex(claimer, i);
        claimable = claimable || (!_claimed[tokenId]);
      }
      return claimable;
    }

    function claim() public {
      require(canClaim(_msgSender()), "CLAIM:CANT CLAIM");
      uint balance = xmons.balanceOf(_msgSender());
      for (uint i = 0; i < balance; i++) {
        uint tokenId = xmons.tokenOfOwnerByIndex(_msgSender(), i);
        _claimed[tokenId] = true;
      }
      _safeMint(_msgSender(), _tokenIdTracker.current());
      _tokenIdTracker.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}