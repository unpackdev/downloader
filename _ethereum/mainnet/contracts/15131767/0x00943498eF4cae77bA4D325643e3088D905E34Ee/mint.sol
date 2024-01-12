// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";


contract VXNFT is ERC721URIStorage, Ownable {

    using SafeMath for uint256;
	using Counters for Counters.Counter;

	Counters.Counter private _tokenIds;
    mapping(address => bool) public usersList;
    mapping(uint256 => address) public _tokenCreators;

	string public baseTokenURI;
	string public tokenURI;
	string public extention = ".json";

	uint256 public constant MAX_SUPPLY = 1001;

    
    constructor(string memory baseURI) ERC721("metasphere-vx", "METASPHERE VX") {
        setBaseURI(baseURI);
    }


    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
    
   	function mintNFTs() external returns (uint) {
        require(_tokenIds.current() < MAX_SUPPLY, "Not enough NFTs left!");
        require(!usersList[msg.sender], "Minter can mint only 1 NFT");

        _tokenCreators[_tokenIds.current()] = msg.sender;
        usersList[msg.sender] = true;
        _mintSingleNFT();
        return _tokenIds.current();
    }

    function _mintSingleNFT() private {
		_tokenIds.increment();
		uint256 newTokenID = _tokenIds.current();
		_safeMint(msg.sender, newTokenID);
        _setTokenURI(newTokenID, string(abi.encodePacked(baseTokenURI, uint2str(newTokenID), extention)));        
	}

    function getCreator(uint256 tokenId) external view returns (address) {
        return _tokenCreators[tokenId];
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     * openzeppelin/contracts/token/ERC721/ERC721Burnable.sol
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }

//    function _baseURI() internal view virtual override returns (string memory) {
// 		return baseTokenURI;
// 	}

	function setBaseURI(string memory _baseTokenURI) public onlyOwner {
		baseTokenURI = _baseTokenURI;
	}
}
