//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// npm packages imports
import "./console.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/*

          _____                   _______                           _____                    _____                    _____                    _____                    _____          
         /\    \                 /::\    \                         /\    \                  /\    \                  /\    \                  /\    \                  /\    \         
        /::\    \               /::::\    \                       /::\____\                /::\____\                /::\    \                /::\    \                /::\    \        
       /::::\    \             /::::::\    \                     /::::|   |               /:::/    /               /::::\    \               \:::\    \              /::::\    \       
      /::::::\    \           /::::::::\    \                   /:::::|   |              /:::/    /               /::::::\    \               \:::\    \            /::::::\    \      
     /:::/\:::\    \         /:::/--\:::\    \                 /::::::|   |             /:::/    /               /:::/\:::\    \               \:::\    \          /:::/\:::\    \     
    /:::/__\:::\    \       /:::/    \:::\    \               /:::/|::|   |            /:::/    /               /:::/__\:::\    \               \:::\    \        /:::/  \:::\    \    
   /::::\   \:::\    \     /:::/    / \:::\    \             /:::/ |::|   |           /:::/    /                \:::\   \:::\    \              /::::\    \      /:::/    \:::\    \   
  /::::::\   \:::\    \   /:::/____/   \:::\____\           /:::/  |::|___|______    /:::/    /      _____    ___\:::\   \:::\    \    ____    /::::::\    \    /:::/    / \:::\    \  
 /:::/\:::\   \:::\    \ |:::|    |     |:::|    |         /:::/   |::::::::\    \  /:::/____/      /\    \  /\   \:::\   \:::\    \  /\   \  /:::/\:::\    \  /:::/    /   \:::\    \ 
/:::/__\:::\   \:::\____\|:::|____|     |:::|____|        /:::/    |:::::::::\____\|:::|    /      /::\____\/::\   \:::\   \:::\____\/::\   \/:::/  \:::\____\/:::/____/     \:::\____\
\:::\   \:::\   \::/    / \:::\   _\___/:::/    /         \::/    / -----/:::/    /|:::|____\     /:::/    /\:::\   \:::\   \::/    /\:::\  /:::/    \::/    /\:::\    \      \::/    /
 \:::\   \:::\   \/____/   \:::\ |::| /:::/    /           \/____/      /:::/    /  \:::\    \   /:::/    /  \:::\   \:::\   \/____/  \:::\/:::/    / \/____/  \:::\    \      \/____/ 
  \:::\   \:::\    \        \:::\|::|/:::/    /                        /:::/    /    \:::\    \ /:::/    /    \:::\   \:::\    \       \::::::/    /            \:::\    \             
   \:::\   \:::\____\        \::::::::::/    /                        /:::/    /      \:::\    /:::/    /      \:::\   \:::\____\       \::::/____/              \:::\    \            
    \:::\   \::/    /         \::::::::/    /                        /:::/    /        \:::\__/:::/    /        \:::\  /:::/    /        \:::\    \               \:::\    \           
     \:::\   \/____/           \::::::/    /                        /:::/    /          \::::::::/    /          \:::\/:::/    /          \:::\    \               \:::\    \          
      \:::\    \                \::::/____/                        /:::/    /            \::::::/    /            \::::::/    /            \:::\    \               \:::\    \         
       \:::\____\                |::|    |                        /:::/    /              \::::/    /              \::::/    /              \:::\____\               \:::\____\        
        \::/    /                |::|____|                        \::/    /                \::/____/                \::/    /                \::/    /                \::/    /        
         \/____/                  --                               \/____/                  --                       \/____/                  \/____/                  \/____/

*/

contract EQKEYS is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedURI;
    bool public paused = true;
    bool public revealed = false;
    bool public onlyPresale = true;
    uint64 public constant presaleCost = .22 ether;
    uint64 public constant publicSaleCost = .33 ether;
    uint16 public constant maxSupply = 264;
    uint8 public constant presaleMintAmount = 2;
    uint8 public constant publicSaleMintAmount = 4;
    uint8 public constant presaleKeysPerAddressLimit = 2;
    uint8 public constant keysPerAddressLimit = 4;
    address[] public presaleAddresses;
    mapping(address => uint) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealURI);
        _tokenIds.increment();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint8 _mintAmount) public payable nonReentrant {
		require (!paused, "this contract is paused");
		uint supply = totalSupply();
		require(_mintAmount > 0, "at least 1 KEY needs to be minted");
		require(supply + _mintAmount <= maxSupply, "this would exceed the number of available KEYs");

		if(msg.sender != owner()) {
			if(onlyPresale) {
				require(onPresaleList(msg.sender), "this address is not on the presale list");
				require(_mintAmount <= presaleMintAmount, "maximum number of KEYs per presale session exceeded"); 
				uint ownerMintedCount = addressMintedBalance[msg.sender];
				require(ownerMintedCount + _mintAmount <= presaleKeysPerAddressLimit, "individual addresses are only allowed a maximum of 2 NFTs during presale");
				require(msg.value >= presaleCost * _mintAmount, "insufficient funds");
				require(supply + _mintAmount <= 176, "this amount will exceed the presale limit or the presale has sold out");
			} else {
				require(_mintAmount <= publicSaleMintAmount, "maximum number of KEYs per session exceeded"); 
				uint ownerMintedCount = addressMintedBalance[msg.sender];
				require(ownerMintedCount + _mintAmount <= keysPerAddressLimit, "individual addresses are only allowed a maximum of 4 NFTs");
				require(msg.value >= publicSaleCost * _mintAmount, "insufficient funds");
			}
		}

		for (uint i = 0; i < _mintAmount; i++) {
			uint tokenId = _tokenIds.current();

			if (_tokenIds.current() <= maxSupply) {
				_tokenIds.increment();
				addressMintedBalance[msg.sender]++;
				_safeMint(msg.sender, tokenId);
			}
		}
    }
  
    function onPresaleList(address _user) public view returns (bool) {
        for (uint i = 0; i < presaleAddresses.length; i++) {
			if (presaleAddresses[i] == _user) {
				return true;
			}
        }
        return false;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		if(revealed == false) {
			return bytes(notRevealedURI).length > 0
				? string(abi.encodePacked(notRevealedURI, tokenId.toString(), baseExtension))
				: "";
		}

			string memory currentBaseURI = _baseURI();
			return bytes(currentBaseURI).length > 0
				? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
				: "";
	}

	//only owner
	function penthouseMint(uint8 _mintAmount) public onlyOwner {
		uint supply = totalSupply();
		require(_mintAmount > 0, "at least 1 KEY needs to be minted");
		require(supply + _mintAmount <= 88, "this would exceed the number of penthouse KEYs");

		for (uint i = 0; i < _mintAmount; i++) {
			uint tokenId = _tokenIds.current();

			if (_tokenIds.current() <= 88) {
				_tokenIds.increment();
				addressMintedBalance[msg.sender]++;
				_safeMint(msg.sender, tokenId);
			}
		}
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedURI = _notRevealedURI;
	}
	
	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

	function reveal() public onlyOwner {
		revealed = !revealed;
	}
	
	function setOnlyPresale(bool _state) public onlyOwner {
		onlyPresale = _state;
	}
	
	function presaleUsers(address[] calldata _users) public onlyOwner {
		delete presaleAddresses;
		presaleAddresses = _users;
	}
	
	function withdraw() external payable onlyOwner {
		uint256 balance = address(this).balance;

		payable(msg.sender).transfer(balance);
    }
}