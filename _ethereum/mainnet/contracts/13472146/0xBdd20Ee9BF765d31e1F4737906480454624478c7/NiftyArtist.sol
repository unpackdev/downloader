// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 _______  .__  _____  __              _____          __  .__          __   
 \      \ |__|/ ____\/  |_ ___.__.   /  _  \________/  |_|__| _______/  |_ 
 /   |   \|  \   __\\   __<   |  |  /  /_\  \_  __ \   __\  |/  ___/\   __\
/    |    \  ||  |   |  |  \___  | /    |    \  | \/|  | |  |\___ \  |  |  
\____|__  /__||__|   |__|  / ____| \____|__  /__|   |__| |__/____  > |__|  
        \/                 \/              \/                    \/        
 */

import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract NiftyArtist is ERC721EnumerableUpgradeable,  AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    string public baseURI;

    address public _royaltyAddr;
    uint256 public _royaltyBps;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant INFRA_ROLE = keccak256("INFRA_ROLE");

    bool public hasSaleStarted;

    // Max NFTs total.
    uint public constant MAX_TOKENS = 9241;

    address public treasuryAddress;
    uint256 public tokenPrice;

    string public contractMeta;


    function initialize(string memory name, string memory symbol, string memory uri) public virtual initializer {
        __ERC721_init(name, symbol);
        __ReentrancyGuard_init();

        // Setup Role Based Access
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(INFRA_ROLE, msg.sender);
        setTreasury(msg.sender);

        // Creator is the initial royalty reciever.
        _royaltyAddr = msg.sender;
        _royaltyBps = 1000;

        baseURI = uri;

        tokenPrice = 50000000000000000;

        hasSaleStarted = false;
        contractMeta = "https://jrmeta.niftyunderground.app/ipfs/QmbHrSzxEUAqrLJv3n1dXVLeFgtdB75jybjpNPNERwu1JR";
    }

     function startSale() public  {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        hasSaleStarted = true;
    }

    function pauseSale() public  {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        hasSaleStarted = false;
    }

    function mint(address to, uint qty) public virtual payable nonReentrant {
        require(totalSupply() < MAX_TOKENS,
           "We are at max supply. Check out the secondary markets.");
        require(qty <= 5 && qty > 0, "Limited to mint up to 5 pieces at a time.");

        uint256 totalPrice = calculatePrice() * qty;

        require(msg.value >= totalPrice,
           "Ether value sent is below the price");

        uint256 index;
        for (index = 0; index < qty; index++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }

    }  

    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale has not started");
        require(totalSupply() < MAX_TOKENS,
                "We're at max supply!");

        return tokenPrice;  // 0.05 ETH
    }

    function setPrice(uint256 price) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");

        tokenPrice = price;
    }

    /*
    * Only valid before the sales starts, for giveaways/team thank you's
    */
    function reserve(address to, uint256 numTokens) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(hasSaleStarted == false, "Only valid when sale is not started");
        require(totalSupply() < MAX_TOKENS,
                "We're at max supply!");
        uint256 index;
        // Reserved for people who helped this project and future events.
        for (index = 0; index < numTokens; index++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }
    }

    // ERC-2981 
    function royaltyInfo(uint256 tokenId_, uint256 value_) public view returns (address _reciever, uint256 _royaltyAmount) {
        return (_royaltyAddr, _royaltyBps);
    }

    // Support the Royalties Interface ERC-2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == 0x2a55205a // ERC-2981
            || super.supportsInterface(interfaceId);
    }

    function setRoyalty(uint256 bps, address distAddress) public virtual {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");

        _royaltyBps = bps;
        _royaltyAddr = distAddress;
    }


    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public {
        require(hasRole(INFRA_ROLE, msg.sender), "Caller is not of infra role.");

        baseURI = uri;
    }

    function setTreasury(address addr) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");

        treasuryAddress = addr;
    }

    function withdrawAll() public payable {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");

        uint256 balance = address(this).balance;
        require(balance > 0);
 
        _widthdraw(treasuryAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function contractURI() public view returns (string memory) {
        return contractMeta;
    }

    function setContractURI(string memory uri) public {
        require(hasRole(INFRA_ROLE, msg.sender), "Caller is not of infra role.");

        contractMeta = uri;
    }
}
