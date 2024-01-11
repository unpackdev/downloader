// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "ERC721.sol";
import "Ownable.sol";
import "ECDSA.sol";

contract PrideIcons is ERC721, Ownable {
    using ECDSA for bytes32;

    uint8 public maxMintsPerTx;

    uint256 public silverPrice;
    uint256 public goldPrice;

    uint16 public silverSupply;
    uint16 public goldSupply;
    uint16 public platinumSupply;

    // Number of tokens minted - gold & silver
    // @VisibleForTesting
    uint16 internal mintedGold;
    uint16 internal mintedSilver;
    uint16 internal mintedPlatinum;

    // Keep track of platinum NFTs minted. This is useful for our Auction contract.
    mapping(uint16 => bool) public hasMintedPlatinum;

    // IPFS prefix URI for each token metadata.
    string private baseTokenURI;

    // IPFS URI for metadata that describes this contract.
    string private nftContractURI;

    // Those who bought during the Early Bird Sale.
    mapping(address => bool) public earlyBirdSaleList;

    // The amount each address bought during the Early Bird Sale.
    mapping(address => uint256) public earlyBirdSalePurchasesSilver;
    mapping(address => uint256) public earlyBirdSalePurchasesGold;

    // Those who bought during the presale.
    mapping(address => bool) public presaleList;

    // The amount each address bought during the presale.
    mapping(address => uint256) public presalePurchasesSilver;
    mapping(address => uint256) public presalePurchasesGold;

    // The amount each allowed address has reserved to purchase during the presale.
    // Allowed addresses are those who successfully registered before the presale.
    mapping(address => uint256) public presaleReservedSilver;
    mapping(address => uint256) public presaleReservedGold;

    // A salt to ensure transaction origin.
    mapping(bytes32 => bool) private nonces;

    // Provenance hash.
    string public proof;

    bool public earlyBirdSaleLive;
    bool public presaleLive;
    bool public publicSaleLive;

    bool public metadataLocked;
    bool public auctionLocked;

    uint16 public mintedSilverGifts;
    uint16 public mintedGoldGifts;

    uint256 public revealTimestamp;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    // @VisibleForTesting
    address internal auctionAddress;
    // @VisibleForTesting
    address internal vaultAddress;
    // Address from the approved sender.
    address internal signerAddress;

    // Paper wallets
    mapping(address => bool) private paperWallets;

    constructor(
        address _vaultAddress,
        address _signerAddress,
        string memory _baseTokenURI,
        string memory _nftContractURI,
        uint8 _maxMintsPerTx,
        uint256 _silverPrice,
        uint256 _goldPrice,
        uint16 _silverSupply,
        uint16 _goldSupply,
        uint16 _platinumSupply,
        address[] memory _paperWallets
    ) ERC721("PrideIcons", "PI") {
        require(_vaultAddress != address(0), "NULL_ADDRESS");
        require(_signerAddress != address(0), "NULL_ADDRESS");
        vaultAddress = _vaultAddress;
        signerAddress = _signerAddress;
        baseTokenURI = _baseTokenURI;
        nftContractURI = _nftContractURI;
        maxMintsPerTx = _maxMintsPerTx;
        silverPrice = _silverPrice;
        goldPrice = _goldPrice;
        silverSupply = _silverSupply;
        goldSupply = _goldSupply;
        platinumSupply = _platinumSupply;
        initializePaperWallets(_paperWallets);
    }

    modifier metadataNotLocked() {
        require(!metadataLocked, "CONTRACT_METADATA_METHODS_ARE_LOCKED");
        _;
    }

    modifier auctionNotLocked() {
        require(!auctionLocked, "CONTRACT_LOCKED_DOWN");
        _;
    }

    modifier onlyPaperOrOwner() {
        require(
            paperWallets[msg.sender] || owner() == msg.sender,
            "ONLY_PAPER_WALLETS_OR_OWNER_ALLOWED"
        );
        _;
    }

    // ------------------------------------------------------
    // Mint functions
    // ------------------------------------------------------
    function mint(
        bytes32 hash,
        bytes calldata signature,
        bytes32 nonce,
        uint16 silverQuantityToMint,
        uint16 goldQuantityToMint
    ) external payable {
        require(
            publicSaleLive && !presaleLive && !earlyBirdSaleLive,
            "SALE_CLOSED"
        );
        require(
            mintedSilver + silverQuantityToMint <= silverSupply,
            "OUT_OF_STOCK_SILVER"
        );
        require(
            mintedGold + goldQuantityToMint <= goldSupply,
            "OUT_OF_STOCK_GOLD"
        );
        require(
            silverQuantityToMint + goldQuantityToMint <= maxMintsPerTx,
            "EXCEED_QUANTITY_LIMIT"
        );
        require(
            msg.value >=
                (silverPrice *
                    silverQuantityToMint +
                    goldPrice *
                    goldQuantityToMint),
            "INSUFFICIENT_ETH"
        );
        require(matchAddresSigner(hash, signature), "UNAUTHORIZED_MINT");
        require(!nonces[nonce], "HASH_USED");
        require(
            hashTransaction(
                msg.sender,
                silverQuantityToMint + goldQuantityToMint,
                nonce
            ) == hash,
            "HASH_FAIL"
        );

        if (silverQuantityToMint > 0) {
            mintSilverQuantity(msg.sender, silverQuantityToMint);
        }
        if (goldQuantityToMint > 0) {
            mintGoldQuantity(msg.sender, goldQuantityToMint);
        }

        nonces[nonce] = true;

        // If we're done, set the starting index of the collection.
        trySetStartingIndex();
    }

    function mintEarlyBird(
        uint16 silverQuantityToMint,
        uint16 goldQuantityToMint
    ) external payable {
        require(
            earlyBirdSaleLive && !publicSaleLive && !presaleLive,
            "EARLY_BIRD_SALE_CLOSED"
        );
        require(earlyBirdSaleList[msg.sender], "UNAUTHORIZED");
        require(
            mintedSilver + silverQuantityToMint <= silverSupply,
            "OUT_OF_STOCK_SILVER"
        );
        require(
            mintedGold + goldQuantityToMint <= goldSupply,
            "OUT_OF_STOCK_GOLD"
        );
        require(
            earlyBirdSalePurchasesSilver[msg.sender] +
                silverQuantityToMint +
                earlyBirdSalePurchasesGold[msg.sender] +
                goldQuantityToMint <=
                maxMintsPerTx,
            "EXCEED_EARLY_BIRD_SALE_PERSONAL_LIMIT"
        );
        require(
            msg.value >=
                (silverPrice *
                    silverQuantityToMint +
                    goldPrice *
                    goldQuantityToMint),
            "INSUFFICIENT_ETH"
        );

        earlyBirdSalePurchasesSilver[msg.sender] += silverQuantityToMint;
        earlyBirdSalePurchasesGold[msg.sender] += goldQuantityToMint;

        if (silverQuantityToMint > 0) {
            mintSilverQuantity(msg.sender, silverQuantityToMint);
        }
        if (goldQuantityToMint > 0) {
            mintGoldQuantity(msg.sender, goldQuantityToMint);
        }

        // If we sold everything during early bird sale, set the starting index of the collection.
        trySetStartingIndex();
    }

    function mintPresale(uint16 silverQuantityToMint, uint16 goldQuantityToMint)
        external
        payable
    {
        require(
            presaleLive && !publicSaleLive && !earlyBirdSaleLive,
            "PRESALE_CLOSED"
        );
        require(presaleList[msg.sender], "UNAUTHORIZED");
        require(
            mintedSilver + silverQuantityToMint <= silverSupply,
            "OUT_OF_STOCK_SILVER"
        );
        require(
            mintedGold + goldQuantityToMint <= goldSupply,
            "OUT_OF_STOCK_GOLD"
        );
        require(
            presaleReservedSilver[msg.sender] == silverQuantityToMint &&
                presaleReservedGold[msg.sender] == goldQuantityToMint,
            "QUANTITY_MUST_BE_EQUAL_TO_RESERVED"
        );
        require(
            presalePurchasesSilver[msg.sender] +
                silverQuantityToMint +
                presalePurchasesGold[msg.sender] +
                goldQuantityToMint <=
                maxMintsPerTx,
            "EXCEED_PRESALE_PERSONAL_LIMIT"
        );
        require(
            msg.value >=
                (silverPrice *
                    silverQuantityToMint +
                    goldPrice *
                    goldQuantityToMint),
            "INSUFFICIENT_ETH"
        );

        presalePurchasesSilver[msg.sender] += silverQuantityToMint;
        presalePurchasesGold[msg.sender] += goldQuantityToMint;

        if (silverQuantityToMint > 0) {
            mintSilverQuantity(msg.sender, silverQuantityToMint);
        }
        if (goldQuantityToMint > 0) {
            mintGoldQuantity(msg.sender, goldQuantityToMint);
        }

        // If we sold everything during presale, set the starting index of the collection.
        trySetStartingIndex();
    }

    function mintPlatinum(uint8 tokenId, address buyer)
        external
        auctionNotLocked
    {
        require(auctionAddress != address(0), "AUCTION_CONTRACT_UNINITIALIZED");
        require(buyer != address(0), "NULL_ADDRESS");
        require(msg.sender == auctionAddress, "UNAUTHORIZED");
        require(mintedPlatinum + 1 <= platinumSupply, "OUT_OF_STOCK");
        require(tokenId <= platinumSupply, "TOKEN_ID_OUT_OF_PLATINUM_RANGE");

        _safeMint(buyer, tokenId);
        mintedPlatinum++;
        hasMintedPlatinum[tokenId] = true;
    }

    function giftSilver(address[] calldata receivers) external onlyOwner {
        require(
            mintedSilver + receivers.length <= silverSupply,
            "OUT_OF_STOCK_SILVER"
        );

        // Safe conversion since silverSupply is less than 2^16.
        mintedSilverGifts += uint16(receivers.length);
        for (uint16 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], getNextSilverTokenId() + i);
        }
        mintedSilver += uint16(receivers.length);
    }

    function giftGold(address[] calldata receivers) external onlyOwner {
        require(
            mintedGold + receivers.length <= goldSupply,
            "OUT_OF_STOCK_GOLD"
        );

        // Safe conversion since goldSupply is less than 2^16.
        mintedGoldGifts += uint16(receivers.length);
        for (uint16 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], getNextGoldTokenId() + i);
        }
        mintedGold += uint16(receivers.length);
    }

    // ------------------------------------------------------
    // Paper Mint functions
    // ------------------------------------------------------

    function paperMintSilver(address userWallet, uint8 quantity)
        public
        payable
        onlyPaperOrOwner
    {
        string memory ineligibilityReason = getClaimIneligibilityReasonSilver(
            userWallet,
            quantity
        );
        require(
            keccak256(abi.encodePacked(ineligibilityReason)) ==
                keccak256(abi.encodePacked("")),
            ineligibilityReason
        );

        if (presaleLive) {
            presalePurchasesSilver[userWallet] += quantity;
        } else if (earlyBirdSaleLive) {
            earlyBirdSalePurchasesSilver[userWallet] += quantity;
        }

        // Mint.
        mintSilverQuantity(userWallet, quantity);

        // If we sold everything during presale, set the starting index of the collection.
        trySetStartingIndex();
    }

    function paperMintGold(address userWallet, uint8 quantity)
        public
        payable
        onlyPaperOrOwner
    {
        string memory ineligibilityReason = getClaimIneligibilityReasonGold(
            userWallet,
            quantity
        );
        require(
            keccak256(abi.encodePacked(ineligibilityReason)) ==
                keccak256(abi.encodePacked("")),
            ineligibilityReason
        );

        if (presaleLive) {
            presalePurchasesGold[userWallet] += quantity;
        } else if (earlyBirdSaleLive) {
            earlyBirdSalePurchasesGold[userWallet] += quantity;
        }

        // Mint.
        mintGoldQuantity(userWallet, quantity);

        // If we sold everything during presale, set the starting index of the collection.
        trySetStartingIndex();
    }

    function getClaimIneligibilityReasonSilver(
        address userWallet,
        uint8 quantity
    ) public view returns (string memory) {
        if (presaleLive) {
            return
                getClaimIneligibilityReason(
                    userWallet,
                    quantity,
                    silverPrice,
                    mintedSilver,
                    silverSupply,
                    presaleReservedSilver[userWallet],
                    presalePurchasesSilver[userWallet],
                    presalePurchasesGold[userWallet]
                );
        }

        if (earlyBirdSaleLive) {
            return
                getClaimIneligibilityReason(
                    userWallet,
                    quantity,
                    silverPrice,
                    mintedSilver,
                    silverSupply,
                    0,
                    earlyBirdSalePurchasesSilver[userWallet],
                    earlyBirdSalePurchasesGold[userWallet]
                );
        }

        return
            getClaimIneligibilityReason(
                userWallet,
                quantity,
                silverPrice,
                mintedSilver,
                silverSupply,
                0,
                0,
                0
            );
    }

    function getClaimIneligibilityReasonGold(address userWallet, uint8 quantity)
        public
        view
        returns (string memory)
    {
        if (presaleLive) {
            return
                getClaimIneligibilityReason(
                    userWallet,
                    quantity,
                    goldPrice,
                    mintedGold,
                    goldSupply,
                    presaleReservedGold[userWallet],
                    presalePurchasesSilver[userWallet],
                    presalePurchasesGold[userWallet]
                );
        }

        if (earlyBirdSaleLive) {
            return
                getClaimIneligibilityReason(
                    userWallet,
                    quantity,
                    goldPrice,
                    mintedGold,
                    goldSupply,
                    0,
                    earlyBirdSalePurchasesSilver[userWallet],
                    earlyBirdSalePurchasesGold[userWallet]
                );
        }

        return
            getClaimIneligibilityReason(
                userWallet,
                quantity,
                goldPrice,
                mintedGold,
                goldSupply,
                0,
                0,
                0
            );
    }

    function getClaimIneligibilityReason(
        address userWallet,
        uint8 quantity,
        uint256 price,
        uint16 purchased,
        uint16 supply,
        uint256 reserved,
        uint256 purchasedSilver,
        uint256 purchasedGold
    ) private view returns (string memory) {
        if (quantity == 0) {
            return "NO_QUANTITY";
        }

        if (msg.value < (quantity * price)) {
            return "INSUFFICIENT_ETH";
        }

        if (purchased + quantity > supply) {
            return "NOT_ENOUGH_SUPPLY";
        }

        if (purchasedSilver + purchasedGold + quantity > maxMintsPerTx) {
            return "EXCEED_LIMIT";
        }

        if (earlyBirdSaleLive) {
            if (!earlyBirdSaleList[userWallet]) {
                return "NOT_ON_ALLOWLIST";
            }
        } else if (presaleLive) {
            if (!presaleList[userWallet]) {
                return "NOT_ON_ALLOWLIST";
            }

            if (reserved != quantity) {
                return "QUANTITY_MUST_BE_EQUAL_TO_RESERVED";
            }
        } else if (!publicSaleLive) {
            return "NOT_LIVE";
        }

        return "";
    }

    // ------------------------------------------------------
    // Utility
    // ------------------------------------------------------

    function mintSilverQuantity(address wallet, uint16 quantityToMint) private {
        for (uint16 i = 0; i < quantityToMint; i++) {
            _safeMint(wallet, getNextSilverTokenId() + i);
        }
        mintedSilver += quantityToMint;
    }

    function mintGoldQuantity(address wallet, uint16 quantityToMint) private {
        for (uint16 i = 0; i < quantityToMint; i++) {
            _safeMint(wallet, getNextGoldTokenId() + i);
        }
        mintedGold += quantityToMint;
    }

    function getNextSilverTokenId() internal view returns (uint16) {
        return mintedSilver + goldSupply + platinumSupply + 1;
    }

    function getNextGoldTokenId() internal view returns (uint16) {
        return mintedGold + platinumSupply + 1;
    }

    /** Setting the starting index will reveal the mapping of all tokens in the collection. */
    function setStartingIndex() public {
        require(startingIndex == 0, "ALREADY_SET");
        require(startingIndexBlock != 0, "MISSING_SEED");
        setStartingIndexInternal();
    }

    /** If the time is right, set the starting index of our collection and record the block number used. */
    function trySetStartingIndex() private {
        if (
            startingIndexBlock == 0 &&
            ((mintedSilver + mintedGold == silverSupply + goldSupply) ||
                block.timestamp >= revealTimestamp)
        ) {
            startingIndexBlock = block.number;
            setStartingIndexInternal();
        }
    }

    function setStartingIndexInternal() private {
        if (block.number - startingIndexBlock > 255) {
            // The EVM only stores the last 256 block hashs.
            startingIndex =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - 1),
                            block.coinbase,
                            block.timestamp
                        )
                    )
                ) %
                goldSupply;
        } else {
            startingIndex =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(startingIndexBlock),
                            block.coinbase,
                            block.timestamp
                        )
                    )
                ) %
                goldSupply;
        }

        // Prevent the default sequence.
        if (startingIndex == 0) {
            startingIndex = (block.number + 1) % goldSupply;
        }
    }

    function hashTransaction(
        address sender,
        uint256 quantity,
        bytes32 nonce
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, quantity, nonce))
            )
        );

        return hash;
    }

    function matchAddresSigner(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        return signerAddress == hash.recover(signature);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseTokenURI;
    }

    // For OpenSea and other marketplaces.
    function contractURI() public view returns (string memory) {
        return nftContractURI;
    }

    // ------------------------------------------------------
    // Owner functions
    // ------------------------------------------------------
    function addToEarlyBirdSale(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!earlyBirdSaleList[entry], "DUPLICATE_ENTRY");

            earlyBirdSaleList[entry] = true;
        }
    }

    function addToPresale(
        address[] calldata entries,
        uint256[] calldata reservedPresaleSilver,
        uint256[] calldata reservedPresaleGold
    ) external onlyOwner {
        require(
            entries.length == reservedPresaleSilver.length &&
                reservedPresaleSilver.length == reservedPresaleGold.length,
            "UNEQUAL_LENGTH"
        );
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            uint256 silverQuantityToReserve = reservedPresaleSilver[i];
            uint256 goldQuantityToReserve = reservedPresaleGold[i];
            require(
                silverQuantityToReserve > 0 || goldQuantityToReserve > 0,
                "RESERVE_MUST_BE_GREATER_THAN_ZERO"
            );
            require(
                silverQuantityToReserve + goldQuantityToReserve <=
                    maxMintsPerTx,
                "RESERVE_OVER_LIMIT"
            );
            require(entry != address(0), "NULL_ADDRESS");
            require(!presaleList[entry], "DUPLICATE_ENTRY");

            presaleList[entry] = true;
            if (silverQuantityToReserve > 0) {
                presaleReservedSilver[entry] = silverQuantityToReserve;
            }
            if (goldQuantityToReserve > 0) {
                presaleReservedGold[entry] = goldQuantityToReserve;
            }
        }
    }

    function removeFromEarlyBirdSaleList(address[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            earlyBirdSaleList[entry] = false;
        }
    }

    function removeFromPresaleList(address[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            presaleList[entry] = false;
            presaleReservedSilver[entry] = 0;
            presaleReservedGold[entry] = 0;
        }
    }

    function modifyTokenPrices(uint256 newSilverPrice, uint256 newGoldPrice)
        external
        onlyOwner
    {
        silverPrice = newSilverPrice;
        goldPrice = newGoldPrice;
    }

    function setVaultAddress(address newVault) external onlyOwner {
        require(newVault != address(0), "NULL_ADDRESS");
        vaultAddress = newVault;
    }

    function lockMetadata() external onlyOwner {
        metadataLocked = true;
    }

    function lockAuction() external onlyOwner {
        auctionAddress = address(0);
        auctionLocked = true;
    }

    function unlockAuction(address newAuctionAddress) external onlyOwner {
        auctionLocked = false;
        auctionAddress = newAuctionAddress;
    }

    /** When live, disables all other sales. */
    function toggleEarlyBirdStatus() external onlyOwner {
        earlyBirdSaleLive = !earlyBirdSaleLive;
        if (earlyBirdSaleLive) {
            presaleLive = false;
            publicSaleLive = false;
        }
    }

    /** When live, disables all other sales. */
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
        if (presaleLive) {
            earlyBirdSaleLive = false;
            publicSaleLive = false;
        }
    }

    /** When live, disables all other sales. */
    function togglePublicSaleStatus() external onlyOwner {
        publicSaleLive = !publicSaleLive;
        if (publicSaleLive) {
            earlyBirdSaleLive = false;
            presaleLive = false;
        }
    }

    function setRevealTimestamp(uint256 timestamp) public onlyOwner {
        revealTimestamp = timestamp;
    }

    function setSignerAddress(address addressToSet) external onlyOwner {
        require(addressToSet != address(0), "NULL_ADDRESS");
        signerAddress = addressToSet;
    }

    function withdrawAll() external onlyOwner {
        payable(vaultAddress).transfer(address(this).balance);
    }

    function setContractURI(string calldata uri) external onlyOwner {
        nftContractURI = uri;
    }

    function assignAuctionContractAddress(address _auctionAddress)
        external
        onlyOwner
    {
        require(_auctionAddress != address(0), "NULL_ADDRESS");
        auctionAddress = _auctionAddress;
    }

    function adjustMaxMintsPerTx(uint8 _maxMintsPerTx) external onlyOwner {
        maxMintsPerTx = _maxMintsPerTx;
    }

    // virtual for tests
    function initializePaperWallets(address[] memory wallets)
        public
        virtual
        onlyOwner
    {
        for (uint8 i = 0; i < wallets.length; i++) {
            paperWallets[wallets[i]] = true;
        }
    }

    function adjustSupply(
        uint16 newSilverSupply,
        uint16 newGoldSupply,
        uint16 newPlatinumSupply
    ) external onlyOwner {
        require(
            newPlatinumSupply == platinumSupply ||
                (mintedPlatinum <= newPlatinumSupply &&
                    mintedSilver == 0 &&
                    mintedGold == 0),
            "SUPPLY_CANNOT_CHANGE_AFTER_MINT"
        );
        require(
            newGoldSupply == goldSupply ||
                (mintedGold <= newGoldSupply && mintedSilver == 0),
            "SUPPLY_CANNOT_CHANGE_AFTER_MINT"
        );
        require(
            mintedSilver <= newSilverSupply,
            "SUPPLY_CANNOT_CHANGE_AFTER_MINT"
        );

        silverSupply = newSilverSupply;
        goldSupply = newGoldSupply;
        platinumSupply = newPlatinumSupply;
    }

    // ------------------------------------------------------
    // NFT meta functions
    // ------------------------------------------------------
    function setBaseTokenURI(string calldata uri)
        external
        onlyOwner
        metadataNotLocked
    {
        baseTokenURI = uri;
    }

    function setProvenanceHash(string calldata hash)
        external
        onlyOwner
        metadataNotLocked
    {
        proof = hash;
    }

    /**
     * Set the starting index block for the collection if setting
     * starting index is blocked.
     */
    function emergencySetStartingIndexBlock()
        external
        onlyOwner
        metadataNotLocked
    {
        require(startingIndex == 0, "STARTING_INDEX_ALREADY_SET");
        startingIndexBlock = block.number;
    }
}
