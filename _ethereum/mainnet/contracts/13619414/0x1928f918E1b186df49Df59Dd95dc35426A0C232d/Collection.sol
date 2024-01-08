// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract IliaZharkovCollection is ERC721Enumerable, AccessControl, Ownable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string private _contractUri;
    string private _baseTokenURI;

    event Mint(address recipient, uint256 tokenId);

    constructor(
        string memory contractUri_,
        string memory baseUri_
    ) public ERC721("Ilia Zharkov Collection", "IZH") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _contractUri = contractUri_;
        _baseTokenURI = baseUri_;
    }

    // returns last minted token id
    function currentTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function updateContractURI(string memory contractUri_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractUri = contractUri_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function updateBaseURI(string memory baseUri_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseUri_;
    }

    // public mint
    function mint(
        uint256 amount,
        address recipient
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            _mint(recipient, newTokenId);

            emit Mint(recipient, newTokenId);
        }
    }

    // let owners to burn their tokens
    function burn(uint256 tokenId) public {
        require(_msgSender() == ownerOf(tokenId), "Can be burned only by token owner");
        _burn(tokenId);
    }

    // See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
