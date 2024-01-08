// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ierc721.sol";
import "./sprite.sol";

contract NFToken is sprite,IERC721Metadata,IERC721Enumerable {
	
	//In order to get friendly tips
    string constant ZERO_ADDRESS = "ZERO_ADDRESS";
	string constant INDEX_BIG_THAN_BALANCE = "INDEX_BIG_THAN_BALANCE";
	string constant CANT_TRANSFER_TO_YOURSELF = "CANT_TRANSFER_TO_YOURSELF";
	string constant NOT_VALID_NFT = "NOT_VALID_NFT";
	string constant NTF_STATUS_CANT_TO_SEND = "NTF_STATUS_CANT_TO_SEND";
	string constant NOT_OWNER_APPROVED_OR_OPERATOR = "NOT_OWNER_APPROVED_OR_OPERATOR";
	string constant NOT_OWNER_OR_OPERATOR = "NOT_OWNER_OR_OPERATOR";
	string constant IS_OWNER = "IS_OWNER";

	mapping (uint=>address) idToApproval; 
	mapping(address=>mapping(address=>bool)) ownerToOperators; 

	
    mapping(address => mapping(uint256 => uint256)) private OwnedTokens;
    mapping(uint256 => uint256) private OwnedTokensIndex;

	mapping(address => uint256) private NTFBalances;


	function supportsInterface(bytes4 interfaceId) public pure override  returns (bool) {
        return interfaceId == hex"01ffc9a7" || interfaceId == hex"80ac58cd" || interfaceId == hex"780e9d63" || interfaceId == hex"5b5e139f";  
    }
	
	
    function name() public pure  override returns (string memory) {
        return "Pixel Universe Sprite";
    }

	
    function symbol() public pure  override returns (string memory) {
        return "PUS";
    }

	//Decompression demo program https://github.com/pixeluniverselab/sprite_decompression
	function tokenURI(uint256 tokenId) public view  override  returns (string memory){
		
		string memory compressedImage = Base64.encode(getSpriteImage(tokenId));
		
		spriteAttribute memory spa = getSpriteAttribute(tokenId);
		spriteBody memory spb = getSpriteBody(tokenId);
		
		string memory spriteaAttar = string(abi.encodePacked('{"speed":',_toString(spa.speed),',"capacity":',_toString(spa.capacity),',"space":',_toString(spa.space),',"color_1":',_toString(spa.color_1),',"color_2":',_toString(spa.color_2),',"color_3":',_toString(spa.color_3),',"color_4":',_toString(spa.color_4),'}'));
		string memory spriteaBody = string(abi.encodePacked('{"trunkIndex":',_toString(spb.trunkIndex),',"headIndex":',_toString(spb.headIndex),',"eyeIndex":',_toString(spb.eyeIndex),',"mouthIndex":',_toString(spb.mouthIndex),',"tailIndex":',_toString(spb.tailIndex),',"colorContainerIndex":',_toString(spb.colorContainerIndex),',"skinColorIndex":',_toString(spb.skinColorIndex),'}'));

		string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Sprite #', _toString(tokenId), '","description": "Pixel sprite is a metaverse game. All information of the sprite, including image data, is completely stored on the chain. The picture is stored on the chain using a compression algorithm", "attribute": ',spriteaAttar,', "body": ',spriteaBody,', "image": "data:image/compressed_png;Base64,', compressedImage,'"}'))));
		
	
		return string(abi.encodePacked('data:application/json;base64,', json));
	}

	
    function totalSupply() public view  override returns (uint256) {
        return SpriteCount;
    }


	//tokenID start at 1
    function tokenByIndex(uint256 index) public pure  override returns (uint256) {
        return index+1;
    }


	function balanceOf(address _owner) external override view returns (uint256){
		require(_owner != address(0), ZERO_ADDRESS);
		return NTFBalances[_owner];
	}

	
	function ownerOf(uint256 _tokenId) external override view returns (address _owner){
		_owner = SpriteList[_tokenId].owner;
		require(_owner != address(0), ZERO_ADDRESS);
	}

	
    function tokenOfOwnerByIndex(address owner, uint256 index) public view  override returns (uint256) {
		require(NTFBalances[owner] > index, INDEX_BIG_THAN_BALANCE); //不曾拥有该TOken

		return OwnedTokens[owner][index];
    }

	
	function transferFrom(address _from, address _to, uint256 _tokenId) external override   {
		require(_from != _to, CANT_TRANSFER_TO_YOURSELF);  

		address tokenOwner = SpriteList[_tokenId].owner; 
		require(tokenOwner != address(0), NOT_VALID_NFT); 
       
        require(tokenOwner == _from, NOT_OWNER_OR_OPERATOR); 

		require(getSpriteStatus(_tokenId)==1,NTF_STATUS_CANT_TO_SEND); //Only when the sprite is idle can you transfer money

		
		require(tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender || ownerToOperators[tokenOwner][msg.sender],NOT_OWNER_APPROVED_OR_OPERATOR);
		
		require(_to != address(0), ZERO_ADDRESS);
		
		

		changeOwner(_tokenId,_to); 
		
		emit Transfer(_from, _to, _tokenId);
	}

	
	
	function approve(address _approved, uint256 _tokenId) external override  {
		address tokenOwner = SpriteList[_tokenId].owner;

		require(
			tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
			NOT_OWNER_OR_OPERATOR
		);

		require(tokenOwner != address(0), NOT_VALID_NFT);

		require(_approved != tokenOwner, IS_OWNER);

		idToApproval[_tokenId] = _approved;
		emit Approval(tokenOwner, _approved, _tokenId);
	}

	
	function setApprovalForAll(address _operator,bool _approved)external override{
		ownerToOperators[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
  	}

	
	function getApproved(uint256 _tokenId) external override view returns (address){
		address tokenOwner = SpriteList[_tokenId].owner;
		require(tokenOwner != address(0), NOT_VALID_NFT);

    	return idToApproval[_tokenId];
  	}

	
	function isApprovedForAll(address _owner,address _operator) external override view returns (bool) {
    	return ownerToOperators[_owner][_operator];
  	}

	
	function _clearApproval(uint256 _tokenId) private{
    	delete idToApproval[_tokenId];
  	}

	
	function _toString(uint256 value) internal pure returns (string memory) {
    	
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }  

	function changeOwner(uint256 _spriteID,address _newOwner) internal {
		address oldOwner = SpriteList[_spriteID].owner;

		_removeTokenFromOwnerEnumeration(oldOwner,_spriteID);
		_addTokenToOwnerEnumeration(_newOwner,_spriteID);

		SpriteList[_spriteID].owner = _newOwner;

		NTFBalances[oldOwner] -= 1; 
		NTFBalances[_newOwner] += 1;

		_clearApproval(_spriteID);

	}

	
	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		

        uint256 length = NTFBalances[to];
        OwnedTokens[to][length] = tokenId;
        OwnedTokensIndex[tokenId] = length;
    }


	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		

        uint256 lastTokenIndex = NTFBalances[from] - 1;
        uint256 tokenIndex = OwnedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = OwnedTokens[from][lastTokenIndex];

            OwnedTokens[from][tokenIndex] = lastTokenId; 
            OwnedTokensIndex[lastTokenId] = tokenIndex; 
        }

        delete OwnedTokensIndex[tokenId];
        delete OwnedTokens[from][lastTokenIndex];
    }

	function addHolderTokens(address _owner,uint256 index) internal {
		_addTokenToOwnerEnumeration(_owner,index);
		NTFBalances[_owner] += 1; 
	}


  
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
