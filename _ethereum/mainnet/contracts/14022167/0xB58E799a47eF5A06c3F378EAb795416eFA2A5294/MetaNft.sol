// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMetaNft.sol";

contract MetaNft is IMetaNft, Ownable, ERC721 {
	string private _uri;
	uint256 private _tokenId=0;
	mapping(uint256 => uint256) private _tokenIds;	// tokenId: level
	uint8 private _tokenURIFlag = 0;
	address private _metaBox;

	modifier onlyMetaBox() {
		require(msg.sender == _metaBox, "Only metabox");
		_;
	}

	constructor (string memory name, string memory symbol) public ERC721(name, symbol) {
		_tokenURIFlag = 0;
	}

	function mint(address to, uint256 level, uint256 startIndex, uint256 minted) public override onlyMetaBox returns (uint256) {
		uint256 tokenId = _tokenId + startIndex + minted;
		_mint(to, tokenId);
		_tokenIds[tokenId] = level;

		return tokenId;
	}

	function burn(uint256 tokenId) public onlyMetaBox override {
		address owner = ERC721.ownerOf(tokenId);
		require(tx.origin == owner, "Burn: Not token owner");
		require(_exists(tokenId), "Burn: token not exist");
		_burn(tokenId);
	}

	function setBaseURI(string memory baseURI) public override onlyOwner {
		require(bytes(baseURI).length > 0, "Invalid baseURI");
		_uri = baseURI;
	}

	function baseURI() public override view returns (string memory) {
		return _uri;
	}

	/**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_tokenURIFlag == 1) {
        	tokenId = _tokenIds[tokenId];
        }
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }

    function setTokenURIFlag(uint8 newURIFlag) public onlyOwner {
    	require(newURIFlag != _tokenURIFlag, "Cannt set same");
    	require(newURIFlag == 0 || newURIFlag == 1, "Invalid newURIFlag");

    	_tokenURIFlag = newURIFlag;
    }

    function tokenURIFlag() public view returns (uint8) {
    	return _tokenURIFlag;
    }

    function setMetaBox(address _newMetaBox) public onlyOwner {
    	require(_newMetaBox != address(0), "Metabox cannt zero address");

    	_metaBox = _newMetaBox;
    }

    function metaBox() public view returns (address) {
    	return _metaBox;
    }
}
