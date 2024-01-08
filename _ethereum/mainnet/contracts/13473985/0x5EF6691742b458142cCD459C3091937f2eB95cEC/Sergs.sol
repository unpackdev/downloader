pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./IMinter.sol";


contract Sergs is ERC721, Ownable {
	using ECDSA for bytes32;
	using SafeMath for uint256;

	IMinter public sergsMinter;
	
	
    uint256 public TOTAL_SUPPLY = 5555;

    uint256 public SergPrice = 0.07 ether;

    uint256 public MAX_PURCHASE = 5;

    bool public saleIsActive = false;

    string private baseURI;

    uint256 private _currentTokenId = 0;

	// Events

    constructor(string memory _baseURI, address _minter) ERC721("Sergs","SERGS") {
		setBaseURI(_baseURI);
		sergsMinter = IMinter(_minter);
	}

	function migrate(address _to, uint256 _tokenId) external{
        require(msg.sender == address(sergsMinter), "Can't call this");
        _mint(_to, _tokenId);
    }

	function setMinter(address _minter) public onlyOwner {
		sergsMinter = IMinter(_minter);
	}

	function setBaseURI(string memory newURI) public onlyOwner {
		baseURI = newURI;
	}

	function tokenURI(uint256 _tokenId) override public view returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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

    function setSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
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