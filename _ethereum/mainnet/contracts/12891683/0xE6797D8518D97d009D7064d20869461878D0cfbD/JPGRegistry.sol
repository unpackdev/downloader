// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./OwnableUpgradeable.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./SignedMessage.sol";
import "./Helpers.sol";

contract JPGRegistry is OwnableUpgradeable, SignedMessage, Helpers {
    using SafeCast for uint256;

    event CuratorAdded(address indexed curator);
    event CreateSubRegistry(address indexed curator, bytes32 name, string description);
    event UpdateSubRegistry(address indexed curator, bytes32 name, string description);
    event RemoveSubRegistry(address indexed curator, bytes32 name);
    event ReinstateSubRegistry(address indexed curator, bytes32 name);

    event TokensListed(OwnerBundle[] bundles);

    event AddNFTToSubRegistry(address indexed curator, bytes32 name, CuratedNFT token);
    event RemoveNFTFromSubRegistry(address indexed curator, bytes32 name, NFT token);

    event TokenListedForSale(NFT token, uint256 price, address curator, address owner);
    event TokenSold(NFT token, uint256 price, address buyer, address seller, address curator);

    // Maximum percentage fee, with 2 decimal points beyond 1%
    uint16 internal constant MAX_FEE_PERC = 10000;
    uint16 internal constant CURATOR_TAKE_PER_10000 = 500;

    bool private _initialized;
    bool private _initializing;

    struct NFT {
        address tokenContract;
        uint256 tokenId;
    }

    struct CuratedNFT {
        address tokenContract;
        uint256 tokenId;
        string note;
    }

    struct Listing {
        bytes signedMessage;
        NFT nft;
    }

    struct OwnerBundle {
        address owner;
        Listing[] listings;
    }

    struct ListingPrice {
        uint256 artistTake;
        uint256 curatorTake;
        uint256 sellerTake;
        uint256 sellPrice;
    }

    struct SubRegistry {
        bool created;
        bool removed;
        string description;
        mapping(address => mapping(uint256 => NFTData)) nfts;
    }

    struct NFTData {
        bool active;
        string note;
    }

    struct SubRegistries {
        uint16 feePercentage;
        bytes32[] registryNames;
        mapping(bytes32 => SubRegistry) subRegistry;
        mapping(address => mapping(uint256 => NFTData)) nfts;
    }

    // We use uint96, since we only support ETH, which 2**96 = 79228162514264337593543950336,
    // which is 79228162514.26434 ETH, which is a ridiculous amount of dollar value
    // this lets us squeeze this into a single slot
    struct InternalPrice {
        address curator;
        uint96 sellerTake;
    }

    mapping(address => bool) public curators;
    mapping(address => mapping(uint256 => bool)) public mainRegistry;
    mapping(address => SubRegistries) internal subRegistries;
    mapping(address => mapping(address => mapping(uint256 => InternalPrice))) internal priceList;
    mapping(address => uint256) public balances;

    function initialize() public {
        {
            bool either = _initializing || !_initialized;
            require(either, "contract initialized");
        }

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        curators[msg.sender] = true;
        subRegistries[msg.sender].feePercentage = CURATOR_TAKE_PER_10000;
        OwnableUpgradeable.__Ownable_init();

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @notice Public method to list non-fungible token(s) on the main registry
     * @dev permissionless listing from dApp - array of tokens (can be one). Will
     * ensure token is owned by caller.
     * @param tokens An array of NFT struct instances
     */
    function bulkAddToMainRegistry(NFT[] calldata tokens) public {
        NFT[] memory listedTokens = new NFT[](tokens.length);
        Listing[] memory bundleListings = new Listing[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            mainRegistry[tokens[i].tokenContract][tokens[i].tokenId] = true;
            listedTokens[i] = tokens[i];
            bundleListings[i] = Listing({signedMessage: bytes("0"), nft: tokens[i]});
        }

        OwnerBundle[] memory bundle = new OwnerBundle[](1);
        bundle[0] = OwnerBundle({listings: bundleListings, owner: address(msg.sender)});
        emit TokensListed(bundle);
    }

    /**
     * @notice Called by token owner to allow JPG Registry to sell an NFT on their behalf
     * in a fixed price sale with minimum price
     * @param token An instance of an NFT struct
     * @param price The minimum price the seller will acccept
     * @param curator Address of curator
     */
    function listForSale(
        NFT calldata token,
        uint96 price,
        address curator
    ) public {
        require(price > 0, "JPGR:lFS:Price cannot be 0");
        require(mainRegistry[token.tokenContract][token.tokenId], "JPGR:lFS:Token not registered");

        require(ERC721(token.tokenContract).ownerOf(token.tokenId) == msg.sender, "JPGR:lFS:Not token owner");

        priceList[msg.sender][token.tokenContract][token.tokenId] = InternalPrice({
            sellerTake: price,
            curator: curator
        });

        emit TokenListedForSale(token, price, curator, msg.sender);
    }

    /**
     * @notice Called by token owner to allow JPG Registry to sell an NFT on their behalf
     * in a fixed price sale with minimum price
     * @param tokens Array of NFT structs
     * @param prices Array of minimum prices the seller will acccept for corresponding tokens
     * @param curator Address of curator
     */
    function bulkListForSale(
        NFT[] calldata tokens,
        uint96[] calldata prices,
        address curator
    ) public {
        require(tokens.length == prices.length, "JPGR:bLFS:Invalid prices array length");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(prices[i] > 0, "JPGR:bLFS:Price cannot be 0");
            require(mainRegistry[tokens[i].tokenContract][tokens[i].tokenId], "JPGR:bLFS:Token not registered");
            require(
                ERC721(tokens[i].tokenContract).ownerOf(tokens[i].tokenId) == msg.sender,
                "JPGR:bLFS:Not token owner"
            );

            priceList[msg.sender][tokens[i].tokenContract][tokens[i].tokenId] = InternalPrice({
                sellerTake: prices[i],
                curator: curator
            });

            emit TokenListedForSale(tokens[i], prices[i], curator, msg.sender);
        }
    }

    /**
     * @notice Get price of a specific token
     * @param subRegistryName Name of the subregistry the token is hosted on
     * @param token An instance of an NFT struct
     * @param curator Address of curator
     * @param owner Owner of the NFT
     */
    function getPrice(
        bytes32 subRegistryName,
        NFT calldata token,
        address curator,
        address owner
    ) public view returns (ListingPrice memory) {
        require(mainRegistry[token.tokenContract][token.tokenId], "JPGR:gp:Token not registered");
        require(inSubRegistry(subRegistryName, token, curator), "JPGR:gp:Token not curated by curator");

        InternalPrice memory priceInternal = priceList[owner][token.tokenContract][token.tokenId];
        require(
            priceInternal.curator != address(0) && priceInternal.curator == curator,
            "JPGR:gp:Curator not approved seller"
        );

        uint256 sellerTake = priceInternal.sellerTake;

        require(sellerTake > 0, "JPGR:bfp:Owner price 0");

        uint256 curatorTake = calculateCuratorTake(sellerTake, curator);
        // Hardcoded artist take to JPG multisig
        uint256 artistTake = sellerTake / 10;
        uint256 totalPrice = sellerTake + curatorTake + artistTake;

        // TODO: artist royalties
        return
            ListingPrice({
                curatorTake: curatorTake,
                sellerTake: sellerTake,
                artistTake: artistTake,
                sellPrice: totalPrice
            });
    }

    /**
     * @notice Called publicly to purchase an NFT that has been approved for fixed price sale
     * @param subRegistryName Name of the subregistry the token is hosted on
     * @param token An instance of an NFT struct
     * @param curator Address of curator
     * @param owner Owner of the NFT
     */
    function buyFixedPrice(
        bytes32 subRegistryName,
        NFT calldata token,
        address curator,
        address owner
    ) public payable {
        ListingPrice memory price = getPrice(subRegistryName, token, curator, owner);
        require(msg.value == price.sellPrice, "JPGR:bfp:Price too low");

        address jpgOwner = this.owner();

        balances[owner] += price.sellerTake;
        balances[curator] += price.curatorTake;
        // Contract owner temporarily set as royalties recipient
        balances[jpgOwner] += price.artistTake;
        delete priceList[owner][token.tokenContract][token.tokenId];

        ERC721(token.tokenContract).transferFrom(owner, msg.sender, token.tokenId);

        emit TokenSold(token, price.sellPrice, msg.sender, owner, curator);
    }

    /**
     * @notice Called publicly to withdraw balance for message sender
     */
    function withdrawBalance() public {
        uint256 balance = balances[msg.sender];
        if (balance > 0) {
            balances[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: balance}("");
            require(success, "JPGR:wb:Transfer failed");
        }
    }

    /**
     * @notice Called internally to determine payout for a fixed price sale
     * @param price The current owner of a Token
     * @param curator Curator whose exhibit the token was purchased throuh, can be null address
     */
    function calculateCuratorTake(uint256 price, address curator) internal view returns (uint256) {
        return (price * subRegistries[curator].feePercentage) / MAX_FEE_PERC;
    }

    /**
     * @notice Called publicly by token owner to remove from ProtocolRegistry
     * @param listing An instance of a Listing struct
     */
    function removeFromMainRegistry(Listing calldata listing) public {
        try ERC721(listing.nft.tokenContract).ownerOf(listing.nft.tokenId) returns (address owner) {
            if (owner == msg.sender) {
                _removeFromMainRegistry(NFT({tokenContract: listing.nft.tokenContract, tokenId: listing.nft.tokenId}));
            }
        } catch {} // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Create subregistry and add array of tokens
     * @param subRegistryName The name of the subregistry
     * @param subRegistryDescription The description of the subregistry
     * @param tokens Array of NFTs
     * @param notes Array of notes corresponding to NFTs
     */
    function createSubregistry(
        bytes32 subRegistryName,
        string calldata subRegistryDescription,
        NFT[] calldata tokens,
        string[] calldata notes
    ) public {
        require(curators[msg.sender], "JPGR:ats:Only allowed curators");
        require(!subRegistries[msg.sender].subRegistry[subRegistryName].created, "JPGR:ats:Subregistry exists");

        subRegistries[msg.sender].subRegistry[subRegistryName].created = true;
        subRegistries[msg.sender].registryNames.push(subRegistryName);
        subRegistries[msg.sender].subRegistry[subRegistryName].description = subRegistryDescription;
        emit CreateSubRegistry(msg.sender, subRegistryName, subRegistryDescription);

        for (uint256 i = 0; i < tokens.length; i++) {
            mainRegistry[tokens[i].tokenContract][tokens[i].tokenId] = true;
            subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokens[i].tokenContract][tokens[i].tokenId]
                .note = notes[i];
            subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokens[i].tokenContract][tokens[i].tokenId]
                .active = true;
            emit AddNFTToSubRegistry(
                msg.sender,
                subRegistryName,
                CuratedNFT({tokenContract: tokens[i].tokenContract, tokenId: tokens[i].tokenId, note: notes[i]})
            );
        }
    }

    /**
     * @notice Update existing subregistry
     * @param subRegistryName The name of the subregistry
     * @param subRegistryDescription The description of the subregistry
     * @param tokensToUpsert Array of NFTs to add/update
     * @param tokensToRemove Array of NFTs to remove
     * @param notes Array of notes corresponding to NFTs
     */
    function updateSubregistry(
        bytes32 subRegistryName,
        string calldata subRegistryDescription,
        NFT[] calldata tokensToUpsert,
        NFT[] calldata tokensToRemove,
        string[] calldata notes
    ) public {
        // Subregistry doesn't belong to msg.sender or hasn't been created
        require(subRegistries[msg.sender].subRegistry[subRegistryName].created, "JPGR:ats:Permission denied");
        require(tokensToUpsert.length == notes.length, "JPGR:ats:Mismatched array length");

        subRegistries[msg.sender].subRegistry[subRegistryName].description = subRegistryDescription;

        if (tokensToRemove.length > 0) {
            for (uint256 i = 0; i < tokensToRemove.length; i++) {
                delete subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokensToRemove[i].tokenContract][
                    tokensToRemove[i].tokenId
                ];
                emit RemoveNFTFromSubRegistry(msg.sender, subRegistryName, tokensToRemove[i]);
            }
        }

        if (tokensToUpsert.length > 0) {
            for (uint256 i = 0; i < tokensToUpsert.length; i++) {
                mainRegistry[tokensToUpsert[i].tokenContract][tokensToUpsert[i].tokenId] = true;

                subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokensToUpsert[i].tokenContract][
                    tokensToUpsert[i].tokenId
                ]
                    .note = notes[i];
                subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokensToUpsert[i].tokenContract][
                    tokensToUpsert[i].tokenId
                ]
                    .active = true;

                emit AddNFTToSubRegistry(
                    msg.sender,
                    subRegistryName,
                    CuratedNFT({
                        tokenContract: tokensToUpsert[i].tokenContract,
                        tokenId: tokensToUpsert[i].tokenId,
                        note: notes[i]
                    })
                );
            }
        }
        emit UpdateSubRegistry(msg.sender, subRegistryName, subRegistryDescription);
    }

    /**
     * @notice Add an array of tokens to a subregistry
     * @param subRegistryName The name of the subregistry
     * @param tokens Array of NFTs
     * @param notes Array of notes corresponding to NFTs
     */
    function addToSubregistry(
        bytes32 subRegistryName,
        NFT[] calldata tokens,
        string[] calldata notes
    ) public {
        // Subregistry doesn't belong to msg.sender or hasn't been created
        require(subRegistries[msg.sender].subRegistry[subRegistryName].created, "JPGR:ats:Permission denied");

        for (uint256 i = 0; i < tokens.length; i++) {
            mainRegistry[tokens[i].tokenContract][tokens[i].tokenId] = true;
            subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokens[i].tokenContract][tokens[i].tokenId]
                .active = true;
            subRegistries[msg.sender].subRegistry[subRegistryName].nfts[tokens[i].tokenContract][tokens[i].tokenId]
                .note = notes[i];
            emit AddNFTToSubRegistry(
                msg.sender,
                subRegistryName,
                CuratedNFT({tokenContract: tokens[i].tokenContract, tokenId: tokens[i].tokenId, note: notes[i]})
            );
        }
    }

    /**
     * @notice Remove a subregistry by tagging it as removed
     * @dev Due to `delete` operation not deleting a mapping, we just set a flag
     * @param subRegistryName The name of the subregistry
     */
    function removeSubRegistry(bytes32 subRegistryName) public {
        require(curators[msg.sender], "JPGR:ats:Only allowed curators");
        subRegistries[msg.sender].subRegistry[subRegistryName].removed = true;
        emit RemoveSubRegistry(msg.sender, subRegistryName);
    }

    /**
     * @notice Reinstates a subregistry that was removed
     * @dev We never actually delete a subregistry, so we can trivially reinstate one's status
     * @param subRegistryName The name of the subregistry
     */
    function reinstateSubRegistry(bytes32 subRegistryName) public {
        require(curators[msg.sender], "JPGR:ats:Only allowed curators");
        subRegistries[msg.sender].subRegistry[subRegistryName].removed = false;
        emit ReinstateSubRegistry(msg.sender, subRegistryName);
    }

    /**
     * @notice Get all subregistries of a curator
     * @param curator Address of the curator
     */
    function getSubRegistries(address curator) public view returns (string[] memory) {
        bytes32[] memory registryNames = subRegistries[curator].registryNames;
        // get non-removed registry length
        uint256 ctr;
        for (uint256 i = 0; i < registryNames.length; i++) {
            if (subRegistries[curator].subRegistry[registryNames[i]].removed) {
                continue;
            }
            ctr += 1;
        }
        // create new array of length non-removed
        string[] memory registryStrings = new string[](ctr);
        ctr = 0;
        for (uint256 i = 0; i < registryNames.length; i++) {
            // add to array if non-removed
            if (subRegistries[curator].subRegistry[registryNames[i]].removed) {
                continue;
            }
            registryStrings[ctr] = Helpers.bytes32ToString(registryNames[i]);
            ctr += 1;
        }
        return registryStrings;
    }

    /**
     * @notice Called by a curator to remove from their subregistry
     * @param subRegistryName name of the subregistry to remove it from
     * @param token An instance of an NFT struct
     */
    function removeFromSubregistry(bytes32 subRegistryName, NFT calldata token) public {
        require(curators[msg.sender], "JPGR:rfs:Only allowed curators");
        subRegistries[msg.sender].subRegistry[subRegistryName].nfts[token.tokenContract][token.tokenId].active = false;
        emit RemoveNFTFromSubRegistry(msg.sender, subRegistryName, token);
    }

    /**
     * @notice Called publicly to determine if NFT is in curator subregistry
     * @param nft An instance of an NFT struct
     * @param curator Address of a curator
     */
    function inSubRegistry(
        bytes32 subRegistryName,
        NFT calldata nft,
        address curator
    ) public view returns (bool) {
        return
            mainRegistry[nft.tokenContract][nft.tokenId] &&
            !subRegistries[curator].subRegistry[subRegistryName].removed &&
            subRegistries[curator].subRegistry[subRegistryName].nfts[nft.tokenContract][nft.tokenId].active;
    }

    /**
     * @notice Called by contract owner admin to add a curator the the list of allowed curators
     * @param curator wallet address to add to allow-list of curators
     */
    function allowCurator(address curator) public onlyOwner {
        curators[curator] = true;
        subRegistries[curator].feePercentage = CURATOR_TAKE_PER_10000;
        emit CuratorAdded(curator);
    }

    /**
     * @notice Public function for curator to set their curation fee as a whole number
     * percentage added to the owner list price.
     * @param feePercentage Fee percentage, with a base of 10000 == 100%
     */
    function setCuratorFee(uint16 feePercentage) public {
        require(curators[msg.sender], "JPGR:scf:Curator only");
        require(feePercentage <= MAX_FEE_PERC, "JPGR:scf:Fee exceeds MAX_FEE");
        subRegistries[msg.sender].feePercentage = feePercentage;
    }

    /**
     * @notice Called by contract owner admin to bulk add NFTs to ProtocolRegistry
     * @dev This saves listers gas by keeping things off-chain until a bulk add task is run
     * @param ownerBundles[] An array of OwnerBundle struct instances
     */
    function adminBulkAddToMainRegistry(OwnerBundle[] memory ownerBundles) public onlyOwner {
        for (uint256 j = 0; j < ownerBundles.length; j++) {
            Listing[] memory listings = ownerBundles[j].listings;

            for (uint256 i = 0; i < listings.length; i++) {
                mainRegistry[listings[i].nft.tokenContract][listings[i].nft.tokenId] = true;
            }
        }

        emit TokensListed(ownerBundles);
    }

    /**
     * @notice Called by contract owner admin to bulk remove NFTs from ProtocolRegistry
     * @param tokens[] An array of NFT struct instances
     */
    function bulkRemoveFromMainRegistry(NFT[] calldata tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeFromMainRegistry(tokens[i]);
        }
    }

    /**
     * @notice Called internally to remove from ProtocolRegistry
     * @param token An instance of an NFT struct
     */
    function _removeFromMainRegistry(NFT memory token) internal {
        mainRegistry[token.tokenContract][token.tokenId] = false;
    }
}
