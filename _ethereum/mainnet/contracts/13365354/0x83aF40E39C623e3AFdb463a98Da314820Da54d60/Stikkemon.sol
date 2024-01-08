pragma solidity ^0.8.0;
pragma abicoder v2;

// import "./console.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract Stikkemon is ERC721Enumerable, Ownable {


	using SafeMath for uint256;
	string public LICENSE_URI = "";
	bool licenseLocked = false;
	string public BASE_URI = "";
	uint256 public constant unitPrice = 69420888800000000;  // 0.0694208888 ETH
	uint public constant maxPurchase = 20;
	bool public saleActive = false;
	mapping(uint => string) public stikkeNames;
	uint256 public constant MAX_STIKKEMONS = 8888;
	uint public mktReserve = 444;
	uint public teamReserve = 88;

 	event NameChanged(address _by, uint _tokenId, string _name);
	event LicenseLocked(string _licenseText);

	constructor() ERC721("Stikkemon", "STIKK") { }


	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
		// address payable addr = payable(msg.sender);
        payable(msg.sender).transfer(balance);
    }


	function setBaseURI(string memory baseURI) public onlyOwner {
	 	BASE_URI = baseURI;
    }


	/**
	* override
	*/
	  function _baseURI() internal view virtual override returns (string memory) {
	  	return BASE_URI;
	  }


	/**
	* flip sale state
	*/
	function switchSale() public onlyOwner {
		saleActive = !saleActive;
	}


	function reserveMkt(address to, uint _amount) public onlyOwner {
		uint inititialSupply = totalSupply();
		require(_amount > 0 && _amount <= maxPurchase, "Invalid amount");
		require(totalSupply().add(_amount) <= MAX_STIKKEMONS, "Max supply exceeded");
		require(mktReserve > 0 && mktReserve.sub(_amount) >= 0, "No reserve");
		for ( uint i = 0; i < _amount; i++) {
            _safeMint( to, inititialSupply + i);
        }
		mktReserve = mktReserve.sub(_amount);
	}


	function reserveTeam(uint _amount) public onlyOwner {
		uint supply = totalSupply();
		require(teamReserve > 0, "No reserve");
		for (uint i = 0; i < _amount; i++) {
            _safeMint( msg.sender, supply + i);
        }
		teamReserve = teamReserve.sub(_amount);
	}


	// Set license text or URL
	function setLicense(string memory _license) public onlyOwner {
		require(licenseLocked == false, "License locked");
		LICENSE_URI = _license;
	}


	//  prevents changing license
	function lockLicense() public onlyOwner {
		licenseLocked =  true;
		emit LicenseLocked(LICENSE_URI);
	}


	function mintStikkemon(uint _amount) public payable {
		require(saleActive, "Sale not active");
		require(_amount > 0 && _amount <= maxPurchase, "Invalid amount");
		require(totalSupply().add(mktReserve).add(teamReserve).add(_amount) <= MAX_STIKKEMONS, "Max supply exceeded");

		// console.log("_amount", _amount);
		// console.log("msgValue ", msg.value);

		require(msg.value >= unitPrice.mul(_amount), "Insufficient Ether");

		for(uint i = 0; i < _amount; i++) {
			uint mintIndex = totalSupply();
			if (totalSupply() < MAX_STIKKEMONS) {
				_safeMint(msg.sender, mintIndex);
			}
		}
	}


	function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);  // Return an empty array
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

	// Returns the license for tokens
    function getTokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Choose a token within range");
        return LICENSE_URI;
    }


	function changeName(uint _tokenId, string memory _name) public {
		require(ownerOf(_tokenId) == msg.sender, "Address doesn't own token");
		require(sha256(bytes(_name)) != sha256(bytes(stikkeNames[_tokenId])), "New name is same as the current one");
		stikkeNames[_tokenId] = _name;
		emit NameChanged(msg.sender, _tokenId, _name);
	}


	function viewStikkeName(uint _tokenId) public view returns( string memory ){
		require( _tokenId < totalSupply(), "Choose a token within range" );
		return stikkeNames[_tokenId];
	}

}
