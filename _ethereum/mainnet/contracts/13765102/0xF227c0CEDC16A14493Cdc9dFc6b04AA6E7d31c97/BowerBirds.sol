// SPDX-License-Identifier: GPL-3.0
/* 
	Baushaus: https://www.baushaus.xyz/
*/
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IBurnable.sol";

contract BowerBirds is ERC721Enumerable, Ownable, PaymentSplitter, ReentrancyGuard, Pausable {
	using Strings for uint256;
	string public baseURI;
	uint256 public cost = 0.15 ether;
	uint256 public OGIndex = 1001;
	uint256 public supply = 10101;
	uint256 public genesisIndex = 1;
	uint256 public totalGenesisClaimed = 0;
	uint256 public startingPrice; // wei
	uint256 public endingPrice; // wei
	uint256 public duration; // seconds
	uint256 public startedAt; // time
	uint256 public endedAt; // time
	bool locked = false;
	uint256 delta;
	uint256 ratio;
	IBurnable earlyBird;
	IBurnable publicMint;
	event Claimed(address, uint256);
	address[] private addressList = [
		// dev wallet
		0xbE7e905592a4de4a24B23953abAAa412Ab654c19,
		// owner wallet
		0x2C8C89e2CB4f98929EC06568a21c3622cCfCFbB6
	];
	uint[] private shareList = [10,90];
	
	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI
	) ERC721(_name, _symbol)
	PaymentSplitter( addressList, shareList ) {
		setBaseURI(_initBaseURI);
		pause();
	}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function adminMint(uint256 count) external nonReentrant onlyOwner {
		for(uint256 i = 0; i < count; i++) {
			_safeMint(msg.sender, genesisIndex + i);
			_safeMint(msg.sender, OGIndex + i);									
		}
	}

	/**
		@dev Public pass holders receieve 1 genesis and 1 OG per pass
	 */
	function claim(uint256[] memory ids) external nonReentrant whenNotPaused {
		uint256 count = ids.length;
		require(count > 0, "cannot be Zero");
		require(genesisIndex + count <= OGIndex, "Cannot exceeds supply");
		require(OGIndex + count <= supply, "Cannot exceeds supply");
		require(publicMint.balanceOf(msg.sender, 1) == count, "need to own pass specified");
		for(uint256 i = 0; i < count; i++) {
			_safeMint(msg.sender, genesisIndex + i);
			_safeMint(msg.sender, OGIndex + i);									
		}
		publicMint.burnBatch(msg.sender, ids, ids);
		genesisIndex += count;
		OGIndex += count;
		totalGenesisClaimed += count;
		emit Claimed(msg.sender, count * 2);
	}

	/**
		@dev Early pass holders receieve 1 genesis and 2 OGs per pass
	 */
	function earlyClaim(uint256[] memory ids) external nonReentrant whenNotPaused {
		uint256 count = ids.length;
		require(count > 0, "cannot be Zero");
		require(genesisIndex + count <= OGIndex, "Cannot exceeds supply");
		require(OGIndex + count <= supply, "Cannot exceeds supply");
		require(earlyBird.balanceOf(msg.sender, 1) == count, "need to own pass specified");
		for(uint256 i = 0; i < count; i++) {					
			_safeMint(msg.sender, genesisIndex + i);			
		}
		for(uint256 i = 0; i < count * 2; i++) {
			_safeMint(msg.sender, OGIndex + i);
		}
		earlyBird.burnBatch(msg.sender, ids, ids);
		genesisIndex += count;
		OGIndex += 2 * count;
		totalGenesisClaimed += count;
		emit Claimed(msg.sender, count * 2);
	}

	/**
		@dev public minting
		public are only allowed to mint the genesis collection
		and supply is sold out when OG collection begins
	 */
	function mint(uint256 count) external payable nonReentrant whenNotPaused {
		require(count > 0, "cannot be zero");
		require(genesisIndex + count <= OGIndex, "Exceeds supply");
		require(msg.value == cost * count, "Not enough eth");
		for(uint256 i = 0; i < count; i++) {
			_safeMint(msg.sender, genesisIndex + i);			
		}
		genesisIndex += count;
	}

	/** 
		@dev
		Dutch Auction 
		Price starts at a certain price and decreases 
		at a regular rate
	*/
  function bid() external nonReentrant payable {
      require(getTime() >= startedAt, "Auction needs to start");
	  require(OGIndex + 1 <= supply, "Cannot exceeds supply");
      uint256 price = getCurrentPrice();
      require(msg.value == price, "Not enough ETH");
	  _safeMint(msg.sender, OGIndex);
	  OGIndex++;
  }

  function getTime() public view virtual returns (uint256) {
	  return block.timestamp;
  }

  function getCurrentPrice() public view returns (uint256) {
      require(startedAt > 0);
      if (getTime() >= endedAt) {
        return endingPrice;
      } else {
		uint256 secondsPassed = 0;
      	secondsPassed = getTime() - startedAt;
		uint256 currentPortion = secondsPassed / duration;
		uint256 currentPrice = delta * currentPortion;
        return startingPrice - currentPrice;
      }
  }

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}

	function setAuction(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _startedAt, uint256 _endedAt) external onlyOwner notLocked {
		require(!locked, "Locked");
		startingPrice = _startingPrice;
		endingPrice = _endingPrice;
		duration = _duration;
		startedAt = _startedAt;
		endedAt = _endedAt;
	  	ratio = (endedAt - startedAt) / _duration;
		delta = (startingPrice - endingPrice) / ratio;
	}

	function setSupply(uint256 _supply) public onlyOwner {
		supply = _supply;
	}

	modifier notLocked() {
		require(!locked, "Locked");
		_;
	}

	function setCost(uint256 _newCost) public onlyOwner notLocked {
		cost = _newCost;
	}

	function setGenesisIndex(uint256 _genesisIndex) public onlyOwner notLocked {
		genesisIndex = _genesisIndex;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner notLocked {
		baseURI = _newBaseURI;
	}

	function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

	function setLocked() external onlyOwner {
		locked = true;
	}

	function setEarlyBird(IBurnable _earlyBird) external onlyOwner notLocked {
		earlyBird = _earlyBird;
	}

	function setPublicMint(IBurnable _publicMint) external onlyOwner notLocked {
		require(!locked, "Locked");
		publicMint = _publicMint;
	}
}
