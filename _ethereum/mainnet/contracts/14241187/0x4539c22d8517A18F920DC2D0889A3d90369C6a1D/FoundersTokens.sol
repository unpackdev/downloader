pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract FoundersTokens is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private _owner;

    uint32 private MAX_TOKENS = 3999;

    //uint256 SEED_NONCE = 0;

    uint256 private MAXQ = 3;

    uint256 private SALE_PRICE = 0.08 ether;

    uint256 private PRESALE_HOURS = 24 hours;

    uint256 private balance = 0;

    uint256 private _startDateTime;

    uint256 private _endDateTime;

    bool private isWhiteListSale;
    
    bool private REVEAL = false;

    string private baseURI = "";

    //mapping (uint256 => string) private _tokenURIs;

    //mapping (string => uint256[]) private _hashes;

    //mapping (string => bool) private _hashComplete;

    mapping (address => uint256) private _mappingWhiteList;

    mapping (address => bool) private _mappingFreeList;

    mapping (address => uint256) private mintTracker;

    //mapping(string => bool) hashToMinted;

    //mapping(uint256 => string) internal tokenIdToHash;

    mapping(uint256 => Trait) private tokenIdTrait;

    //uint arrays
    //uint16[][2] TIERS;

    uint16[][4] RARITIES; // = [[695, 695, 695, 695], [150, 150, 150, 150], [100, 100, 100, 100], [50, 50, 50, 50], [5, 5, 5, 5]];


    struct Trait {
        uint16 artType;
        uint16 materialType;
    }

    string[] private artTypeValues = [
        'Mean Cat',
        'Mouse',
        'Marshal',
        'Hero'
    ];

    string[] private materialTypeValues = [
        'Paper',
        'Bronze',
        'Silver',
        'Gold',
        'Ghostly'
    ];

    /*mapping(uint256 => address) private idOwners;

    mapping(string=>address) public type_to_contract;

    mapping(uint256=>string[]) public attribute_values;

    mapping(uint256=>string[]) public attribute_types;*/

    constructor() ERC721("Ghost Town Founders Pass", "GTFP") public {
        _owner = msg.sender;

        _tokenIds.increment();

        //Declare all the rarity tiers

        //Art
        //TIERS[0] = [5, 5, 5, 5];//TIERS[0] = [1000, 1000, 1000, 1000]; // Mean Cat, MM, FM, Landscape
        //material
        //TIERS[1] = [10, 4, 3, 2, 1]; // paper, bronze, silver, gold, ghostly

        //RARITIES[0] = [695, 695, 695, 695]; //, [150, 150, 150, 150], [100, 100, 100, 100], [50, 50, 50, 50], [5, 5, 5, 5]];
        //RARITIES[1] = [150, 150, 150, 150];
        //RARITIES[2] = [100, 100, 100, 100];
        //RARITIES[3] = [50, 50, 50, 50];
        //RARITIES[4] = [5, 5, 5, 5];

        RARITIES[0] = [695, 150, 100, 50, 5]; // rotating creates a better overall random distribution
        RARITIES[1] = [695, 150, 100, 50, 5];
        RARITIES[2] = [695, 150, 100, 50, 5];
        RARITIES[3] = [695, 150, 100, 50, 5];
    }

    /*function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }*/

    function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        //string memory _tokenURI = _tokenURIs[tokenId];
        //string(abi.encodePacked("ipfs://"));
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function startSale(uint256 dt, bool whiteList) external onlyOwner {
        _startDateTime = dt;
        _endDateTime = dt + PRESALE_HOURS;
        isWhiteListSale = whiteList;
    }

    function setWhiteList(address[] calldata whiteListAddress, uint8[] calldata amount) external onlyOwner {
        for (uint256 i = 0; i < whiteListAddress.length; i++) {
            _mappingWhiteList[whiteListAddress[i]] = amount[i];
        }
    }

    function setFreeList(address[] calldata freeListAddress, bool bEnable) external onlyOwner {
        for (uint256 i = 0; i < freeListAddress.length; i++) {
            _mappingFreeList[freeListAddress[i]] = bEnable;
        }
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setReveal(bool _reveal) external onlyOwner {
        REVEAL = _reveal;
    }

    function mintPresale(uint256 numberOfMints) public payable {
        uint256 reserved = _mappingWhiteList[msg.sender];
        require(isWhiteListSale, "No presale active");
        require(reserved > 0 || msg.sender == _owner, "This address is not authorized for presale");
        require(numberOfMints <= reserved || msg.sender == _owner, "Exceeded allowed amount");
        require(_tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, "This would exceed the max number of allowed nft");
        require(numberOfMints * SALE_PRICE <= msg.value || (_mappingFreeList[msg.sender] && numberOfMints == 1) || msg.sender == _owner, "Amount of ether is not enough");

        _mappingWhiteList[msg.sender] = reserved - numberOfMints;
        if (msg.value < SALE_PRICE) {
            _mappingFreeList[msg.sender] = false;
        }

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            tokenIdTrait[newItemId] = createTraits(newItemId, msg.sender);

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function createItem(uint256 numberOfTokens) public payable returns (uint256) {
        require(((block.timestamp >= _startDateTime && block.timestamp < _endDateTime  && !isWhiteListSale) || msg.sender == _owner), "sale not active");
        require(msg.value >= SALE_PRICE || msg.sender == _owner, "not enough money");
        require(((mintTracker[msg.sender] + numberOfTokens) <= MAXQ || msg.sender == _owner), "ALready minted during sale");

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require((newItemId - 1 + numberOfTokens) <= MAX_TOKENS, "collection fully minted");

        mintTracker[msg.sender] = mintTracker[msg.sender] + numberOfTokens;

        for (uint256 i=0; i < numberOfTokens; i++) {
            tokenIdTrait[newItemId] = createTraits(newItemId, msg.sender);

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }

    /*function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i.toString();
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }*/

    /*function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 9 character string.
        //The last 8 digits are random, the first is 0, due to the mouse not being burned.
        string memory currentHash = "0";

        for (uint8 i = 0; i < 8; i++) {
            SEED_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);

        return currentHash;
    }*/

    function weightedRarityGenerator(uint16 pseudoRandomNumber) private returns (uint8, uint8) {
        uint16 lowerBound = 0;

        for (uint8 i = 0; i < RARITIES.length; i++) {
            for (uint8 j = 0; j < RARITIES[i].length; j++) {
                uint16 weight = RARITIES[i][j];

                if (pseudoRandomNumber >= lowerBound && pseudoRandomNumber < lowerBound + weight) {
                    RARITIES[i][j] -= 1;
                    return (i, j);
                }

                lowerBound = lowerBound + weight;
            }
        }

        revert();
    }

    function createTraits(uint256 tokenId, address _msgSender) private returns (Trait memory) {
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender, tokenId)));

        uint256 tokensMinted = itemsMinted();
        (uint8 a, uint8 m) = weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 1) % (1 + MAX_TOKENS - tokensMinted)));
        return
            Trait({
                artType: a,
                materialType: m
            });
    }

    function withdraw() onlyOwner public {
        require(address(this).balance > 0, "0 balance");
        payable(_owner).transfer(address(this).balance);
    }

    function getTraits(uint256 tokenId) public view returns (string memory artType, string memory materialType) {
        require(REVEAL, "reveal not set yet");
        Trait memory trait = tokenIdTrait[tokenId];
        artType = artTypeValues[trait.artType];
        materialType = materialTypeValues[trait.materialType];
    }

    function getWLSpots(address wl) public view returns (uint256) {
        return _mappingWhiteList[wl];
    }

    function getFreeSpot(address wl) public view returns (bool) {
        return _mappingFreeList[wl];
    }

    function itemsMinted() public view returns(uint) {
        return _tokenIds.current() - 1;
    }

    function ownerBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function saleTimes() public view returns(uint256, uint256, bool) {
        return (_startDateTime, _endDateTime, isWhiteListSale);
    }

}