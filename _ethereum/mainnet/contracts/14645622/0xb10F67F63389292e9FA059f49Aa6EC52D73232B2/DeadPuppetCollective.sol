//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";

contract DeadPuppetCollective is Ownable, ERC721A, ReentrancyGuard {
    uint256 public price = 0.035 ether;
    uint256 public constant supply = 5555;
    uint256 public constant presaleSpots = 2000;
    uint256 public constant maxPerTxPublicSale = 10;

    address internal constant puppetMaster = 0x9ff1D15341F08D13ff5cda6e6a33a82BfD9c3CC3; 
    address internal constant communityVault = 0xCFf2CADb68fa2EBd10327cc981F2c61CC169Bd2D;

    bool public presaleLive;
    bool public publicSaleLive;

    mapping (address => uint256) public allowlist;
    
    constructor() ERC721A("Dead Puppet Collective", "TDPC"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is contrat");
        _;
    }

    function presaleMint(uint256 _amount) public payable callerIsUser {
        require(presaleLive, "Not live");
        require(allowlist[msg.sender] > 0, "Not eligible");
        require(_amount > 0, "Not enough");        
        require(_amount <= allowlist[msg.sender], "Too many");        
        require(totalSupply() + _amount <= supply, "Exceeds supply");
        require(msg.value == _amount * price, "Wrong value");
        allowlist[msg.sender] = allowlist[msg.sender] - _amount;
        _safeMint(msg.sender, _amount);
    }

    function publicSaleMint(uint256 _amount) public payable callerIsUser {
        require(publicSaleLive, "Not live");
        require(_amount > 0, "Not enough");
        require(_amount <= maxPerTxPublicSale, "Too many");
        require(totalSupply() + _amount <= supply, "Exceeds supply");
        require(msg.value == _amount * price, "Wrong value");        
        _safeMint(msg.sender, _amount);
    }

    function flipPresale() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function flipPublicSale() external onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function seedAllowlist(address[] calldata _addresses, uint256[] calldata _spots) external onlyOwner {
        require(_addresses.length == _spots.length, "Mismatch");
        require(_addresses.length <= presaleSpots, "Too many");
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowlist[_addresses[i]] = _spots[i];
        }
    }

    // for marketing, team etc.
    function devMint(uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= supply, "Too many");
        _safeMint(msg.sender, _amount);
    }

    // metadata URI
    string private baseUri = "https://mint.deadpuppetco.io/api/json/";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string calldata _baseTokenUri) external onlyOwner {
        baseUri = _baseTokenUri;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer((amount * 12) / 100);
        payable(communityVault).transfer((amount * 40) / 100);
        payable(puppetMaster).transfer((amount * 48) / 100);
    }
}

