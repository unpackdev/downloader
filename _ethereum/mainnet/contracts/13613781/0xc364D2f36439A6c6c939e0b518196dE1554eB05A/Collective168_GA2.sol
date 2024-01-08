// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Collective168_GA2 is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 constant public TOTAL_TOKEN_TO_MINT = 3050;
    uint256 constant public OWNER_MINT = 50;
    address immutable public FUND_WALLET;
    uint256 public itemPrice = 0.04 ether;
	uint256 public mintedTokens;
    uint256 public limitPerWallet = 5;
    uint256 private startingIpfsId;
    uint256 private _lastIpfsId;
    uint256 public saleStatus;
    bool public ownerMinted;

    ERC721 public C168GA1;

    mapping(address => uint256) public minted;
    mapping(uint256 => bool) public claimed;
    mapping(address => uint256) public claimedCount;

    constructor (string memory _tokenBaseUri, address _fundWallet, ERC721 _C168GA1) ERC721("Collective 168 - Gen Art 2", "C168-GA2") {
        _setBaseURI(_tokenBaseUri);
        FUND_WALLET = _fundWallet;
        C168GA1 = _C168GA1;
    }

    ////////////////////
    // Action methods //
    ////////////////////

    function mintTokenOwner(address _to) external onlyOwner {
        require(!ownerMinted, "Owner has already minted");
		for (uint256 i = 1; i <= OWNER_MINT; i++) {
            _mint(_to, i);
		}
        mintedTokens = mintedTokens + OWNER_MINT;
        ownerMinted = true;
	}

    function _beforeMint(uint256 _howMany) private view {
	    require(_howMany > 0, "Minimum 1 tokens need to be minted");
	    require(_howMany <= tokenRemainingToBeMinted(), "Mint amount is greater than the token available");
    }

    function claim(uint256[] memory _tokenList) external {
        uint256 _count = _tokenList.length;
        require(saleStatus == 1, "Claim is not active");
        _beforeMint(_count);
		for (uint256 i = 0; i < _count; i++) {
		    require(C168GA1.ownerOf(_tokenList[i]) == _msgSender(), "NFT ownership required");
	        require(!claimed[_tokenList[i]], "Already claimed");
			_mintToken(_msgSender());
            claimedCount[_msgSender()]++;
            claimed[_tokenList[i]] = true;
		}
	}

    function mintToken(uint256 _howMany) external payable {
        require(saleStatus == 2, "Sale is not active");
        _beforeMint(_howMany);
		require(itemPrice.mul(_howMany) == msg.value, "Insufficient ETH to mint");
	    require(minted[_msgSender()] <= limitPerWallet, "Max limit exceeds");
		for (uint256 i = 0; i < _howMany; i++) {
            minted[_msgSender()]++;
	        require(minted[_msgSender()] <= limitPerWallet, "Max limit exceeds");
			_mintToken(_msgSender());
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }

    ///////////////////
    // Query methods //
    ///////////////////

    function checkClaimStatus(uint256 _tokenId) external view returns (string memory) {
        if(claimed[_tokenId]) {
            return "Already claimed";
        } else {
            return "Eligible to claim";
        }
    }

    function isClaimActive() external view returns (bool) {
        return (saleStatus == 1 ? true : false);
    }

    function isSaleActive() external view returns (bool) {
        return (saleStatus == 2 ? true : false);
    }

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

    function updateSaleStatus(uint256 _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function updatePrice(uint256 _itemPrice) external onlyOwner {
        itemPrice = _itemPrice;
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