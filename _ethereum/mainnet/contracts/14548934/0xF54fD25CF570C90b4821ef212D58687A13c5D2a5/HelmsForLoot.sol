// SPDX-License-Identifier: CC0-1.0
/// @title The Helms (for Loot) ERC-1155 token

//   _    _      _                  ____             _                 _ __
//  | |  | |    | |                / / _|           | |               | |\ \
//  | |__| | ___| |_ __ ___  ___  | | |_ ___  _ __  | |     ___   ___ | |_| |
//  |  __  |/ _ \ | '_ ` _ \/ __| | |  _/ _ \| '__| | |    / _ \ / _ \| __| |
//  | |  | |  __/ | | | | | \__ \ | | || (_) | |    | |___| (_) | (_) | |_| |
//  |_|  |_|\___|_|_| |_| |_|___/ | |_| \___/|_|    |______\___/ \___/ \__| |
//                                 \_\                                   /_/

/* Helms (for Loot) is a 3D visualisation of the Helms of Loot */

import "./Ownable.sol";
import "./ERC1155.sol";
import "./LootInterfaces.sol";
import "./HelmsMetadata.sol";

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

contract HelmsForLoot is ERC1155, IERC2981, Ownable {
    // Code inspired by Rings (for Loot):
    // https://github.com/w1nt3r-eth/rings-for-loot/blob/main/contracts/RingsForLoot.sol

    string public PROVENANCE = "";

    enum SaleState {
        Paused,
        Phase1, // Common helms available
        Phase2, // Epic and legendary helms available
        Phase3 // Mythic helms available
    }
    SaleState public state = SaleState.Paused;
    bool public lootOnly = true;

    // The Lootmart contract is used to calculate the token ID,
    // guaranteeing the correct supply for each helm
    ILoot private ogLootContract;
    ILmart private lmartContract;
    IRiftData private riftDataContract;
    IHelmsMetadata public metadataContract;

    // Loot-compatible contracts that we support. Users can claim a matching
    // helm if they own a token in this contract and `getHead` matches helm's name
    mapping(ILoot => bool) private lootContracts;

    // We only allow claiming one matching helm per bag. This data structure
    // holds the contract/bag ids that were already claimed
    mapping(ILoot => mapping(uint256 => bool)) public lootClaimed;
    // This data structure keeps track of the Loot bags that were minted to
    // ensure the correct max supply of each helm
    mapping(uint256 => bool) public lootMinted;

    string public name = "Helms for Loot";
    string public symbol = "H4L";

    // Flag to enable/disable Wyvern Proxy approval for gas-free Opensea listings
    bool private wyvernProxyWhitelist = true;

    // Common and Epic helms can be identified by calculating their greatness, but
    // to determine whether a helm is legendary or mythic, we use a list of ids
    // Legendary helm ids are stored as a tightly packed arrays of uint16
    bytes[5] private under19legendaryIds;
    bytes[5] private over19legendaryIds;

    // Pricing
    uint256 public lootOwnerPriceCommon = 0.02 ether;
    uint256 public publicPriceCommon = 0.05 ether;

    uint256 public lootOwnerPriceEpic = 0.04 ether;
    uint256 public publicPriceEpic = 0.07 ether;

    uint256 public lootOwnerPriceLegendary = 0.06 ether;
    uint256 public publicPriceLegendary = 0.09 ether;

    uint256 public lootOwnerPriceMythic = 0.08 ether;
    uint256 public publicPriceMythic = 0.11 ether;

    event Minted(uint256 lootId);
    event Claimed(uint256 lootId);

    constructor(
        ILoot[] memory lootsList,
        ILmart lmart,
        IRiftData riftData
    ) ERC1155("") {
        for (uint256 i = 0; i < lootsList.length; i++) {
            if (i == 0) {
                ogLootContract = lootsList[i];
            }
            lootContracts[lootsList[i]] = true;
        }
        lmartContract = lmart;
        riftDataContract = riftData;

        // List of legendary helm ids with less than 19 greatness
        // and over 19 greatness to help with rarity determination
        under19legendaryIds[1] = hex"01131028039119120f7b14d2";
        under19legendaryIds[2] = hex"0200109b0f441b04";
        under19legendaryIds[4] = hex"01400eea06fa1c29088616e60f7c12b5";
        over19legendaryIds[1] = hex"00fd148101ee0c02030a0809037013d91d501d88";
        over19legendaryIds[2] = hex"064d0a68094114340b611e45";
        over19legendaryIds[4] = hex"01a81d870b141087";
    }

    /**
     * @dev Accepts a Loot bag ID and returns the rarity level of the helm contained within that bag.
     * Rarity levels (based on the number of times each helm appears in the set of 8000 Loot bags):
     * 1 - Common Helm (>19)
     * 2 - Epic Helm (<19)
     * 3 - Legendary Helm (2)
     * 4 - Mythic Helm (1)
     */
    function helmRarity(uint256 lootId) public view returns (uint256) {
        // We use a combination of the greatness calculation from the loot contract
        // and precomputed lists of legendary and mythic helm IDs
        // to determine the helm rarity.
        uint256 rand = uint256(
            keccak256(abi.encodePacked("HEAD", Strings.toString(lootId)))
        );
        uint256 greatness = rand % 21;
        uint256 kind = rand % 15;

        // Other head armor not supported by this contract
        require(kind < 6, "HelmsForLoot: no helm in bag");

        if (greatness <= 14) {
            return (1); // Comon Helm
        } else if (greatness < 19) {
            // Check if it is in the legendary list
            if (findHelmIndex(under19legendaryIds[kind], lootId)) {
                return (3); // Legendary Helm
            }
            // Else two possible mythic helms with less than 19 greatness:
            else if (lootId == 2304 || lootId == 4557) {
                return (4); // Mythic Helm
            } else {
                return (2); // Epic Helm
            }
        } else {
            if (findHelmIndex(over19legendaryIds[kind], lootId)) {
                return (3); // Legendary helm
            } else {
                return (4); // Mythic Helm
            }
        }
    }

    /**
     * @dev Accepts an array of Loot bag IDs and mints the corresponding Helm tokens.
     */
    function purchasePublic(uint256[] memory lootIds) public payable {
        require(!lootOnly, "HelmsForLoot: Loot-only minting period is active");

        require(lootIds.length > 0, "HelmsForLoot: buy at least one");
        require(lootIds.length <= 26, "HelmsForLoot: too many at once");

        uint256[] memory tokenIds = new uint256[](lootIds.length);
        uint256 price = 0;

        for (uint256 i = 0; i < lootIds.length; i++) {
            require(!lootMinted[lootIds[i]], "HelmsForLoot: already claimed");
            // Reserve Loot IDs 7778 to 8000 for ownerClaim
            require(
                lootIds[i] > 0 && lootIds[i] < 7778,
                "HelmsForLoot: invalid Loot ID"
            );

            uint256 rarity = helmRarity(lootIds[i]);

            if (rarity == 1) {
                require(
                    state == SaleState.Phase1 ||
                        state == SaleState.Phase2 ||
                        state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceCommon;
            } else if (rarity == 2) {
                require(
                    state == SaleState.Phase2 || state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceEpic;
            } else if (rarity == 3) {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceLegendary;
            } else {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += publicPriceMythic;
            }

            lootMinted[lootIds[i]] = true;
            tokenIds[i] = lmartContract.headId(lootIds[i]);
        }

        require(msg.value == price, "HelmsForLoot: wrong price");

        // We're using a loop with _mint rather than _mintBatch
        // as currently some centralised tools like Opensea
        // have issues understanding the `TransferBatch` event
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(msg.sender, tokenIds[i], 1, "");
            emit Minted(lootIds[i]);
        }
    }

    /**
     * @dev Allows the owner of a Loot, More Loot, or Genesis Adventurer
     * NFT to claim the Helm from a Loot bag that matches the Helm in
     * their bag. The address of the contract (Loot, More Loot, or GA)
     * needs to be provided, together with claimIds array containing
     * the IDs of the bags to be used for the claim, together with a
     * corresponding lootIds array that contains the IDs of the Loot Bags
     * with matching helms to be claimed. If claimRiftXP is set to true,
     * each bag in the claimIds array will gain 200 XP on The Rift.
     */
    function purchaseMatching(
        ILoot claimLoot,
        uint256[] memory claimIds,
        uint256[] memory lootIds,
        bool claimRiftXP
    ) public payable {
        require(
            state == SaleState.Phase1 ||
                state == SaleState.Phase2 ||
                state == SaleState.Phase3,
            "HelmsForLoot: sale not active"
        );

        require(lootContracts[claimLoot], "HelmsForLoot: not compatible");

        if (lootOnly == true) {
            require(
                claimLoot == ogLootContract,
                "HelmsForLoot: loot-only minting period is active."
            );
        }

        require(lootIds.length > 0, "HelmsForLoot: buy at least one");
        require(lootIds.length <= 26, "HelmsForLoot: too many at once");

        uint256[] memory tokenIds = new uint256[](lootIds.length);
        uint256 price = 0;

        for (uint256 i = 0; i < lootIds.length; i++) {
            // Reserve Loot IDs 7778 to 8000 for ownerClaim
            require(
                (lootIds[i] > 0 && lootIds[i] < 7778),
                "HelmsForLoot: invalid Loot ID"
            );

            require(
                claimLoot.ownerOf(claimIds[i]) == msg.sender,
                "HelmsForLoot: not owner"
            );

            require(
                keccak256(abi.encodePacked(claimLoot.getHead(claimIds[i]))) ==
                    keccak256(
                        abi.encodePacked(ogLootContract.getHead(lootIds[i]))
                    ),
                "HelmsForLoot: wrong helm"
            );

            // Both the original loot bag and matching bag
            // (loot/mloot/genesis adventurer) to be unclaimed
            require(
                !lootClaimed[claimLoot][claimIds[i]],
                "HelmsForLoot: bag already used for claim"
            );
            require(
                !lootMinted[lootIds[i]],
                "HelmsForLoot: loot bag already minted"
            );

            uint256 rarity = helmRarity(lootIds[i]);

            if (rarity == 1) {
                require(
                    state == SaleState.Phase1 ||
                        state == SaleState.Phase2 ||
                        state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceCommon;
            } else if (rarity == 2) {
                require(
                    state == SaleState.Phase2 || state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceEpic;
            } else if (rarity == 3) {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceLegendary;
            } else {
                require(
                    state == SaleState.Phase3,
                    "HelmsForLoot: sale not active"
                );
                price += lootOwnerPriceMythic;
            }
            lootMinted[lootIds[i]] = true;
            lootClaimed[claimLoot][claimIds[i]] = true;
            tokenIds[i] = lmartContract.headId(lootIds[i]);
        }
        require(msg.value == price, "HelmsForLoot: wrong price");

        // We're using a loop with _mint rather than _mintBatch
        // as currently some centralised tools like Opensea
        // have issues understanding the `TransferBatch` event
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 riftId;
            // Add XP via The Rift
            if (claimRiftXP == true) {
                // Adjust ID for gLoot:
                if (claimLoot != ogLootContract && claimIds[i] < 8001) {
                    riftId = claimIds[i] + 9997460;
                } else {
                    riftId = claimIds[i];
                }
                riftDataContract.addXP(200, riftId);
            }
            _mint(msg.sender, tokenIds[i], 1, "");
            emit Claimed(lootIds[i]);
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(
            address(metadataContract) != address(0),
            "HelmsForLoot: no metadata address"
        );
        return metadataContract.uri(tokenId);
    }

    /**
     * @dev Run a batch query to check if a set of loot, mloot or gloot IDs have been used for a claim.
     */
    function lootClaimedBatched(ILoot loot, uint256[] calldata ids)
        public
        view
        returns (bool[] memory claimed)
    {
        claimed = new bool[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            claimed[i] = lootClaimed[loot][ids[i]];
        }
    }

    /**
     * @dev Run a batch query to check if a set of loot bags have already been claimed.
     */
    function lootMintedBatched(uint256[] calldata ids)
        public
        view
        returns (bool[] memory minted)
    {
        minted = new bool[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            minted[i] = lootMinted[ids[i]];
        }
    }

    /**
     * @dev Utlity function to check a tightly packed array of uint16 for a given id.
     */
    function findHelmIndex(bytes storage data, uint256 helmId)
        internal
        view
        returns (bool found)
    {
        for (uint256 i = 0; i < data.length / 2; i++) {
            if (
                uint8(data[i * 2]) == ((helmId >> 8) & 0xFF) &&
                uint8(data[i * 2 + 1]) == (helmId & 0xFF)
            ) {
                return true;
            }
        }
        return false;
    }

    // Interfaces

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = owner();
        royaltyAmount = (salePrice * 5) / 100;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Allow easier listing for sale on OpenSea. Based on
        // https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/migrations/2_deploy_contracts.js#L29
        if (wyvernProxyWhitelist == true) {
            if (block.chainid == 4) {
                if (
                    ProxyRegistry(0xF57B2c51dED3A29e6891aba85459d600256Cf317)
                        .proxies(owner) == operator
                ) {
                    return true;
                }
            } else if (block.chainid == 1) {
                if (
                    ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1)
                        .proxies(owner) == operator
                ) {
                    return true;
                }
            }
        }

        return ERC1155.isApprovedForAll(owner, operator);
    }

    // Admin
    function setProvenance(string calldata prov) public onlyOwner {
        PROVENANCE = prov;
    }

    function setState(SaleState newState, bool newlootOnly) public onlyOwner {
        state = newState;
        lootOnly = newlootOnly;
    }

    function setMetadataContract(IHelmsMetadata addr) public onlyOwner {
        metadataContract = addr;
    }

    function setWyvernProxyWhitelist(bool enabled) public onlyOwner {
        wyvernProxyWhitelist = enabled;
    }

    /**
     * @dev Allows the owner to mint a set of helms for promotional purposes and to reward contributors.
     * Loot IDs 7778->8000
     */
    function ownerClaim(uint256[] memory lootIds, address to)
        public
        payable
        onlyOwner
    {
        // We're using a loop with _mint rather than _mintBatch
        // as currently some centralised tools like Opensea
        // have issues understanding the `TransferBatch` event
        for (uint256 i = 0; i < lootIds.length; i++) {
            require(lootIds[i] > 7777 && lootIds[i] < 8001, "Token ID invalid");
            lootMinted[lootIds[i]] = true;
            uint256 tokenId = lmartContract.headId(lootIds[i]);
            _mint(to, tokenId, 1, "");
            emit Minted(lootIds[i]);
        }
    }

    /**
     * Given an erc721 bag, returns the erc1155 token ids of the helm in the bag
     * We use LootMart's bijective encoding function.
     */
    function id(uint256 lootId) public view returns (uint256 headId) {
        return lmartContract.headId(lootId);
    }

    function setPricesCommon(uint256 newlootOwnerPrice, uint256 newPublicPrice)
        public
        onlyOwner
    {
        lootOwnerPriceCommon = newlootOwnerPrice;
        publicPriceCommon = newPublicPrice;
    }

    function setPricesEpic(uint256 newlootOwnerPrice, uint256 newPublicPrice)
        public
        onlyOwner
    {
        lootOwnerPriceEpic = newlootOwnerPrice;
        publicPriceEpic = newPublicPrice;
    }

    function setPricesLegendary(
        uint256 newlootOwnerPrice,
        uint256 newPublicPrice
    ) public onlyOwner {
        lootOwnerPriceLegendary = newlootOwnerPrice;
        publicPriceLegendary = newPublicPrice;
    }

    function setPricesMythic(uint256 newlootOwnerPrice, uint256 newPublicPrice)
        public
        onlyOwner
    {
        lootOwnerPriceMythic = newlootOwnerPrice;
        publicPriceMythic = newPublicPrice;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAllERC20(IERC20 erc20Token) public onlyOwner {
        require(
            erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)))
        );
    }
}
