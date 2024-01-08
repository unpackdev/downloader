// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";

contract ZerothNFT is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {

    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol, address owner) ERC721(name, symbol) {

        _setupRole(DEFAULT_ADMIN_ROLE, owner);

        _setupRole(MINTER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);
    }

    function mint(address to, string memory _tokenURI) public virtual returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "ZerothNFT: must have minter role to mint");

        uint256 tokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        return tokenId;
    }

    function mintAndApprove(string memory _tokenURI, address approveTo) public virtual returns (uint256) {
        uint256 tokenId = mint(_msgSender(), _tokenURI);
        ERC721.approve(approveTo, tokenId);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ZerothNFT: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ZerothNFT: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ZerothNFT: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ZerothNFT: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
