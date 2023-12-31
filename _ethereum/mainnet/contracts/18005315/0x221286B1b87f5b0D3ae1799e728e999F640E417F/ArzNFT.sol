// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


import "./ArzRaffle.sol";
import "./ArzStaking.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./console.sol";

/*
Things to Improve:
- Find a way to combine guaranteed and competitve whitelist to be more
  space efficient
*/

contract ArzNFT is ERC721A, Ownable, ReentrancyGuard, ERC2981 {

    ArzRaffle public arzRaffle;
    ArzStaking public arzStaking;


    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public provenanceHash;


    string public baseURI;
    string public baseExtension = ".json";
    

    bool public revealed = false;
    string public notRevealedUri;

    
    struct GuaranteedWhitelistInfo {
        uint256 SUPPLY;
        uint256 LIMIT_PER_ADDRESS;
        uint256 CURR_MINTED;
        uint256 PRICE;
        uint START_TIME;
        uint END_TIME;
    }
    GuaranteedWhitelistInfo public guaranteedWhitelistInfo;
    mapping(address => bool) GUARANTEED_WHITELIST_ADDRESSES;
    mapping(address => uint256) GUARANTEED_WHITELIST_CLAIMED;



    struct CompetitveWhitelistInfo {
        uint256 SUPPLY;
        uint256 LIMIT_PER_ADDRESS;
        uint256 CURR_MINTED;
        uint256 PRICE;
        uint START_TIME;
        uint END_TIME;
    }
    CompetitveWhitelistInfo public competitveWhitelistInfo;
    mapping(address => bool) COMPETITIVE_WHITELIST_ADDRESSES;
    mapping(address => uint256) COMPETITIVE_WHITELIST_CLAIMED;


    struct PublicInfo {
        uint256 SUPPLY;
        uint256 LIMIT_PER_ADDRESS;
        uint256 CURR_MINTED;
        uint256 PRICE;
        uint START_TIME;
        uint END_TIME;
    }
    PublicInfo public publicInfo;


    uint32 public royaltyPercentage;


    uint256 public mysteryBoxPrice;


    bool public paused = false;

    //Constructor
    constructor(
        string memory _NFT_NAME,
        string memory _NFT_SYMBOL,
        string memory _initBaseURI, 
        string memory _nonReveal,
        uint32 _royaltyPercentage
    ) 
        ERC721A(_NFT_NAME, _NFT_SYMBOL)
    {
        arzRaffle = new ArzRaffle(address(this));
        arzRaffle.transferOwnership(owner());
        arzStaking = new ArzStaking(address(this));
        arzStaking.transferOwnership(owner());
        setBaseURI(_initBaseURI);
        setPreRevealURI(_nonReveal);
        royaltyPercentage = _royaltyPercentage;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    ///////////////
    // Accessors //
    //////////////
    function setProvenanceHash(string calldata hash) public onlyOwner {
        provenanceHash = hash;
    }

    function getTotalSupply() public view returns (uint256) {
        return  guaranteedWhitelistInfo.SUPPLY + competitveWhitelistInfo.SUPPLY + publicInfo.SUPPLY;
    }

    function getTotalMinted() public view returns (uint256) {
        require(guaranteedWhitelistInfo.CURR_MINTED +
                competitveWhitelistInfo.CURR_MINTED +
                publicInfo.CURR_MINTED == totalSupply(), "Incorrect sum of minted tokens");
        return totalSupply();
    }

    function setMintingStatus(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function eligibleForMysteryBox(address _user) public view returns (bool holding) {
        if (balanceOf(_user) > 0) {
            return true;
        } else {
            return false; 
        }
    }


    ///////////////
    // Metadata //
    //////////////
     function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function reveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }

    function _preRevealURI() internal view virtual returns (string memory) {
        return notRevealedUri;
    }

    function setPreRevealURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealed) {
            return notRevealedUri;
        }

        // Returns baseURI (folder where metadata for all the tokens is stored) location
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    

    ///////////////////////////////
    // Guaranteed Whitelist Sale //
    //////////////////////////////
    function setGuaranteedWhitelistParams(
        uint256 _SUPPLY,
        uint256 _LIMIT_PER_ADDRESS,
        uint256 _PRICE_WEI,
        uint _START_TIME,
        uint _END_TIME
    ) public onlyOwner {
        require(
            (_START_TIME == 0 ||
            _END_TIME - _START_TIME > 0) && _PRICE_WEI >= 0,
            "Invalid guaranteed whitelist setup"
        );
        guaranteedWhitelistInfo = GuaranteedWhitelistInfo(
            _SUPPLY,
            _LIMIT_PER_ADDRESS,
            0,
            _PRICE_WEI * 1 wei,
            _START_TIME,
            _END_TIME
        );
    }

    function getGuaranteedWhitelistPrice() public view returns (uint256) {
        return guaranteedWhitelistInfo.PRICE;
    }

    function getGuaranteedWhitelistLimit() public view returns (uint256) {
        return guaranteedWhitelistInfo.LIMIT_PER_ADDRESS; 
    }

    function getGuaranteedWhitelistNumMinted() public view returns (uint256) {
        return guaranteedWhitelistInfo.CURR_MINTED;
    }

    function getGuaranteedWhitelistSupply() public view returns (uint256) {
        return guaranteedWhitelistInfo.SUPPLY;
    }

    function getOnGuaranteedWhitelist(address _user) public view returns (bool) {
        return GUARANTEED_WHITELIST_ADDRESSES[_user];
    }

    function getGuaranteedWhitelistTimesAvaliable(address _user) public view returns (uint256) {
        return GUARANTEED_WHITELIST_CLAIMED[_user];
    }

    function getGuaranteedWhitelistActive() public view returns (uint256) {
        if (block.timestamp < guaranteedWhitelistInfo.START_TIME) {
            return 0;
        } else if (block.timestamp >= guaranteedWhitelistInfo.START_TIME &&
            block.timestamp <= guaranteedWhitelistInfo.END_TIME) {
            return 1;
        } else {
            return 2;
        }
    }

    function guaranteedWhitelistMint(uint256 quantity) public payable nonReentrant {
        require(
            block.timestamp >= guaranteedWhitelistInfo.START_TIME &&
            block.timestamp <= guaranteedWhitelistInfo.END_TIME,
            "Guaranteed whitelist minting closed"
        );
        require(guaranteedWhitelistInfo.CURR_MINTED < guaranteedWhitelistInfo.SUPPLY, "Sold Out");
        require(GUARANTEED_WHITELIST_ADDRESSES[msg.sender], "Not on the guaranteed whitelist");
        require(GUARANTEED_WHITELIST_CLAIMED[msg.sender] > 0, "Claimed all avaliable times");
        require(quantity <= guaranteedWhitelistInfo.LIMIT_PER_ADDRESS, "Exceeded limit");
        require(msg.value == guaranteedWhitelistInfo.PRICE * quantity, "Incorrect amount");

        _internalMint(msg.sender, quantity);
        guaranteedWhitelistInfo.CURR_MINTED += quantity;
        GUARANTEED_WHITELIST_CLAIMED[msg.sender] -= 1; 
    }

    function addGuaranteedUser(address[] memory _addresses) public {
        require(msg.sender == owner() || msg.sender == address(arzRaffle), "Only owners can access this function");
        for (uint256 i; i < _addresses.length; i++) {
            GUARANTEED_WHITELIST_ADDRESSES[_addresses[i]] = true;
            GUARANTEED_WHITELIST_CLAIMED[_addresses[i]] += 1; 
        }
    }

    function removeGuaranteedUser(address _address) external onlyOwner {
        require(GUARANTEED_WHITELIST_ADDRESSES[_address], "Address is not on the guaranteed whitelist");
        delete GUARANTEED_WHITELIST_CLAIMED[_address]; 
        delete GUARANTEED_WHITELIST_ADDRESSES[_address]; 
    }

    /////////////////////////////////
    // Competitive Whitelist Sale //
    ////////////////////////////////
    function setCompetitiveWhitelistParams(
        uint256 _SUPPLY,
        uint256 _LIMIT_PER_ADDRESS,
        uint256 _PRICE_WEI,
        uint _START_TIME,
        uint _END_TIME
    ) public onlyOwner {
        require(
            (_START_TIME == 0 ||
            _END_TIME - _START_TIME > 0) && _PRICE_WEI >= 0,
            "Invalid competitive whitelist setup"
        );
        competitveWhitelistInfo = CompetitveWhitelistInfo(
            _SUPPLY,
            _LIMIT_PER_ADDRESS,
            0,
            _PRICE_WEI * 1 wei,
            _START_TIME,
            _END_TIME
        );
    }


    function getCompetitiveWhitelistPrice() public view returns (uint256) {
        return competitveWhitelistInfo.PRICE;
    }

    function getCompetitiveWhitelistLimit() public view returns (uint256) {
        return competitveWhitelistInfo.LIMIT_PER_ADDRESS; 
    }

    function getCompetitiveWhitelistNumMinted() public view returns (uint256) {
        return competitveWhitelistInfo.CURR_MINTED;
    }

    function getCompetitiveWhitelistSupply() public view returns (uint256) {
        return competitveWhitelistInfo.SUPPLY;
    }

    function getOnCompetitiveWhitelist(address _user) public view returns (bool) {
        return COMPETITIVE_WHITELIST_ADDRESSES[_user];
    }

    function getCompetitiveWhitelistTimesAvaliable(address _user) public view returns (uint256) {
        return COMPETITIVE_WHITELIST_CLAIMED[_user];
    }

    function getCompetitiveWhitelistActive() public view returns (uint256) {
        if (block.timestamp < competitveWhitelistInfo.START_TIME) {
            return 0;
        } else if (block.timestamp >= competitveWhitelistInfo.START_TIME &&
            block.timestamp <= competitveWhitelistInfo.END_TIME) {
            return 1;
        } else {
            return 2;
        }
    }

    function competitveWhitelistMint(uint256 quantity) public payable nonReentrant {
        require(
            block.timestamp >= competitveWhitelistInfo.START_TIME &&
            block.timestamp <= competitveWhitelistInfo.END_TIME,
            "Competitive whitelist minting closed"
        );
        require(competitveWhitelistInfo.CURR_MINTED < competitveWhitelistInfo.SUPPLY, "Sold Out");
        require(COMPETITIVE_WHITELIST_ADDRESSES[msg.sender], "Not on the competitive whitelist");
        require(COMPETITIVE_WHITELIST_CLAIMED[msg.sender] > 0, "Claimed all avaliable times");
        require(quantity <= competitveWhitelistInfo.LIMIT_PER_ADDRESS, "Exceeded mint limit");
        require(msg.value == competitveWhitelistInfo.PRICE * quantity, "Incorrect amount");

        _internalMint(msg.sender, quantity);
        competitveWhitelistInfo.CURR_MINTED += quantity;
        COMPETITIVE_WHITELIST_CLAIMED[msg.sender] -= 1;
    }

    function addCompetitveUser(address[] memory _addresses) public {
        require(msg.sender == owner() || msg.sender == address(arzRaffle), "Only owners can access this function");
        for (uint256 i; i < _addresses.length; i++) {
            COMPETITIVE_WHITELIST_ADDRESSES[_addresses[i]] = true;
            COMPETITIVE_WHITELIST_CLAIMED[_addresses[i]] += 1; 
        }
    }

    function removeCompetitveUser(address _address) external onlyOwner {
        require(COMPETITIVE_WHITELIST_ADDRESSES[_address], "Address is not on the competitive whitelist");
        delete COMPETITIVE_WHITELIST_CLAIMED[_address]; 
        delete COMPETITIVE_WHITELIST_ADDRESSES[_address];
    }


    //////////////////
    // Public Sale //
    /////////////////
    function setPublicParams(
        uint256 _SUPPLY,
        uint256 _LIMIT_PER_ADDRESS,
        uint256 _PRICE_WEI,
        uint _START_TIME,
        uint _END_TIME
    ) public onlyOwner {
        require(
            (_START_TIME == 0 ||
            _END_TIME - _START_TIME > 0) && _PRICE_WEI >= 0,
            "Invalid public minting setup"
        );
        publicInfo = PublicInfo(
            _SUPPLY,
            _LIMIT_PER_ADDRESS,
            0,
            _PRICE_WEI * 1 wei,
            _START_TIME,
            _END_TIME
        );
    }

    function getPublicPrice() public view returns (uint256) {
        return publicInfo.PRICE;
    }

    function getPublicLimit() public view returns (uint256) {
        return publicInfo.LIMIT_PER_ADDRESS; 
    }

    function getPublicNumMinted() public view returns (uint256) {
        return publicInfo.CURR_MINTED;
    }

    function getPublicSupply() public view returns (uint256) {
        return publicInfo.SUPPLY;
    }

    function getPublicActive() public view returns (uint256) {
        if (block.timestamp < publicInfo.START_TIME) {
            return 0;
        } else if (block.timestamp >= publicInfo.START_TIME &&
            block.timestamp <= publicInfo.END_TIME) {
            return 1;
        } else {
            return 2;
        }
    }

    function publicMint(uint256 quantity) public payable nonReentrant {
        require(
            block.timestamp >= publicInfo.START_TIME && block.timestamp <= publicInfo.END_TIME,
            "Public minting closed"
        );
        require(
            quantity <= publicInfo.LIMIT_PER_ADDRESS,
            "Exceeded mint limit"
        );
        require(publicInfo.CURR_MINTED < publicInfo.SUPPLY, "Sold Out");
        require(msg.value == publicInfo.PRICE * quantity, "Incorrect amount");

        _internalMint(msg.sender, quantity);
        publicInfo.CURR_MINTED += quantity;
    }


    //////////////
    // Airdrop //
    /////////////
    function airdrop(uint256 quantity, address[] memory _addresses)
        external
    {
        require(msg.sender == owner() || msg.sender == address(arzRaffle), "Only owners can access this function");
        require((totalSupply() + (_addresses.length * quantity)) <= getTotalSupply(), "Exceeded maximum supply");
        for (uint256 i; i < _addresses.length; i++) { 
            _internalMint(_addresses[i], quantity);
        }
    }


    //////////////
    // Royalty //
    /////////////
    function updateRoyaltyPercentage(uint32 _royaltyPercentage) external onlyOwner {
         require(
            _royaltyPercentage <= 20,
            "Royalty fee can't exceed %20"
        );
        royaltyPercentage = _royaltyPercentage;
    }

    function payRoyalty(uint256 _price) public payable {
        require(msg.value == _price, "Incorrect amount");

        uint256 royaltyAmount = (_price * royaltyPercentage) / 100; 
        payable(address(this)).transfer(royaltyAmount);
    }



    /////////////////
    // Some Stuff //
    ////////////////
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _internalMint(address to, uint256 quantity) private {
        require(!paused, "Minting unavaliable");
        require(
            (totalSupply() + quantity) <= getTotalSupply(),
            "Exceeded maximum supply"
        );
        
        _safeMint(to, quantity);
    }
    

    ////////////////
    // Interface //
    ///////////////
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}