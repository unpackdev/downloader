pragma solidity ^0.7.6;

import "./Address.sol";
import "./ERC721.sol";
import "./Strings.sol";

interface MapElevationRetriever {
	function getElevation(uint8 col, uint8 row) external view returns (uint8);
}

interface Etheria{
	function getOwner(uint8 col, uint8 row) external view returns(address);
	function setOwner(uint8 col, uint8 row, address newowner) external;
}

contract InterfacedEtheriaV11 is ERC721 {

	using Address for address;
	using Strings for uint256;

    Etheria public etheria = Etheria(0x169332Ae7D143E4B5c6baEdb2FEF77BFBdDB4011);

    constructor() ERC721("Interfaced Etheria V1.1", "INTERFACEDETHERIAV1.1") {
		_setBaseURI("https://api.etheria.exchange/1.1/getTile/");
	}

    function _deindexify(uint index) view internal returns (uint8 col, uint8 row) {
        row = uint8(index % 33);
        col = uint8(index / 33);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        (uint8 col, uint8 row) = _deindexify(tokenId);
        return etheria.getOwner(col, row);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        uint balance = 0;
        for(uint8 i = 0; i < 33; i++) {
            for(uint8 j = 0; j < 33; j++) {
                balance = etheria.getOwner(i, j) == owner ? balance + 1 : balance;
            }
        }
        return balance;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return 457;
    }

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory base = baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

	function contractURI() public view returns (string memory) {
        return "https://api.etheria.exchange/1.1/storefront";
    }


	//------------------------------------------------------------------------------------------------
    //
    //

	function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
		emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        //require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return ownerOf(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return true;
    }

    //------------------------------------------------------------------------------------------------
    //
    //
     function _transfer(address to, uint8 col, uint8 row) internal {
         require(!to.isContract(), "ERC721: cannot transfer to a contract");
         require(to != address(0), "ERC721: transfer to the zero address");
         etheria.setOwner(col, row, to);
		 emit Transfer(tx.origin, to, uint(col)*33 + uint(row));

     }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        (uint8 col, uint8 row) = _deindexify(tokenId);
         require(tx.origin == ownerOf(tokenId), "ERC721: transfer caller is not owner");
        _transfer(to, col, row);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        (uint8 col, uint8 row) = _deindexify(tokenId);
         require(tx.origin == ownerOf(tokenId), "ERC721: transfer caller is not owner");
        _transfer(to, col, row);
    }
}
