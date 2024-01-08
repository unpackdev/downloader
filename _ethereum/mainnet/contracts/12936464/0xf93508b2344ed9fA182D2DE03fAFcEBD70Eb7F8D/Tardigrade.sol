pragma solidity 0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";


contract TARDX is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public defaultURI = "ipfs://QmaNR7LcV2RQ1HN4VEH5XBXZBBcEH6iA6uSnAky8NFPr3s";
    string public baseURI = "ipfs://";
    
    bool public saleIsActive = false;
    bool public initialSaleEnded = false;

    uint public initialDropMaxSupply;
    uint maxTardxPurchase = 3;
    uint256 tardXPrice;
    uint256 airdropSupply;
    
    struct TardX {
        bool initialized;
        string dna;
        uint256 dominantTrait;
        uint256[2] parents;
        uint256[8] fightAttributes;
        uint256 purity;
        uint256 planet;
        uint256 level;
        uint256 xp;
        uint256 version;
    }

    mapping (uint256 => TardX) public tardXs;
    mapping (uint256 => string) tokenCIDs;
    mapping (address => bool) public proxyAddressRegistry;

    constructor(uint _initialDropMaxSupply, uint _airdropSupply, uint _tardXPrice) ERC721("TARDX Fight Club", "TARDX") { 
        initialDropMaxSupply = _initialDropMaxSupply;
        airdropSupply = _airdropSupply;
        setTardxPrice(_tardXPrice);
    }

    function addProxyAddress(address _address) public onlyOwner {
        proxyAddressRegistry[_address] = true;
    }

    function removeProxyAddress(address _address) public onlyOwner {
        proxyAddressRegistry[_address] = false;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(tokenCIDs[_tokenId]).length > 0 ? string(abi.encodePacked(baseURI, tokenCIDs[_tokenId])) : defaultURI;
    }
    
    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string calldata _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function proxyOrOwner() internal {
        require(msg.sender == owner() || proxyAddressRegistry[msg.sender], "Access Denied");
    }

    function setTardXCID(uint256 _tokenId, string memory _ipfsHash) public {
        proxyOrOwner();
        tokenCIDs[_tokenId] = _ipfsHash;
    }

    function setTokenCIDs(uint[] memory _tokenIds, string[] memory _tokenCIDs) public {
        proxyOrOwner();
        require(_tokenIds.length <= 100, "Limit 100 tokenIds");
        for(uint i = 0; i < _tokenIds.length; i++){
            tokenCIDs[_tokenIds[i]] = _tokenCIDs[i];
        }
    }

    function setTardXData(uint256 _tokenId, string calldata _dna, uint _dominantTrait, uint256 _purity, uint256 _planet, 
    uint256 _level, uint256 _xp, uint256[2] calldata _parents, uint[8] calldata _fightAttributes, uint _version) public {
        proxyOrOwner();
        require(_exists(_tokenId), "This tardX does not exist");
        tardXs[_tokenId].dna = _dna;
        tardXs[_tokenId].dominantTrait = _dominantTrait;
        tardXs[_tokenId].purity = _purity;
        tardXs[_tokenId].planet = _planet;
        tardXs[_tokenId].level = _level;
        tardXs[_tokenId].xp = _xp;
        tardXs[_tokenId].parents = _parents;
        tardXs[_tokenId].fightAttributes = _fightAttributes;
        tardXs[_tokenId].version = _version;
        tardXs[_tokenId].initialized = true;
    }

    function buyTardX(uint _numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint a tardX");
        require(_numberOfTokens <= maxTardxPurchase, "You cannot purchase these many tardXs at a time");
        require(totalSupply().add(_numberOfTokens) < (initialDropMaxSupply - airdropSupply), "Purchase would exceed max supply");
        require(tardXPrice.mul(_numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < (initialDropMaxSupply - airdropSupply)) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function airdropTardX(address _to,uint _numberOfTokens) public onlyOwner {
        require (_numberOfTokens <= airdropSupply, "No more tokens to airdrop");
        for (uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (airdropSupply > 0 && totalSupply() < initialDropMaxSupply) {
                _safeMint(_to, mintIndex);
                airdropSupply --;
            }
        }
    }

    function mintAsProxy(address _to, uint _numberOfTokens) public {
        proxyOrOwner();
        require(!saleIsActive || totalSupply() == initialDropMaxSupply, "Initial sale still active");
        for (uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
        }
    }

    function resumeSale() public onlyOwner {
        require(!initialSaleEnded, "Initial sale ended");
        saleIsActive = true;
    }

    function pauseSale() public onlyOwner {
        saleIsActive = false;
    }

    function endInitialSale() public onlyOwner {
        saleIsActive = false;
        initialSaleEnded = true;
    }

    function setTardxPrice(uint256 _tardXPrice) public onlyOwner {
        require(_tardXPrice > 0, "sale price cannot be null");
        tardXPrice = 1 ether / 1000 * _tardXPrice;
    }

    function withdrawAll() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        return super.transferOwnership(newOwner);
    }
}
