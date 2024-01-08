// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

interface IPhanana {
    function mint(address to, uint256 amount) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

contract Phongz is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    string _baseUri;
    uint public constant TOTAL_SUPPLY = 1000;
    uint public price;
    bool public isSalesStarted;
    IPhanana public phanana;
    uint public nameChangePrice;
    
    mapping(uint256 => string) public bio;
	mapping (uint256 => string) private _tokenName;
	mapping (string => bool) private _nameReserved;
	
	event NameChange (uint256 indexed tokenId, string newName);
	event BioChange (uint256 indexed tokenId, string bio);

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function initialize() initializer public {
        __ERC721_init("Phongz", "PHONGZ");
        __ERC721Burnable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        price = 0;
        phanana = IPhanana(0xC4aAB23706295Ff5e14b81aD5f8B5Ad6f382682E);
        nameChangePrice = 300 ether;
        isSalesStarted = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function _mintNfts(address receiver, uint quantity) internal {
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "sold out");
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, _tokenIdCounter.current()+1);
            _tokenIdCounter.increment();
        }
    }

    function safeMint(address to, uint quantity) public onlyRole(MINTER_ROLE) {
        _mintNfts(to, quantity);
    }
    
    function mint(uint quantity) public payable {
        require(isSalesStarted, "sales not started");
        require(quantity <= 3, "only 3 per transaction");
        require(msg.value >= price * quantity, "ether value sent is below the price");
        
        phanana.mint(msg.sender, 69 ether);
        
        _mintNfts(msg.sender, quantity);
    }
    
    function changeBio(uint256 _tokenId, string memory _bio) public {
        phanana.transferFrom(msg.sender, address(this), nameChangePrice);
		address owner = ownerOf(_tokenId);
		require(_msgSender() == owner, "ERC721: caller is not the owner");
		bio[_tokenId] = _bio;
		emit BioChange(_tokenId, _bio); 
	}
	
	function changeName(uint256 tokenId, string memory newName) public {
	    phanana.transferFrom(msg.sender, address(this), nameChangePrice);
		address owner = ownerOf(tokenId);
		require(_msgSender() == owner, "ERC721: caller is not the owner");
		require(validateName(newName) == true, "Not a valid new name");
		require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
		require(isNameReserved(newName) == false, "Name already reserved");
		// If already named, dereserve old name
		if (bytes(_tokenName[tokenId]).length > 0) {
			toggleReserveName(_tokenName[tokenId], false);
		}
		toggleReserveName(newName, true);
		_tokenName[tokenId] = newName;
		emit NameChange(tokenId, newName);
	}
    	
	function setBaseURI(string memory newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_baseUri = newURI;
	}
	
	function changeNamePrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
		nameChangePrice = _price;
	}
	
	function setPrice(uint newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
	    price = newPrice;
	}
	
	function toggleSales() public onlyRole(DEFAULT_ADMIN_ROLE) {
	    isSalesStarted = !isSalesStarted;
	}
	
	function totalSupply() public view returns (uint) {
	    return _tokenIdCounter.current();
	}
	
	function toggleReserveName(string memory str, bool isReserve) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_nameReserved[toLower(str)] = isReserve;
	}
	
	function tokenNameByIndex(uint256 index) public view returns (string memory) {
		return _tokenName[index];
	}
	
	function isNameReserved(string memory nameString) public view returns (bool) {
		return _nameReserved[toLower(nameString)];
	}
	
	function validateName(string memory str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 25) return false; // Cannot be longer than 25 characters
		if(b[0] == 0x20) return false; // Leading space
		if (b[b.length - 1] == 0x20) return false; // Trailing space
		bytes1 lastChar = b[0];
		for(uint i; i<b.length; i++){
			bytes1 char = b[i];
			if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces
			if(
				!(char >= 0x30 && char <= 0x39) && //9-0
				!(char >= 0x41 && char <= 0x5A) && //A-Z
				!(char >= 0x61 && char <= 0x7A) && //a-z
				!(char == 0x20) //space
			)
				return false;
			lastChar = char;
		}
		return true;
	}
	
	function toLower(string memory str) public pure returns (string memory){
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			// Uppercase character
			if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
	
	function withdrawAll() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }
	
	function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}