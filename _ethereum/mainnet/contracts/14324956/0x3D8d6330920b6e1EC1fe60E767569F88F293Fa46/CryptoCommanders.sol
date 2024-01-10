// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";

/// @custom:security-contact bytedeltaca@gmail.com
contract CryptoCommanders is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
	
	bytes32 public commanderProvenance;
    
    uint256 public maxCommanders;
	uint256 public reservePrice ;
	uint256 public giveawayAllocation;
    uint256 public giveawayReserved;
	uint256 public maxMint;
	
	uint256 public commanderPrice;
    uint256 public discountPrice;
	
	mapping(address => bool)  public giveawayWinners; // Addresses that have won a free CryptoCommander
	mapping(address => uint)  public ASLTReserved; // Addresses that have reserved CryptoCommanders using ASLT
	
	address public ASLTAddress;
    string public baseURI;
	
	bool public earlyIsActive;
	bool public mintIsActive;
    bool public reserveRefundable;

    uint giveawayCounter;
    uint256 normalCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("CryptoCommanders", "CRCO");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        maxCommanders = 11111;
        reservePrice = 1000000000000000000000; // 1000 ASLT
        giveawayAllocation = 1111;
        giveawayReserved = 0;
        maxMint = 20; // Max per transaction
        commanderPrice = 50000000000000000; // 0.05 ETH
        discountPrice   = 40000000000000000; // 0.8 * 0.05 ETH
        ASLTAddress = 0x2B8b09cE791A4b1036137cF8Ac8260CD1e619F29;
        baseURI = "ipfs://QmeN9tajdY4wC3MRz94CKTvKCUNW2C1E6zLAgtt1hFLEBF/";
        earlyIsActive = false;
        mintIsActive = false;
        reserveRefundable = false;
        giveawayCounter = 0;
        normalCounter = 1111;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 amount) public onlyOwner {
        uint256 tokenId = giveawayCounter;
        for(uint i = 0; i < amount; i++) {
            _safeMint(to, tokenId + i);
            giveawayCounter += 1;
            giveawayReserved += 1;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
	
	function setReservePrice(uint256 newReservePrice) public onlyOwner {
		reservePrice = newReservePrice;
	}
	
	function setCommanderPrice(uint256 newCommanderPrice) public onlyOwner {
		commanderPrice = newCommanderPrice;
	}
	
	function setDiscountPrice(uint256 newDiscountPrice) public onlyOwner {
		discountPrice = newDiscountPrice;
	}
	
	function setMaxMint(uint256 newMaxMint) public onlyOwner {
		maxMint = newMaxMint;
	}
	
	function flipEarlyMint() public onlyOwner {
		earlyIsActive = !earlyIsActive;
	}
	
	function flipMintState() public onlyOwner {
		mintIsActive = !mintIsActive;
	}

    function flipReserveRefund() public onlyOwner {
        reserveRefundable = !reserveRefundable;
    }
	
	function setASLTAddress(address newASLTAddress) public onlyOwner {
		ASLTAddress = newASLTAddress;
	}
	
	function mintGiveaway() public whenNotPaused {
        require(earlyIsActive, "Mint is not active.");
		require (giveawayWinners[msg.sender], "No winnings to claim");
		giveawayWinners[msg.sender] = false;
		uint mintIndex = giveawayCounter;
		require(giveawayCounter < giveawayAllocation, "Not enough remaining Commanders to mint.");
		_safeMint(msg.sender, mintIndex);
        giveawayCounter += 1;
	}
	
	function mintReserved(uint256 amount) public payable whenNotPaused {
        require((commanderProvenance != bytes32(0)),"Hash not set");
        require(mintIsActive, "Mint is not active.");
		require (ASLTReserved[msg.sender] >= amount, "Not enough reserved");
        uint mintIndex = normalCounter;
        require(mintIndex + amount <= maxCommanders, "Not enough remaining Commanders to mint.");
        require(discountPrice * amount <= msg.value, "Insufficient payment.");
        ASLTReserved[msg.sender] -= amount;
        for(uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex+i);
            normalCounter += 1;
        }
	}
	
	function mintCommander(uint256 amount) public payable whenNotPaused {
        require((commanderProvenance != bytes32(0)),"Hash not set");
        require(mintIsActive, "Mint is not active.");
		require(amount <= maxMint, "Can not exceed max mint per transaction");
        uint mintIndex = normalCounter;
        require(mintIndex + amount <= maxCommanders, "Not enough remaining Commanders to mint.");
        require(commanderPrice * amount <= msg.value, "Insufficient payment.");
        for(uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex+i);
            normalCounter += 1;
        }
	}
	
	function addGiveawayWinners(address[] memory accounts) public onlyOwner {
		for (uint256 account = 0; account < accounts.length; account++) {
            require (giveawayReserved < giveawayAllocation, "Max number of Commanders given away.");
			giveawayWinners[accounts[account]]= true;
            giveawayReserved += 1;
		}
	}
	
	function reserve(uint256 amount) public {
		require (amount > 0, "Amount must be greater than 0");
		uint256 reservePayment = amount * reservePrice;
		
		IERC20(ASLTAddress).transferFrom(address(msg.sender), address(this), reservePayment);
		ASLTReserved[msg.sender] += amount;
	}

    function refundReserve() public {
        require (reserveRefundable, "Refunds are disabled");
        uint256 refundPayment = ASLTReserved[msg.sender] * reservePrice;

        ASLTReserved[msg.sender] = 0;
        IERC20(ASLTAddress).transferFrom(address(this), address(msg.sender), refundPayment);
    }
	
    //Set token URI from baseURI

	function tokenURI(uint256 tokenId)
       public
       view
       override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
       returns (string memory)
    {
       return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // Provenance checks and baseURI

    function setProvenanceHash(bytes32 provenanceHash) public onlyOwner {
        require((commanderProvenance == bytes32(0)),"Hash already set");
        commanderProvenance = provenanceHash;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(getHash(newBaseURI) == commanderProvenance, "Invalid BaseURI");
        bytes memory ba = bytes(newBaseURI);
        require(ba[ba.length -1] == '/',"BaseURI must end with a '/'");
        baseURI = newBaseURI;
    }

    function getHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
	
	// Recovery functions

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

}
