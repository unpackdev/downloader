//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// xm = "would exceed max supply"
// tm = "Too many tokens"
// na = "null address"
// it = "invalid token"
// nw = "no multisig wallet set"
// pna = "presale not active"
// pa = "public sale not active"
// now = "not on white list"
// if = "Insufficient funds"
// am = "All tokens minted"

contract ZSUStudentOrientation is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string public provenanceUri;
    string public courseCreditsUri;

    uint256 public constant zombiePrice = 60000000000000000; //0.06 ETH

    uint256 public constant maxZombiePurchasePreSale = 3;
    uint256 public constant maxZombiePurchase = 10;

    uint256 public RESERVE = 500;
    uint256 public PUBLIC = 8388;
    uint256 public MAX_LEGENDARY_COUNT = 15;
    uint256 public MAX_ZOMBIES = RESERVE + PUBLIC;

    uint256 public totalReserveSupply;
    uint256 public totalZombieSupply;
    uint256 public totalLegendarySupply;

    bool public isPreSaleActive = false;
    bool public isPublicSaleActive = false;

    struct Student {
        uint256 studentId;
        uint8 classLevel;
        uint8 hasCustomUri;
        string customUri;
    }

    mapping(uint256 => Student) public Students;
    mapping(address => bool) private _PreSaleWhiteList;
    mapping(address => uint256) private _PreSaleWhiteListClaimed;
    mapping(uint256 => bool) private _isLegendary;
    mapping(uint256 => uint256) private _hasCustomUri;

    bool public reveal = false;

    string private baseURI;

    address public MULTI_WALLET = address(this);

    constructor(
        string memory name,
        string memory symbol,
        string memory startingUri,
        string memory creditsUri,
        address multiSigWallet
    ) ERC721(name, symbol) {
        baseURI = startingUri;
        courseCreditsUri = creditsUri;
        MULTI_WALLET = multiSigWallet;
        uint256 tokenId = MAX_LEGENDARY_COUNT + 1;
        setStudentId(tokenId, msg.sender);        
        totalZombieSupply += 1;
        totalReserveSupply += 1;
        _safeMint(msg.sender, tokenId);
    }

    function toggleWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "na");
            _PreSaleWhiteList[addresses[i]] = !_PreSaleWhiteList[addresses[i]];
            _PreSaleWhiteListClaimed[addresses[i]] > 0 ? _PreSaleWhiteListClaimed[addresses[i]] : 0;
        }
    }

    function isOnWhiteList(address addr) external view returns (bool) {
        return _PreSaleWhiteList[addr];
    }

    function PreSaleClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "na");
        return _PreSaleWhiteListClaimed[owner];
    }

    function _generateRandomStudentId(string memory _identifier)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_identifier))) % 10**24; //10 is modulus and 24 is student id digits based on number of layers
    }

    function getStudentId(uint256 tokenId) public view returns (uint256) {
        require(tokenId > 0, "it");
        return Students[tokenId].studentId;
    }

    function setStudentId(uint256 tokenId, address wallet) private {
        Students[tokenId] = Student(_generateRandomStudentId(string(abi.encodePacked(tokenId.toString(), wallet))), 0, 0, "");
    } 

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), 'token does not exist');
        if (reveal) {  
            if(Students[tokenId].hasCustomUri == 1) {
                return string(abi.encodePacked(Students[tokenId].customUri, tokenId.toString()));    
            } else {
                return string(abi.encodePacked(baseURI, tokenId.toString()));       
            }                       
        } else {
            return baseURI;
        }
    }

    function getCustomURI(uint256 tokenId, bool isCourseCredits)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), 'token does not exist');
        if(isCourseCredits) {
            return string(abi.encodePacked(courseCreditsUri, tokenId.toString()));
        } else {
            return provenanceUri;
        }     
    }

    function toggleSale(uint togglePreSale) public onlyOwner {
        if(togglePreSale == 1) {
            isPreSaleActive = !isPreSaleActive;
            isPublicSaleActive = false;
        } else {
            isPreSaleActive = false;
            isPublicSaleActive = !isPublicSaleActive;
        }        
    }

    function setURI(string memory newURI, uint256 uriType) public onlyOwner {
        //  normal or reveal = 1
        // provenance = 2
        if(uriType == 1) {
            baseURI = newURI;
        } else if(uriType == 2) {
            provenanceUri = newURI;
        }
    }

    function toggleReveal(string memory newBaseURI) public onlyOwner {
        reveal = !reveal;
        setURI(newBaseURI, 1);
    }

    function withdraw() external onlyOwner {
        require(MULTI_WALLET != address(this), "nw");
        payable(MULTI_WALLET).transfer(address(this).balance);
    }

    function sharedMintFunc(address wallet) private {
        uint256 tokenId = MAX_LEGENDARY_COUNT + totalZombieSupply + 1;                      
        setStudentId(tokenId, msg.sender);
        totalZombieSupply += 1;
        _safeMint(wallet, tokenId);
    }

    function mintPreSale(uint256 numberOfTokens) external payable {
        require(isPreSaleActive, "pna");
        require(_PreSaleWhiteList[msg.sender], "now");
        require(totalZombieSupply < MAX_ZOMBIES, "am");
        require(totalZombieSupply + numberOfTokens <= PUBLIC, "xm");
        require(_PreSaleWhiteListClaimed[msg.sender] + numberOfTokens <= maxZombiePurchasePreSale, "xm");
        require(numberOfTokens <= maxZombiePurchasePreSale, "tm");
        require(zombiePrice * numberOfTokens <= msg.value, "if");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _PreSaleWhiteListClaimed[msg.sender] += 1;  
            sharedMintFunc(msg.sender);
        }
    }

    function mintPublic(uint256 numberOfTokens) external payable {
        require(isPublicSaleActive, "pa");
        require(totalZombieSupply < MAX_ZOMBIES, "am");
        require(numberOfTokens <= maxZombiePurchase, "tm");
        require(totalZombieSupply + numberOfTokens <= PUBLIC, "xm");
        require(zombiePrice * numberOfTokens <= msg.value, "if");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            sharedMintFunc(msg.sender);
        }
    }

    function mintReserve(
        address[] calldata addresses,
        uint256 numberOfTokensPerAddress,
        bool isLegendary
    ) external payable onlyOwner {
        uint totalToMint = SafeMath.mul(numberOfTokensPerAddress, uint256(addresses.length));
        require(totalToMint < (MAX_ZOMBIES - totalZombieSupply), "am");   
        require(totalToMint < (RESERVE - totalReserveSupply), "xm");
        if(isLegendary) {
            require(totalToMint < (MAX_LEGENDARY_COUNT - totalLegendarySupply), "exceed max legendary");
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint256 t = 0; t < numberOfTokensPerAddress; t++) {
                if(isLegendary) {                    
                    uint256 tokenId = totalLegendarySupply + 1;                    
                    setStudentId(tokenId, msg.sender);
                    totalReserveSupply += 1;
                    totalZombieSupply += 1;
                    totalLegendarySupply += 1;
                    _safeMint(addresses[i], tokenId);
                } else {
                    totalReserveSupply += 1;
                    sharedMintFunc(addresses[i]);
                }                
            }
        }
    }

    function moveFromReserve(uint256 total) public onlyOwner {
        require(total <= RESERVE - totalReserveSupply, "na");
        RESERVE = RESERVE - total;
        PUBLIC = PUBLIC + total;
    }

    //  Let's not have to use this, huh?
    function burn(uint256 _newMax) public onlyOwner {
        require(totalZombieSupply < MAX_ZOMBIES, "am");
        require(_newMax >= totalZombieSupply, "Can't burn");
        MAX_ZOMBIES = _newMax;
    }
}
