// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";


contract LFT is Ownable, ERC721Enumerable {

    using Strings for uint256;

    event SaleStatusChanged(bool _from, bool _to);
    event MintPriceChanged(uint256 _from, uint256 _to);
    event TokensAvailableToSellChanged(uint256 _from, uint256 _to);
    event Reveal();

    uint256 private constant MAX_TOKENS = 10000;
    uint256 private constant MAX_TIER1_TOKENS_PERCENT = 5;
    uint256 private constant MAX_TIER1_TOKENS = (MAX_TOKENS / 100) * MAX_TIER1_TOKENS_PERCENT; // 500
    uint256 private constant MAX_TIER2_TOKENS = MAX_TOKENS - MAX_TIER1_TOKENS; // 9500
    uint256 private constant MAX_TIER1_DROP_CHANCE = 5; //percents

    //we save tier1 tokens here
    mapping(uint256 => bool) private _tier1Tokens;
    uint256 private _tier1TokensCount;

    //we change this value for sales waves
    uint256 private _tokensAvailableToSell;
    uint256 private _tokensAvailablePerMint;
    uint256 private _tokenPrice;

    bool private _isSaleActive;
    bool private _isRevealed = false;

    string private _tokenBaseURI;
    string private _contractMetadataURI;

    constructor(
        bool saleStatus,
        uint256 tokenPrice,
        uint256 tokensAvailableToSell,
        uint256 tokensAvailablePerMint,
        string memory baseURI,
        string memory contractMetadataURI
    ) ERC721("Legionfarm Celebrities Collection", "LFT") {

        _isSaleActive = saleStatus;
        _tokenPrice = tokenPrice;
        _tokensAvailableToSell = tokensAvailableToSell;
        _tokensAvailablePerMint = tokensAvailablePerMint;
        _tokenBaseURI = baseURI;
        _contractMetadataURI = contractMetadataURI;
    }

    ////////////// variables ///////////////
    function setTokensAvailableToSell(uint256 tokensAvailableToSell) external onlyOwner {
        require(tokensAvailableToSell <= MAX_TOKENS, "Cannot be more than 10000");

        uint256 tokensAvailableToSellOld = _tokensAvailableToSell;
        _tokensAvailableToSell = tokensAvailableToSell;

        emit TokensAvailableToSellChanged(tokensAvailableToSellOld, tokensAvailableToSell);
    }

    function getTokensAvailableToSell() external view returns (uint256) {
        return _tokensAvailableToSell;
    }

    function setTokensAvailablePerMint(uint256 tokensAvailablePerMint) external onlyOwner {
        _tokensAvailablePerMint = tokensAvailablePerMint;
    }

    function getTokensAvailablePerMint() external view returns (uint256) {
        return _tokensAvailablePerMint;
    }

    function setSaleStatus(bool saleStatus) external onlyOwner {
        bool isSaleActiveOld = _isSaleActive;
        _isSaleActive = saleStatus;

        emit SaleStatusChanged(isSaleActiveOld, saleStatus);
    }

    function getSaleStatus() external view returns (bool) {
        return _isSaleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        uint256 oldPrice = _tokenPrice;
        _tokenPrice = newPrice;

        emit MintPriceChanged(oldPrice, newPrice);
    }

    function getPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function setContractMetadataURI(string memory metadataURI) external onlyOwner {
        _contractMetadataURI = metadataURI;
    }

    function getTier1TokensCount() public view returns (uint256) {
        return _tier1TokensCount;
    }

    function getTier2TokensCount() public view returns (uint256) {
        if (!_isRevealed) {
            return 0;
        }

        return totalSupply() - getTier1TokensCount();
    }

    ///////////// logic ////////////////////

    function contractURI() external view returns (string memory) {
        return _contractMetadataURI;
    }

    function getTokenTier(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!_isRevealed) {
            return 0;
        }

        if (_tier1Tokens[tokenId]) {
            return 1;
        }

        return 2;
    }

    function mint(uint256 count) external payable {
        uint256 totalSupplyCount = totalSupply();
        uint256 tokensAvailableToSell = _tokensAvailableToSell;

        require(_isSaleActive, "Sale is not active");
        require(count <= _tokensAvailablePerMint, string(abi.encodePacked("Count available to mint: ", _tokensAvailablePerMint.toString())));
        require(msg.value == (_tokenPrice * count), "Incorrect ETH amount");
        require((totalSupplyCount + count) <= tokensAvailableToSell, "Cannot mint more tokens");

        bool isRevealed = _isRevealed;

        bool isFullSupply;
        bool onlyTier1Left;
        bool tier1Changed = false;

        uint256 tier1TokensCount;
        uint256 tier2TokensCount;

        if (isRevealed) {
            tier1TokensCount = _tier1TokensCount;
            isFullSupply = tokensAvailableToSell == MAX_TOKENS;
            tier2TokensCount = totalSupplyCount - tier1TokensCount;
        }

        for (uint256 i = 0; i < count; i++) {
            totalSupplyCount++;
            uint256 newItemId = totalSupplyCount;
            _safeMint(msg.sender, newItemId);

            if (isRevealed && tier1TokensCount < MAX_TIER1_TOKENS) {
                onlyTier1Left = isFullSupply && (MAX_TIER2_TOKENS == tier2TokensCount);

                if (onlyTier1Left || calculateTokenTier(newItemId * (i + 1)) == 1) {
                    _tier1Tokens[newItemId] = true;
                    tier1Changed = true;
                    tier1TokensCount++;
                } else {
                    tier2TokensCount++;
                }
            }
        }

        if (tier1Changed) {
            _tier1TokensCount = tier1TokensCount;
        }
    }

    function mintOwner(uint256 count, uint256 seed) external onlyOwner {
        uint256 totalSupplyCount = totalSupply();
        uint256 tokensAvailableToSell = _tokensAvailableToSell;

        require((totalSupplyCount + count) <= _tokensAvailableToSell, "Cannot mint more tokens");

        bool isRevealed = _isRevealed;

        bool isFullSupply;
        bool onlyTier1Left;
        bool tier1Changed = false;

        uint256 tier1TokensCount;
        uint256 tier2TokensCount;

        if (isRevealed) {
            tier1TokensCount = _tier1TokensCount;
            isFullSupply = tokensAvailableToSell == MAX_TOKENS;
            tier2TokensCount = totalSupplyCount - tier1TokensCount;
        }

        for (uint256 i = 0; i < count; i++) {
            totalSupplyCount++;
            uint256 newItemId = totalSupplyCount;
            _safeMint(msg.sender, newItemId);

            if (isRevealed && tier1TokensCount < MAX_TIER1_TOKENS) {
                onlyTier1Left = isFullSupply && (MAX_TIER2_TOKENS == tier2TokensCount);

                if (onlyTier1Left || calculateTokenTier(seed * (i + 1)) == 1) {
                    _tier1Tokens[newItemId] = true;
                    tier1Changed = true;
                    tier1TokensCount++;
                } else {
                    tier2TokensCount++;
                }
            }
        }

        if (tier1Changed) {
            _tier1TokensCount = tier1TokensCount;
        }
    }

    function calculateTokenTier(uint256 seed) internal view returns (uint256) {
        uint256 randomChance = getRandom(seed, 100) + 1;

        if (randomChance <= MAX_TIER1_DROP_CHANCE) {
            return 1;
        } else {
            return 2;
        }
    }

    //Reveal step 1. To set tiers for minted boxes
    function setTokenTierBunch(uint256 limit, uint256 seed) external onlyOwner {
        require(!_isRevealed, "Already revealed");

        _isSaleActive = false;

        uint256 tier1TokensCount = getTier1TokensCount();
        uint256 totalSupplyCount = totalSupply();

        uint256 totalTier1ToSetCount = (totalSupplyCount * MAX_TIER1_TOKENS_PERCENT) / 100; //cannot be more than 5% of total supply for current sale wave
        uint256 iterLimit = totalTier1ToSetCount - tier1TokensCount;
        iterLimit = limit > iterLimit ? iterLimit : limit;

        if (iterLimit == 0) {
            return;
        }

        uint256 randomTokenId;

        for (uint256 i = 0; i < iterLimit; i++) {

            do {
                randomTokenId = getRandom(seed * (i + 1) + randomTokenId, totalSupplyCount) + 1;
            } while (_tier1Tokens[randomTokenId] == true);

            _tier1Tokens[randomTokenId] = true;
            tier1TokensCount++;
        }

        _tier1TokensCount = tier1TokensCount;
    }

    //Reveal step 2. After setTokenTierBunch. To set collection "Revealed"
    function setRevealDone() external onlyOwner {
        require(!_isRevealed, "Already revealed");
        _isRevealed = true;
        _isSaleActive = true;

        emit Reveal();
    }

    //zero-based pseudo random
    function getRandom(uint256 seed, uint256 modulus) internal view returns (uint256) {
        uint256 randomHash = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed, block.difficulty))) % modulus;
        return randomHash;
    }

    function withdraw() external onlyOwner {
        address _owner = owner();
        address payable _owner_payable = payable(_owner);
        _owner_payable.transfer(address(this).balance);
    }

    function getTier1TokenIds(uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        uint256 totalSupplyCount = totalSupply();
        uint256 maxLimit = getMaxLimit(totalSupplyCount, offset, limit);
        uint256[] memory resMap = new uint256[](maxLimit);

        if (maxLimit == 0) {
            return resMap;
        }

        uint256 counter = 0;

        for (uint256 i = 0; i < maxLimit; i++) {
            if (_tier1Tokens[i + offset + 1] == true) {
                resMap[counter] = i + offset + 1;
                counter++;
            }
        }

        uint256[] memory res = new uint256[](counter);

        for (uint256 i = 0; i < counter; i++) {
            res[i] = resMap[i];
        }

        return res;
    }

    function getTokenAddressMap(uint256 offset, uint256 limit) external view returns (uint256[] memory, address[] memory) {
        uint256 totalSupplyCount = totalSupply();
        uint256 maxLimit = getMaxLimit(totalSupplyCount, offset, limit);

        address[] memory addresses = new address[](maxLimit);
        uint256[] memory tokenIds = new uint256[](maxLimit);

        uint256 counter = 0;
        for (uint256 i = 0; i < maxLimit; i++) {
            addresses[counter] = ownerOf(i + offset + 1);
            tokenIds[counter] = i + offset + 1;

            counter++;
        }

        return (tokenIds, addresses);
    }

    function getTokenListByAddress(address owner, uint256 offset, uint256 limit) external view returns (uint256[] memory) {
        uint256 addressTokensCount = balanceOf(owner);
        uint256 maxLimit = getMaxLimit(addressTokensCount, offset, limit);
        uint256[] memory res = new uint256[](maxLimit);

        if (maxLimit == 0) {
            return res;
        }

        uint256 counter = 0;

        for (uint256 i = 0; i < maxLimit; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i + offset);

            res[counter] = tokenId;
            counter++;
        }

        return res;
    }

    function tier1balanceOf(address owner, uint256 offset, uint256 limit) external view returns (uint256) {
        uint256 addressTokensCount = balanceOf(owner);
        uint256 maxLimit = getMaxLimit(addressTokensCount, offset, limit);
        uint256 res = 0;

        for (uint256 i = 0; i < maxLimit; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i + offset);
            if (_tier1Tokens[tokenId] == true) {
                res++;
            }
        }

        return res;
    }

    function tier2balanceOf(address owner, uint256 offset, uint256 limit) external view returns (uint256) {
        uint256 addressTokensCount = balanceOf(owner);
        uint256 maxLimit = getMaxLimit(addressTokensCount, offset, limit);
        uint256 res = 0;

        for (uint256 i = 0; i < maxLimit; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i + offset);
            if (_tier1Tokens[tokenId] == false) {
                res++;
            }
        }

        return res;
    }

    function getMaxLimit(uint256 total, uint256 offset, uint256 limit) internal pure returns (uint256) {
        uint256 maxLimit;
        if (total >= (offset + limit)) {
            maxLimit = limit;
        } else if (offset > total) {
            maxLimit = 0;
        } else {
            maxLimit = total - offset;
        }

        return maxLimit;
    }
}