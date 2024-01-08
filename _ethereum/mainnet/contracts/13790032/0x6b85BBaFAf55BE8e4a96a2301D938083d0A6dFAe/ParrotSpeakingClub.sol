pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract ParrotSpeakingClub is ERC721, Ownable {
		
     using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY = 3555;

    uint256 public price = 0.02 ether;

    uint256 public MAX_PURCHASE = 15;

    bool public saleIsActive = false;

    string private baseURI = "";

    uint256 private _currentTokenId = 0;
    
   constructor() ERC721("ParrotSpeakingClub","PSC") {
       mintTo(msg.sender, 5);
   }

	function mintParrotsTo(address _to, uint numberOfTokens) public payable {
        require(saleIsActive, "Wait for sales to start!");
        require(numberOfTokens <= MAX_PURCHASE, "Too many Parrots to mint!");
        require(_currentTokenId.add(numberOfTokens) <= TOTAL_SUPPLY, "All Parrots has been minted!");
        require(msg.value >= getPrice().mul(numberOfTokens), "insufficient ETH");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                _incrementTokenId();
            }
        }
    }

    function mintTo(address _to, uint numberOfTokens) public onlyOwner {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                _incrementTokenId();             
            }
        }
    }
    

    // contract functions
    function assetsLeft() public view returns (uint256) {
        if (supplyReached()) {
            return 0;
        }

        return TOTAL_SUPPLY - _currentTokenId;
    }

    function _nextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function supplyReached() public view returns (bool) {
        return _currentTokenId > TOTAL_SUPPLY;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function switchSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

	function setBaseURI(string memory _newUri) public onlyOwner {
		baseURI = _newUri;
	}

	function setTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		TOTAL_SUPPLY = _newTotalSupply;
	}

    function setMaxPurchase(uint256 _newMaxPurchase) public onlyOwner {
		MAX_PURCHASE = _newMaxPurchase;
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
		price = _newPrice;
	}

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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

}