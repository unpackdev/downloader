// SPDX-License-Identifier: MIT

// Lazy Serum Claim Developed for Lazy LongHorns

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

abstract contract LLH is ERC721Enumerable, Ownable {}

contract LazySerum is ERC721A, Ownable  {
    using SafeMath for uint256;
    using Strings for uint256;
    LLH public llh;
    string public baseTokenURI;
    mapping(uint256 => bool) public claimed;
	bool public claimWindowStatus = false;

    constructor() ERC721A("Lazy Serum", "LLHSerum") { }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setLLHAddress(address _addr) external onlyOwner {
        llh = LLH(_addr);
    }
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function claim(uint256[] memory tokenIds) external callerIsUser {
		require(claimWindowStatus,"Claim window not open");
        uint len = tokenIds.length;
        for(uint i; i < len; i++) {
            require(msg.sender == llh.ownerOf(tokenIds[i]), "Caller not owner of LLH tokenId.");
            require(!claimed[tokenIds[i]],"Vial already claimed");
            claimed[tokenIds[i]] = true;
        }

        _safeMint(msg.sender, len);

    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getLLHowner(uint256 tokenId) external callerIsUser view returns(address) {
        return llh.ownerOf(tokenId);
    }

	 function flipClaimWindowStatus() public onlyOwner {
        claimWindowStatus = !claimWindowStatus;
    }
}
