// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LuckyLlamas is ERC721, Ownable {
    using SafeMath for uint256;

    struct Whitelist {
        bool approved;
        uint256 minted;
    }

    uint256 constant public TOTAL_TOKEN_TO_MINT = 11777;
    uint256 constant public OWNER_MINT = 111;
    uint256 constant public WHITELIST_MINT_PER_USER = 5;
    uint256 constant public PUBLIC_MINT_PER_USER = 10;
    uint256 constant public ITEM_PRICE = 0.0777 ether; // 0.0777 ETH;
	uint256 public mintedTokens;
    uint256 public startingIpfsId;
    uint256 private _lastIpfsId;
    address public fundWallet;
    bool public isSaleActive;
    bool public isPreSaleActive;

    mapping(address => Whitelist) public whitelistInfo;

    modifier beforeMint(uint256 _howMany, uint256 _limit) {
	    require(_howMany > 0, "LuckyLlamas: Minimum 1 tokens need to be minted");
	    require(_howMany <= tokenRemainingToBeMinted(), "LuckyLlamas: Mint amount is greater than the token available");
		require(_howMany <= _limit, "LuckyLlamas: Max tokens at once limit reached");
		require(ITEM_PRICE.mul(_howMany) == msg.value, "LuckyLlamas: Insufficient ETH to mint");
        require(!_isContract(msg.sender), "LuckyLlamas: Caller cannot be contract");
        _;
    }

    constructor (string memory _tokenBaseUri, address _fundWallet) ERC721("Lucky Llamas", "LL") {
        _setBaseURI(_tokenBaseUri);
        fundWallet = _fundWallet;
    }

    ////////////////////
    // Action methods //
    ////////////////////

	function mintLuckyLlamas(uint256 _howMany) beforeMint(_howMany, PUBLIC_MINT_PER_USER) external payable {
        require(isSaleActive, "LuckyLlamas: Sale is not active");
		for (uint256 i = 0; i < _howMany; i++) {
			_mintLuckyLlamas(_msgSender());
		}
	}

    function presaleMint(uint256 _howMany) beforeMint(_howMany, WHITELIST_MINT_PER_USER) external payable {
        require(isPreSaleActive, "LuckyLlamas: Presale is not active");
	    require(isWhitelisted(_msgSender()), "LuckyLlamas: You are not whitelist to mint in presale");
        require(whitelistUserMint(_msgSender()) < WHITELIST_MINT_PER_USER, "LuckyLlamas: Presale max limit reached");
		for (uint256 i = 0; i < _howMany; i++) {
            require(whitelistUserMint(_msgSender()) < WHITELIST_MINT_PER_USER, "LuckyLlamas: Presale max limit reached");
            _mintLuckyLlamas(_msgSender());
            whitelistInfo[_msgSender()].minted++;
		}
	}

    function mintToOwner(address _to) external onlyOwner {
        require(mintedTokens < OWNER_MINT, "LuckyLlamas: Owner already minted");
		for (uint256 i = 1; i <= OWNER_MINT; i++) {
            require(!_exists(i), "LuckyLlamas: Token already exist.");
            _mint(_to, i);
		}
        mintedTokens = mintedTokens + OWNER_MINT;
	}
    
    function _mintLuckyLlamas(address _to) private {
        if(mintedTokens == 111) {
            _lastIpfsId = random(112, TOTAL_TOKEN_TO_MINT, uint256(uint160(address(_msgSender()))) + 1);
            startingIpfsId = _lastIpfsId;
        } else {
            _lastIpfsId = getIpfsIdToMint();
        }
        mintedTokens++;
        require(!_exists(mintedTokens), "LuckyLlamas: Token already exist.");
        _mint(_to, mintedTokens);
        _setTokenURI(mintedTokens, uint2str(_lastIpfsId));
    }
	
	function _isContract(address _addr) private view returns (bool) {
        uint32 _size;
        assembly {
            _size := extcodesize(_addr)
        }
        return (_size > 0);
    }

    function uint2str(uint256 _i) private pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "LuckyLlamas: token does not exist.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "LuckyLlamas: caller is not owner nor approved");
        _burn(tokenId);
    }

    ///////////////////
    // Query methods //
    ///////////////////

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelistInfo[_address].approved;
    }

    function whitelistUserMint(address _address) public view returns(uint256) {
        return whitelistInfo[_address].minted;
    }
    
    function tokenRemainingToBeMinted() public view returns (uint256) {
        return TOTAL_TOKEN_TO_MINT.sub(mintedTokens);
    }

    function isAllTokenMinted() public view returns (bool) {
        return mintedTokens == TOTAL_TOKEN_TO_MINT;
    }

    function getIpfsIdToMint() public view returns(uint256 _nextIpfsId) {
        require(!isAllTokenMinted(), "LuckyLlamas: All tokens have been minted");
        if(_lastIpfsId == TOTAL_TOKEN_TO_MINT && mintedTokens < TOTAL_TOKEN_TO_MINT) {
            _nextIpfsId = 112;
        } else if(mintedTokens < TOTAL_TOKEN_TO_MINT) {
            _nextIpfsId = _lastIpfsId + 1;
        }
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    //random number
	function random(
		uint256 from,
		uint256 to,
		uint256 salty
	) private view returns (uint256) {
		uint256 seed =
			uint256(
				keccak256(
					abi.encodePacked(
						block.timestamp +
							block.difficulty +
							((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
							block.gaslimit +
							((uint256(keccak256(abi.encodePacked(_msgSender())))) / (block.timestamp)) +
							block.number +
							salty
					)
				)
			);
		return seed.mod(to - from) + from;
	}

    /////////////
    // Setters //
    /////////////

    function addToWhitelistMultiple(address[] memory _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            addToWhitelist(_addresses[i]);
        }
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelistInfo[_address].approved = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelistInfo[_address].approved = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }
    
    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startPreSale() external onlyOwner {
        isPreSaleActive = true;
    }

    function stopPreSale() external onlyOwner {
        isPreSaleActive = false;
    }

    function changeFundWallet(address _fundWallet) external onlyOwner {
        fundWallet = _fundWallet;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        payable(fundWallet).transfer(_amount);
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
        _setTokenURI(_tokenId, _uri);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}