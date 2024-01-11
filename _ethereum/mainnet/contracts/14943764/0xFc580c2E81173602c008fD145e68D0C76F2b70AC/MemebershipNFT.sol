//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol"; // Helper functions OpenZeppelin provides.
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// Helper we wrote to encode in Base64
import "./Base64.sol";
import "./IMembershipNFT.sol";
//import "./console.sol";

// Hardhat util for console output
//import "./console.sol";

contract MembershipNFT is ERC721A, IMembershipNFT, Ownable {
    struct TierAttributes {
        uint256 index;
        uint256 startId;
        uint256 endId;
        uint256 count;
        string name;
        string class;
        string image; // image
        string ext_url; // external_url
        string ani_url; // animation_url
    }
    struct GameProp {
        uint256 token_transaction;
        uint256 game_play;
    }

    using Strings for uint256;

    // Tier struct array.
    TierAttributes[] public defaultTiers;
    // A modifier to lock/unlock token transfer
    bool public locked;
    address nftPoolAddress;
    mapping(uint256 => GameProp) internal _gameProps;

    constructor(
        string[] memory tierNames,
        string[] memory tierClasses,
        string[] memory imageURIs,
        uint256[] memory counts
    ) ERC721A("Genesis Owner Key", "OWNK") {
        for (uint256 i = 0; i < tierNames.length; i++) {
            defaultTiers.push(
                TierAttributes({
                    index: i,
                    startId: 0,
                    endId: 0,
                    name: tierNames[i],
                    class: tierClasses[i],
                    image: imageURIs[i],
                    count: counts[i],
                    ext_url: "",
                    ani_url: ""
                })
            );

            //TierAttributes memory c = defaultTiers[i];
            // console.log(
            //     "\nInitializing Tier\nName: %s\nType: %s",
            //     c.name,
            //     c.class
            // );
        }
    }

    modifier notLocked() {
        require(!locked, "MembershipNFT: can't operate - currently locked");
        _;
    }

    // ---------------------------------------
    // -          External Functions         -
    // ---------------------------------------
    function setupPool(address nftpool) external onlyOwner {
        require(nftpool != address(0), "MembershipNFT: ZERO_ADDRESS");
        nftPoolAddress = nftpool;
        emit SetupPool(msg.sender, nftpool);
    }

    function toggleLock() external onlyOwner {
        locked = !locked;
        emit Locked(msg.sender, locked);
    }

    function mint(
        address to,
        uint256 quantity,
        uint8 tierIndex
    ) public onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(
            defaultTiers.length > tierIndex,
            "MembershipNFT: The tier index is overflow"
        );
        require(
            defaultTiers[tierIndex].count == tierSupply(tierIndex) + quantity,
            "MembershipNFT: The tier qunatity doesn't match"
        );
        uint256 currentIdx = _currentIndex;
        uint256 startId = currentIdx;
        _safeMint(to, quantity);
        currentIdx = _currentIndex;
        defaultTiers[tierIndex].startId = startId;
        defaultTiers[tierIndex].endId = currentIdx > 0 ? currentIdx - 1 : 0;

        emit Mint(_msgSender(), to, quantity, tierIndex);
    }

    // Batch minting to all tiers for gas optimization
    function mintToPool() external onlyOwner {
        require(
            nftPoolAddress != address(0),
            "MembershipNFT: POOL_ZERO_ADDRESS"
        );
        require(defaultTiers.length > 0, "MembershipNFT: NOT_INITIALIZED");
        TierAttributes[] memory tmpTiers = defaultTiers;
        uint256 tSupply = 0;

        for (uint8 i = 0; i < tmpTiers.length; i++) {
            tSupply += tmpTiers[i].count;
            defaultTiers[i].startId = i > 0 ? defaultTiers[i - 1].endId + 1 : 0;
            defaultTiers[i].endId = i > 0
                ? defaultTiers[i - 1].endId + tmpTiers[i].count
                : tmpTiers[i].count - 1;
            //console.log("Tier %s : startID=%s  endID=%s", i,  defaultTiers[i].startId, defaultTiers[i].endId);
        }
        _safeMint(nftPoolAddress, tSupply);
        //console.log("Total Supply: ", tSupply);
        emit MintToPool(msg.sender);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId, true);
        emit Burn(_msgSender(), tokenId);
    }

    function setImage(string[] memory urls) external onlyOwner {
        require(
            urls.length == defaultTiers.length,
            "MembershipNFT: The length is not equal"
        );

        for (uint256 i = 0; i < urls.length; i++) {
            defaultTiers[i].image = urls[i];
        }

        emit UpdateMetadataImage(urls);
    }

    function setAnimationUrls(string[] memory urls) external onlyOwner {
        require(
            urls.length == defaultTiers.length,
            "MembershipNFT: The length is not equal"
        );

        for (uint256 i = 0; i < urls.length; i++) {
            defaultTiers[i].ani_url = urls[i];
        }

        emit UpdateMetadataAnimationUrl(urls);
    }

    function setExternalUrls(string[] memory urls) external onlyOwner {
        require(
            urls.length == defaultTiers.length,
            "MembershipNFT: The length is not equal"
        );

        for (uint256 i = 0; i < urls.length; i++) {
            defaultTiers[i].ext_url = urls[i];
        }

        emit UpdateMetadataExternalUrl(urls);
    }

    function setGameProp(
        uint256 tokenId,
        uint256 gameplay,
        uint256 tokentransaction
    ) external onlyOwner {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        _gameProps[tokenId].game_play = gameplay;
        _gameProps[tokenId].token_transaction = tokentransaction;
    }

    // ---------------------------------------
    // -          Public Functions           -
    // ---------------------------------------
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        // string memory baseURI = _baseURI();
        // return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
        GameProp memory gp = _gameProps[tokenId];

        TierAttributes memory tierAttributes;
        TierAttributes[] memory tiers = defaultTiers;
        uint256 startPos = 0;
        uint256 endPos = 0;
        for (uint256 i = 0; i < tiers.length; i++) {
            if (tiers[i].count == 0) continue;
            startPos = tiers[i].startId;
            endPos = tiers[i].endId;
            if (tokenId >= startPos && tokenId <= endPos) {
                tierAttributes = tiers[i];
                break;
            }
        }
        string memory s1 = string(
            abi.encodePacked(
                '{"name": "',
                name(),
                " #",
                Strings.toString(tokenId),
                '", "image": "',
                tierAttributes.image,
                '", "external_url": "',
                tierAttributes.ext_url,
                '", "animation_url": "',
                tierAttributes.ani_url
            )
        );
        string memory s2 = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        s1,
                        '", "description": "PlayEstates Founding Member Token"',
                        ', "attributes": [',
                        ' { "trait_type": "Tier", "value": "',
                        tierAttributes.class,
                        '"},',
                        '{ "display_type": "number", "trait_type": "Game Play", "value": ',
                        Strings.toString(gp.game_play),
                        "},",
                        '{ "display_type": "number", "trait_type": "Token Transaction", "value": ',
                        Strings.toString(gp.token_transaction),
                        "}",
                        "]}"
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", s2)
        );
        return output;
    }

    function getAllDefaultTiers()
        public
        view
        returns (TierAttributes[] memory)
    {
        return defaultTiers;
    }

    function gamePlayOf(uint256 tokenId) public view returns (uint256) {
        return _gamePropOf(tokenId).game_play;
    }

    function tokenTransactionOf(uint256 tokenId) public view returns (uint256) {
        return _gamePropOf(tokenId).token_transaction;
    }

    // ---------------------------------------
    // -          Internal Functions         -
    // ---------------------------------------
    function _gamePropOf(uint256 tokenId)
        internal
        view
        returns (GameProp memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        GameProp memory gameprop = _gameProps[tokenId];
        return gameprop;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function _beforeTokenTransfers(
        address, /* from */
        address, /* to */
        uint256, /* startTokenId */
        uint256 /* quantity */
    ) internal virtual override {
        require(!locked, "MembershipNFT: can't operate - currently locked");
    }

    // ---------------------------------------
    // -          Private Functions          -
    // ---------------------------------------
    // ---------------------------------------
    // -     Interface Implementation        -
    // ---------------------------------------
    modifier checkTier(uint8 tierIndex) {
        require(
            tierIndex < defaultTiers.length,
            "MembershipNFT: tier overflow"
        );
        _;
    }

    function tierSupply(uint8 tierIndex)
        public
        view
        override
        checkTier(tierIndex)
        returns (uint256)
    {
        if (_currentIndex == 0) return 0;
        unchecked {
            TierAttributes memory tierAttr = defaultTiers[tierIndex];
            if (tierIndex > 0 && tierAttr.endId == 0) return 0;
            return tierAttr.endId - tierAttr.startId + 1;
        }
    }

    function tierName(uint8 tierIndex)
        public
        view
        override
        checkTier(tierIndex)
        returns (string memory)
    {
        unchecked {
            TierAttributes memory tierAttr = defaultTiers[tierIndex];
            return tierAttr.name;
        }
    }

    function tierCount(uint8 tierIndex)
        public
        view
        override
        checkTier(tierIndex)
        returns (uint256)
    {
        unchecked {
            TierAttributes memory tierAttr = defaultTiers[tierIndex];
            return tierAttr.count;
        }
    }

    function numberTiers() public view override returns (uint256) {
        return defaultTiers.length;
    }

    function tierStartId(uint8 tierIndex)
        public
        view
        override
        checkTier(tierIndex)
        returns (uint256)
    {
        unchecked {
            TierAttributes memory tierAttr = defaultTiers[tierIndex];
            return tierAttr.startId;
        }
    }

    function tierEndId(uint8 tierIndex)
        public
        view
        override
        checkTier(tierIndex)
        returns (uint256)
    {
        unchecked {
            TierAttributes memory tierAttr = defaultTiers[tierIndex];
            return tierAttr.endId;
        }
    }
}
