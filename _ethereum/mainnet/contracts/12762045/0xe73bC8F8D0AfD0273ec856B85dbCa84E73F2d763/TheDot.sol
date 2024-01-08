pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract TheDot is Context, Ownable, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    string private _encodedJSON;


    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, 0xD2927a91570146218eD700566DF516d67C5ECFAB);
    }

    function changeEncodedJSON(string memory encodedJSON) onlyRole(DEFAULT_ADMIN_ROLE) public {
        _encodedJSON = encodedJSON;
    }

    function mint() public {
      require(totalSupply() < 10000, "MINT:NO MO' FREE WEI FOR YOU");
      _safeMint(_msgSender(), _tokenIdTracker.current());
      _tokenIdTracker.increment();
      payable(_msgSender()).transfer(1 wei);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _encodedJSON;
    }

    function fund() payable public onlyRole(DEFAULT_ADMIN_ROLE) {
      //do nothing
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}