// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./CamelCoin.sol";


contract CamelClanUtility is ERC721Enumerable {

    CamelCoin public immutable camelCoin;

    address public owner;
    string public baseURI; 
    string public baseExtension = ".json";
    uint256 public  maxSupply = 660;

    mapping(address => bool) public whiteListAddresses;
    mapping(address => uint256) public addressTokenCount;
    mapping(uint256 => string) public uriMap;

    mapping (address => mapping (uint256 => uint256)) tierTokenCount;

    mapping(uint256 => uint256) public tierCounts;
    mapping(uint256 => Tier) public tokenTier;

    mapping(uint256 => uint256) public tokenMintedAt;
    mapping(uint256 => uint256) public tokenLastTransferredAt;

    uint256 public tokenID = 1; // starting at 1 because of IPFS data


    struct Prices {
        uint256 bronzePrice;
        uint256 silverPrice;
        uint256 goldPrice;
        uint256 brailPrice;
    } 

    Prices public _prices = Prices({
        bronzePrice: 1_400,
        silverPrice: 7_000,
        goldPrice: 14_000,
        brailPrice: 70_000
        });

    //-- Tiers --//

    // Public tier info
    struct Tier {
        uint256 id;
        string name;
    }

    // Private tier info
    struct TierInfo {
        Tier tier;
        uint256 startingOffset;
        uint256 totalSupply;
        uint256 price;
        uint256 maxTotalMint;
        bool saleEnded;
    }

    // Bronze Tier - public info
    Tier public bronzeTier = Tier({id: 1, name: "Bronze"});

    // Bronze Tier - private info
    TierInfo private bronzeTierInfo =
        TierInfo({
            tier: bronzeTier,
            startingOffset: 1,
            totalSupply: 500,
            price: 1_400,
            maxTotalMint: 10,
            saleEnded: false
        });

    // Silver Tier - public info
    Tier public silverTier = Tier({id: 2, name: "Silver"});

    // Silver Tier - private info
    TierInfo private silverTierInfo =
        TierInfo({
            tier: silverTier,
            startingOffset: 501,
            totalSupply: 100,
            price: 7_000,
            maxTotalMint: 4,
            saleEnded: false
        });

    // Gold Tier - public info
    Tier public goldTier = Tier({id: 3, name: "Gold"});

    // Gold Tier - private info
    TierInfo private goldTierInfo =
        TierInfo({
            tier: goldTier,
            startingOffset: 601,
            totalSupply: 50,
            price: 14_000,
            maxTotalMint: 2,
            saleEnded: false
        });

    // Brail Tier - public info
    Tier public brailTier = Tier({id: 4, name: "Brail"});

    // Brail Tier - private info
    TierInfo private brailTierInfo =
        TierInfo({
            tier: brailTier,
            startingOffset: 651,
            totalSupply: 10,
            price: 70_000,
            maxTotalMint: 1,
            saleEnded: false
        });



    Tier[] public allTiersArray;
    TierInfo[] private allTiersInfoArray;

    uint256[] public allTierIds;

    mapping(uint256 => Tier) public allTiers;
    mapping(uint256 => TierInfo) private allTiersInfo;


    constructor(address _camelAddr, string memory _newBaseURI) ERC721("CamelClans Utility Token", "CMLUTIL") {
        owner = msg.sender;
        camelCoin = CamelCoin(_camelAddr);

        Tier[4] memory allTiersArrayMem = [bronzeTier, silverTier, goldTier, brailTier];
        TierInfo[4] memory allTiersInfoArrayMem = [
            bronzeTierInfo,
            silverTierInfo,
            goldTierInfo,
            brailTierInfo
        ];

        for (uint256 i = 0; i < allTiersArrayMem.length; i++) {
            uint256 tierId = allTiersArrayMem[i].id;

            // Tier arrays
            allTiersArray.push(allTiersArrayMem[i]);
            allTiersInfoArray.push(allTiersInfoArrayMem[i]);

            allTierIds.push(tierId);

            // Tier mappings
            allTiers[tierId] = allTiersArray[i];
            allTiersInfo[tierId] = allTiersInfoArray[i];
        }
        whiteListAddresses[_msgSender()] = true; 
        setBaseURI(_newBaseURI);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action");
        _;
    }

    // Mint token - requires tier and amount
    function mint(uint256 _tierId, uint256 _amount) public payable {
        Tier memory tier = allTiers[_tierId];
        TierInfo memory tierInfo = allTiersInfo[_tierId];

        require(tier.id == _tierId, "Invalid tier");

        // Must mint at least one
        require(_amount > 0, "Must mint at least one");

        // Get current address total balance
        uint256 currentTotalAmount = camelCoin.balanceOf(_msgSender());

        uint256 burnPrice = tierInfo.price * (10**camelCoin.decimals());

        require(currentTotalAmount >= burnPrice * _amount, "Revert: minting wallet does not have enought CMLCOIN");

        require(totalSupply() + _amount <= maxSupply, "Mint would exceed the total maximum supply");

        if (!whiteListAddresses[_msgSender()]) {
            require(tierTokenCount[_msgSender()][_tierId] + _amount <= allTiersInfo[_tierId].maxTotalMint, "Mint would exceed maximum mint amount for tier"); 
        }



        for (uint256 i = 0; i < _amount; i++) {
            // Token id is tier starting offset plus count of already minted
            uint256 tokenId = tierInfo.startingOffset + tierCounts[tier.id];
            require(camelCoin.approve(address(this), burnPrice), "Not Approved");
            camelCoin.burnFrom(_msgSender(), burnPrice);
            // Safe mint
            _safeMint(_msgSender(), tokenId);

            // Attribute token id with tier
            tokenTier[tokenId] = tier;

            // Store minted at timestamp by token id
            tokenMintedAt[tokenId] = block.timestamp;

            // Store tokenURI
            uriMap[tokenID] = tokenURI(tokenID);

            // Stores tier token count for address
            tierTokenCount[_msgSender()][_tierId] = tierTokenCount[_msgSender()][_tierId] + _amount;
            
            // Increment tier counter
            tierCounts[tier.id] = tierCounts[tier.id] + 1;
        }
    }

    // ----------------------------- //
    //  IPFS/OPEANSEA FUNCTIONALITY //
    // --------------------------  //

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }


    // Setters

    function setPrices(uint256 bronzePrice, uint256 silverPrice, uint256 goldPrice, uint256 brailPrice) external onlyOwner {
        _prices.bronzePrice = bronzePrice;
        _prices.silverPrice = silverPrice;
        _prices.goldPrice = goldPrice;
        _prices.brailPrice = brailPrice;
    }
}
