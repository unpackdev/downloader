// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./AggregatorV3Interface.sol";
import "./ReentrancyGuard.sol";

contract WealthCircle is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    bytes32 private merkleRoot;
    AggregatorV3Interface internal priceFeed;

    uint256 private tokenIdCounter = 0;
    enum SaleState {
        Inactive,
        WhitelistOnly,
        PublicSale
    }
    SaleState public saleState;
    mapping(address => uint8) public whitelistedUserMintCount;

    uint256 public buybackReserve = 0;

    struct TierData {
        uint256 tokenUsdPrice;
        uint256 tokenSupply;
        uint256 maxTokens;
        uint256 reservedTokensRemaining;
    }
    mapping(Tier => TierData) public tierData;

    mapping(uint256 => TokenInfo) public tokenInfos;

    string private _baseTokenURI;
    string private _contractURI;

    struct TokenInfo {
        uint256 tier;
        uint256 mintTimestamp;
        uint256 mintPrice;
        uint256 tokenTierIndex;
    }

    enum Tier {
        BRONZE,
        SILVER,
        GOLD
    }

    function initialize() public initializer {
        __ERC721_init("Wealth Circle by Betix.gg", "BETIXWC");
        __ERC721Enumerable_init();
        __ERC2981_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _contractURI = "ipfs://QmZxcpPzRaX2wM2FE4kuPjr5YXi5BmvDwC18BkVoH5Ysgb";
        _baseTokenURI = "ipfs://QmbzpERCjxbeWUuj8dDCCVJdSEYH42yqC7EWpVitASygiB/";

        priceFeed = AggregatorV3Interface(
            0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46
        );
        setTierInfo(Tier.BRONZE, 199, 2800, 280, 0);
        setTierInfo(Tier.SILVER, 499, 2400, 240, 0);
        setTierInfo(Tier.GOLD, 1299, 1000, 100, 0);
        _setDefaultRoyalty(msg.sender, 500);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeeInBips);
    }

    function setTierInfo(
        Tier tier,
        uint256 usdPrice,
        uint256 maxTokens,
        uint256 reservedTokens,
        uint256 tokenSupply
    ) private {
        tierData[tier].tokenUsdPrice = usdPrice;
        tierData[tier].tokenSupply = tokenSupply;
        tierData[tier].maxTokens = maxTokens;
        tierData[tier].reservedTokensRemaining = reservedTokens;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 tierId = tokenInfos[tokenId].tier;
        uint256 tokenOrderInTier = tokenInfos[tokenId].tokenTierIndex;
        return (
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    Strings.toString(tierId),
                    "/",
                    Strings.toString(tokenOrderInTier),
                    ".json"
                )
            )
        );
    }

    function setBaseTokenURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
    }

    function getTokenTier(uint256 tokenId) public view returns (uint256) {
        return tokenInfos[tokenId].tier;
    }

    function mintTokenWhitelist(
        Tier tier,
        uint8 amount,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(
            saleState == SaleState.WhitelistOnly,
            "Whitelist sale is not active"
        );
        require(
            whitelistedUserMintCount[msg.sender] + amount <= 3,
            "Mint exceeds allowed limit"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not whitelisted"
        );
        _mintToken(tier, amount);
        whitelistedUserMintCount[msg.sender] += amount;
    }

    function mintToken(Tier tier, uint256 amount) external payable {
        require(amount > 0 && amount <= 20, "Max 20 per tx");
        require(saleState == SaleState.PublicSale, "Sale is not active");
        _mintToken(tier, amount);
    }

    function _mintToken(Tier tier, uint256 amount) internal {
        require(
            tierData[tier].tokenSupply + amount <=
                tierData[tier].maxTokens -
                    tierData[tier].reservedTokensRemaining,
            "Purchase would exceed max supply"
        );

        (, int256 gweiUsdPrice, , , ) = priceFeed.latestRoundData();
        uint256 tokenPriceInWei = (tierData[tier].tokenUsdPrice * 1e26) /
            uint256(gweiUsdPrice);

        // price is dynamic, allow 0.1% error
        require(
            msg.value >= (tokenPriceInWei * amount * 999) / 1000,
            "Not enough funds for transaction"
        );

        uint256 newTokenId = tokenIdCounter;
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, newTokenId + i);
            tokenInfos[newTokenId + i] = TokenInfo({
                tier: uint256(tier),
                mintTimestamp: block.timestamp,
                mintPrice: tokenPriceInWei,
                tokenTierIndex: tierData[tier].tokenSupply + i
            });
        }
        tokenIdCounter += amount;
        tierData[tier].tokenSupply += amount;
        buybackReserve += (tokenPriceInWei * amount) / 2;
    }

    function buybackToken(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Must own the token");
        TokenInfo storage tokenInfo = tokenInfos[tokenId];

        require(
            block.timestamp - tokenInfo.mintTimestamp <= 365 days,
            "Buyback period has expired"
        );

        require(tokenInfo.mintPrice > 0, "Cannot refund free token");

        uint256 buybackAmount = tokenInfo.mintPrice / 2;
        require(
            buybackAmount <= address(this).balance,
            "Contract doesn't have enough funds"
        );
        tokenInfos[tokenId].mintPrice = 0;
        buybackReserve -= buybackAmount;
        payable(msg.sender).transfer(buybackAmount);
        _safeTransfer(
            msg.sender,
            OwnableUpgradeable.owner(),
            tokenId,
            "Token buyback"
        );
    }

    function refreshBuybackReserve(uint256 startIndex, uint256 endIndex)
        external
        onlyOwner
    {
        require(endIndex <= tokenIdCounter, "End index is out of range");

        uint256 totalDeduction = 0;

        for (uint256 i = startIndex; i < endIndex; i++) {
            TokenInfo storage tokenInfo = tokenInfos[i];

            uint256 mintPrice = tokenInfo.mintPrice;
            if (
                block.timestamp - tokenInfo.mintTimestamp >= 365 days &&
                mintPrice > 0
            ) {
                uint256 buybackAmount = mintPrice / 2;
                totalDeduction += buybackAmount;
            }
        }

        buybackReserve -= totalDeduction;
    }

    function getAllUserTokens(address user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(user);
        uint256[] memory userTokens = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            userTokens[i] = tokenOfOwnerByIndex(user, i);
        }

        return userTokens;
    }

    function setSaleState(SaleState state) external onlyOwner {
        saleState = state;
    }

    function withdraw() external onlyOwner {
        uint256 withdrawableAmount = address(this).balance - buybackReserve;
        payable(OwnableUpgradeable.owner()).transfer(withdrawableAmount);
    }

    function mintReservedTokens(Tier tier, uint256 amount) external onlyOwner {
        TierData storage tierDataRef = tierData[tier];
        require(
            tierDataRef.reservedTokensRemaining >= amount,
            "Not enough reserved tokens left"
        );

        uint256 newTokenId = tokenIdCounter;
        tokenIdCounter += amount;

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(OwnableUpgradeable.owner(), newTokenId + i);
            tokenInfos[newTokenId + i] = TokenInfo({
                tier: uint256(tier),
                mintTimestamp: block.timestamp,
                mintPrice: 0,
                tokenTierIndex: tierDataRef.tokenSupply + i
            });
        }
        tierDataRef.tokenSupply += amount;
        tierDataRef.reservedTokensRemaining -= amount;
    }

    function setUsdPriceFeed(address feedAddress) external onlyOwner {
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    function setUsdPrice(Tier tier, uint256 usdPrice) external onlyOwner {
        require(tier <= Tier.GOLD, "Unknown tier");
        require(usdPrice > 0, "Can't set price to 0");

        tierData[tier].tokenUsdPrice = usdPrice;
    }

    function calculateNFTPriceInWei(Tier tier) public view returns (uint256) {
        require(tier <= Tier.GOLD, "Unknown tier");

        (, int256 gweiUsdPrice, , , ) = priceFeed.latestRoundData();
        uint256 nftPriceInWei = (tierData[tier].tokenUsdPrice * 1e26) /
            uint256(gweiUsdPrice);
        return nftPriceInWei;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._increaseBalance(account, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}
