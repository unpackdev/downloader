pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract SergToadz is ERC721, Ownable {
		
     using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY = 222;

    uint256 public price = 0.02 ether;

    uint256 public MAX_PURCHASE = 3;

    bool public saleIsActive = false;

    string private baseURI;

    uint256 private _currentTokenId = 0;
    
    address[] private whitelistArr = [
        0xa8c534413F2C4663c166B435dA1BdFfb7680d29A, //1
        0x7dD65658F6480A2911F4A7f6c7C193B66E318EC7, //2
        0x9B4B7282e4838273C79CcA63c6c03a2dF5ee4286, //3
        0xAe0C3d6aA3636A77372da7772f6469f47b6893F4, //4
        0x38A4D889a1979133FbC1D58F970f0953E3715c26, //5
        0x17357B1002AB1804657885a60a3d9B114C79019e, //6
        0x46E8518eb63AC88AC61F9b00A234f2d31eEabe93, //7
        0x46E8518eb63AC88AC61F9b00A234f2d31eEabe93, //8
        0x208BA77C17d62A418B0A34A54143E9375FfEa633, //9
        0x881a960440153CFF2e60aFEddFa05296239240a3, //10
        0xE464d012805F23705091eeE10CA3856d6E4bff3b, //11
        0x31E04750dd87396eCf4AE8F976CBe4cc69224Eda, //12
        0xCb9BbC9Da5e28D3939c1045962f48883C573a913, //13
        0xaa8Ce0c99C2c71D371C98a2a7a18D8B22775D2f4, //14
        0xDFaE6c45233c9DA3F8Ae1309925Fe93bCAbC0a77, //15
        0xA749B058ee2a54e98342f4865Cd3062eaC14B451, //16
        0xf873543D645b90bD00dAfb012cF22Bb4E03dBFFC, //17
        0x40deB7ab338083c92A83F02f45dA928Ae09101E8, //18
        0xCebB48Fa75c8d4A339C7BFD85a80748b59Df6302, //19
        0x16Aeb36CeEBA2BEAfAC0D74e87FD31d36182a2BA, //20
        0xC956B82CFbc9C85f33aE1755E948AfEc47451f9A, //21
        0xE6Bcc30C79e7D53FDe06B2a195B960f60ca4DC3d, //22
        0xCaA9743D454824eD06dC6bad7424DD32328D6644, //23
        0xdC133816529CB58177d9bc8b55E4b523673b84FB, //24
        0x43c7C3943A181774FD1791742EF6b42d671E30c3, //25
        0x14c9ec0e3022871cb56bA0fFAE119Fd6419d4e0E, //26
        0x85BaEC1be8C448E7c7B2ffd0C97e883781C6A702, //27
        0x112762e444d00DB72b851E711783B392df6A1F60, //28
        0x74f6D5e64f563Ddc394b309cbb127383397436e3, //29
        0x4FEdE03557B04d20483BBe549A872e97045C575f, //30
        0xbd16b6cf36301Bb279798aA39Bd0E19C5faa7BB6, //31
        0x14bEd840CA7F237F5B9FeCb98e5371C56540BFCB, //32
        0xc8fDBBA9dB5868e2d5Fb854B8cF473Ca69D8498F, //33
        0x2D26b69ab582765752b1591958394aCA21A9949B, //34
        0xA54A24f7aA6538EC46c8Cc5EE9AED158C0624eC1, //35
        0x25E4b241D4ca338b49D429178d55E6118090aFcc, //36
        0xaFF0A88bB6D6Fbe6619c2592d56515c06E78D061, //37
        0x3a8B669fF0630BaFF1433041646eE0D2FfA20772, //38
        0x2d63ABce30f048c6FCAE5008e614f6C6510954c1, //39
        0x6D0998e0513A739d1Af438e35Fe33b4DAD258920, //40
        0x9d80eDefb33F7Fa40DcFF768E15A173F0498d183, //41
        0xbDA4377A9455d877e4347545b4454F1fE59f5c10, //42
        0x7DC3D31bDE30C104D8A3Eb61B62D6260e2BD7155, //43
        0x90d9172c62a0206848B1eC83A35065bd61bA0f08, //44
        0xC46Db2d89327D4C41Eb81c43ED5e3dfF111f9A8f, //45
        0x1E177302D48956B6e80dDB8c884E6fEe65E6Ae8D, //46
        0x0bBf7580e036eA5D69ABe679CC90117EeC2e3dc1, //47
        0xd461c0E84C98650B7d573Cb7cDd3d7E0bA402E6b, //48
        0x4436b0B26a76cCD25f6b97324C42dF4B0f0Ed3AB, //49
        0xD8B5Ec978d3009CF1dFE07f51d02001550dc7706, //50
        0x4E6997674d683908175A22F8Ac1E4CC3367A09e2, //51
        0xb733E52DFF6D056fad688428D96CfC887b43b5DA, //52
        0xFC2a616D48a8681250Aaaf590404E20812e96cFa, //53
        0x4298e663517593284Ad4FE199b21815BD48a9969, //54
        0x46F67bA8629F70A9c6099F9f0cA1Fe98e5047397  //55
    ];
    
    mapping(address => uint256) whitelist;

    event SergToadzMinted(uint tokenId, address sender);

   constructor(string memory _baseURI) ERC721("SergToadz","SERGTZ") {
		setBaseURI(_baseURI);
		setupWhitelist();
	}
	
	function setupWhitelist() private{
	    for(uint256 i = 0; i < whitelistArr.length; i++){
		    addToWhitelist(whitelistArr[i], i + 1);
		}
		
		_currentTokenId = whitelistArr.length;
	}


	function mintSergToadzTo(address _to, uint numberOfTokens) public payable {
        require(saleIsActive, "Wait for sales to start!");
        require(numberOfTokens <= MAX_PURCHASE, "Too many SergToadz to mint!");
        require(_currentTokenId.add(numberOfTokens) <= TOTAL_SUPPLY, "All SergToadz has been minted!");
        require(msg.value >= price, "insufficient ETH");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit SergToadzMinted(newTokenId, msg.sender);
                _incrementTokenId();
            }
        }
    }

    function mintTo(address _to, uint numberOfTokens) public onlyOwner {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit SergToadzMinted(newTokenId, msg.sender);
                _incrementTokenId();
               
            }
        }
    }
    
    function claimSergToadz() public onlyWhitelisted {
        require(saleIsActive, "Wait for sales to start!");
        _safeMint(msg.sender, whitelist[msg.sender]);
        removeFromWhitelist(msg.sender);
    }
    
    // whitelist functions
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function addToWhitelist(address _address, uint256 index) private {
        whitelist[_address] = index;
    }
    
    function removeFromWhitelist(address _address) private{
        whitelist[_address] = 0;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address] != 0;
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