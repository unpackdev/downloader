// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Collective168 is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 constant public TOTAL_TOKEN_TO_MINT = 1550;
    uint256 constant public OWNER_MINT = 50;
    uint256 constant public ITEM_PRICE = 0.05 ether;
	uint256 public mintedTokens;
    uint256 public startingIpfsId;
    uint256 private _lastIpfsId;
    bool public isSaleActive;
    bool public ownerMinted;
    uint256 public limitPerWallet = 5;
    address immutable public FUND_WALLET;

    mapping(address => uint256) public minted;

    constructor (string memory _tokenBaseUri, address _fundWallet) ERC721("Collective 168", "C168-GA1") {
        _setBaseURI(_tokenBaseUri);
        FUND_WALLET = _fundWallet;
    }

    ////////////////////
    // Action methods //
    ////////////////////

    function mintTokenOwner() external onlyOwner {
        require(!ownerMinted, "Collective168: Owner has already minted");
		for (uint256 i = 1; i <= OWNER_MINT; i++) {
            require(!_exists(mintedTokens), "Collective168: Token already exist.");
            _mint(_msgSender(), i);
		}
        mintedTokens = mintedTokens + OWNER_MINT;
        ownerMinted = true;
	}

    function mintToken(uint256 _howMany) external payable {
        require(isSaleActive, "Collective168: Sale is not active");
	    require(_howMany > 0, "Collective168: Minimum 1 tokens need to be minted");
	    require(_howMany <= tokenRemainingToBeMinted(), "Collective168: Mint amount is greater than the token available");
		require(ITEM_PRICE.mul(_howMany) == msg.value, "Collective168: Insufficient ETH to mint");
	    require(minted[_msgSender()] <= limitPerWallet, "Collective168: Max limit exceeds");
        require(!_isContract(msg.sender), "Collective168: Caller cannot be contract");
		for (uint256 i = 0; i < _howMany; i++) {
			_mintToken(_msgSender());
            minted[_msgSender()]++;
	        require(minted[_msgSender()] <= limitPerWallet, "Collective168: Max limit exceeds");
		}
	}
	
	function _isContract(address _addr) private view returns (bool) {
        uint32 _size;
        assembly {
            _size := extcodesize(_addr)
        }
        return (_size > 0);
    }
    
    function _mintToken(address _to) private {
        if(mintedTokens == 50) {
            _lastIpfsId = random(51, TOTAL_TOKEN_TO_MINT, uint256(uint160(address(_msgSender()))) + 1);
            startingIpfsId = _lastIpfsId;
        } else {
            _lastIpfsId = getIpfsIdToMint();
        }
        mintedTokens++;
        require(!_exists(mintedTokens), "Collective168: Token already exist.");
        _mint(_to, mintedTokens);
        _setTokenURI(mintedTokens, uint2str(_lastIpfsId));
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
        require(_exists(tokenId), "Collective168: token does not exist.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Collective168: caller is not owner nor approved");
        _burn(tokenId);
    }

    ///////////////////
    // Query methods //
    ///////////////////

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }
    
    function tokenRemainingToBeMinted() public view returns (uint256) {
        return TOTAL_TOKEN_TO_MINT.sub(mintedTokens);
    }

    function isAllTokenMinted() public view returns (bool) {
        return mintedTokens == TOTAL_TOKEN_TO_MINT;
    }

    function getIpfsIdToMint() private view returns(uint256 _nextIpfsId) {
        require(!isAllTokenMinted(), "All tokens have been minted");
        if(_lastIpfsId == TOTAL_TOKEN_TO_MINT && mintedTokens < TOTAL_TOKEN_TO_MINT) {
            _nextIpfsId = 51;
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

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    function changeWalletLimit(uint256 _limitPerWallet) external onlyOwner {
        limitPerWallet = _limitPerWallet;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        payable(FUND_WALLET).transfer(_amount);
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