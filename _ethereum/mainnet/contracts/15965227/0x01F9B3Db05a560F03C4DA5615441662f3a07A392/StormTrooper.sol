// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./ERC2981.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ConfirmedOwner.sol";

contract StormTrooper is ERC1155, ERC2981, AccessControl, VRFConsumerBaseV2, ConfirmedOwner {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // chainlink event
    event RequestMintSent(
        uint256 requestId, 
        address requestedBy,
        uint256 brand,
        uint32 numWords, 
        uint256 amount
    );

    event RequestMintFulfilled(
        uint256 requestId, 
        address to,
        uint256 brand,
        uint256 collectionId,
        uint256[] randomWords
    );

    event CollectionCreated (
        uint256 indexed brand,
        uint256 indexed collectionId,
        uint256 indexed cap,
        bool enabled,
        bool exist
    );

    event BrandCreated (
        uint256 collectionIds,
        uint256 mintPriceInWei,
        bool enabled,
        bool exist
    );

    event UpdateBrandMintPrice(
        uint256 indexed brand,
        uint256 indexed mintPriceInWei
    );

    struct MintRequestStatus {
        address to;
        uint256 brand;
        uint256 collectionId;
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint256 dateCreated;
    }

    struct StormTrooperItem {
        // categories collection
        uint256 brand; 
        uint256 cap;
        uint256 minted;
        bool enabled;
        bool exist;
    }

    struct Brand {
        uint256[] collectionIds;
        uint mintPriceInWei;
        bool enabled;
        bool exist;
        bool isPremintOpen;
        bytes32 whitelistMerkleRoot;
    }

    // Your subscription ID.
    uint64 public subscriptionId;
    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 public keyHash;

    uint32 public callbackGasLimit = 160000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    // withdrawal variables
    address[] public wallets;
    uint256[] public walletsShares;
    uint256 public totalShares;

    mapping(address => uint256[]) public accountMintRequest; /* minter --> requestId */
    mapping(uint256 => MintRequestStatus) public mintRequests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // collectionId => StormTrooperItem
    mapping(uint256 => StormTrooperItem) private stormtroopers;
    // brandId => Brand
    mapping(uint256 => Brand) private brands;
    // track collection id => brand id
    mapping(uint256 => uint256) public collectionIdsBrand;

    // get all collectionIds
    uint256[] collectionIds;
    // get all brandIds
    uint256[] brandIds;
    // max mint per tx
    uint256 maxMintPerTx = 5;


    modifier onlyHasRole(bytes32 _role) {
        require(hasRole(_role, _msgSender()), "Caller does not have role");
        _;
    }

    constructor(
        string memory baseMetaURI, 
        uint96 _feeNumerator, 
        address _coordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) 
        ERC1155(baseMetaURI) 
        VRFConsumerBaseV2(_coordinator)
        ConfirmedOwner(msg.sender) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_msgSender(), _feeNumerator);
        _tokenIds.increment();

        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }
    // === Pre-Mint === //

    function premint(bytes32[] calldata _proof, uint256 _brandId, uint256 _quantity) external payable {
        require(brands[_brandId].mintPriceInWei * _quantity == msg.value, "Invalid eth price");
        _premint(_proof, _msgSender(), _brandId, _quantity);
    }

    function premint(bytes32[] calldata _proof, address to, uint256 _collectionId, uint256 _quantity) external onlyHasRole(MINTER_ROLE) {
        _premint(_proof, to, _collectionId, _quantity);
    }

    function _premint(bytes32[] calldata _proof, address to, uint256 _brandId, uint256 _quantity) internal {
        require(brands[_brandId].isPremintOpen, "Premint disabled.");

        require(
            _verifySenderProof(to, brands[_brandId].whitelistMerkleRoot, _proof),
            "Invalid proof"
        );

        require(_quantity > 0, "quantity cannot be zero");
        require(_quantity <= maxMintPerTx, "exceed max mint limit per tx.");
        for (uint256 ctr = 0; ctr < _quantity; ctr++) {
            _requestMint(msg.sender, _brandId);
        }
    }

    function isWhitelistedAddressOnBrand(bytes32[] calldata _proof, address to, uint256 brandId) external view returns (bool) {
        return _verifySenderProof(to, brands[brandId].whitelistMerkleRoot, _proof);
    }

     // === Minting === //

    /// @dev mint multiple nft
    /// @param _brandId the brand id to mint
    /// @param _quantity the number of nft to mint
    function multiRequestMint(uint256 _brandId, uint256 _quantity) public payable {
        require(_quantity > 0, "quantity cannot be zero");
        require(_quantity <= maxMintPerTx, "exceed max mint limit per tx.");
        require(!brands[_brandId].isPremintOpen, "Premint currently enabled");
        require(brands[_brandId].mintPriceInWei * _quantity == msg.value, "Not enough eth.");
        for (uint256 ctr = 0; ctr < _quantity; ctr++) {
            _requestMint(msg.sender, _brandId);
        }
    }

     /// @dev mint multiple nft
    /// @param _brandId the brand id to mint
    /// @param _quantity the number of nft to mint
    function multiRequestMint(address _to, uint256 _brandId, uint256 _quantity) public onlyHasRole(MINTER_ROLE) {
        require(_quantity > 0, "quantity cannot be zero");
        require(_quantity <= maxMintPerTx, "exceed max mint limit per tx.");
        require(!brands[_brandId].isPremintOpen, "Premint currently enabled");
        for (uint256 ctr = 0; ctr < _quantity; ctr++) {
            _requestMint(_to, _brandId);
        }
    }

    function requestMint(uint256 _brandId) public payable {
        require(brands[_brandId].mintPriceInWei * 1 == msg.value, "Not enough eth.");
        require(!brands[_brandId].isPremintOpen, "Premint currently enabled");
        _requestMint(msg.sender, _brandId);
    }

    function requestMint(address _to, uint256 _brandId) public onlyHasRole(MINTER_ROLE) {
        require(!brands[_brandId].isPremintOpen, "Premint currently enabled");
        _requestMint(_to, _brandId);
    }

    function _requestMint(address _to, uint256 _brandId) internal {
        require(brands[_brandId].exist, "Brand doesnt exist.");
        require(brands[_brandId].enabled, "Brand currently disabled.");
        require(getMintableCollectionIds(_brandId).length > 0, "Sold out.");

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // request random words
        );

        accountMintRequest[_to].push(requestId);

        mintRequests[requestId] = MintRequestStatus({
            to: _to,
            brand: _brandId,
            collectionId: 0,
            randomWords: new uint256[](1), 
            exists: true, 
            fulfilled: false,
            dateCreated: block.timestamp
        });

        requestIds.push(requestId);
        lastRequestId = requestId;

        emit RequestMintSent({
            requestId: requestId,
            requestedBy: _to,
            brand: _brandId,
            numWords: 1,
            amount: 0
        });
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(_randomWords.length > 0, "Random Words cannot be empty.");
        require(mintRequests[_requestId].exists, "request not found");
        mintRequests[_requestId].fulfilled = true;
        mintRequests[_requestId].randomWords = _randomWords;

        MintRequestStatus memory req = mintRequests[_requestId];
        uint256[] memory mintableCollections = getMintableCollectionIds(req.brand);
        // set the index to mint based on the random worlds return
        uint256 collectionIndexToMint = _randomWords[0] % mintableCollections.length;

        uint256 _collectionId = brands[req.brand].collectionIds[collectionIndexToMint];
        stormtroopers[_collectionId].minted =  stormtroopers[_collectionId].minted + 1;
        mintRequests[_requestId].collectionId = _collectionId;

        emit RequestMintFulfilled({
            requestId: _requestId, 
            to: req.to,
            brand: req.brand,
            collectionId: _collectionId,
            randomWords: _randomWords
        });

        _mint(mintRequests[_requestId].to, _collectionId, 1, "");
    }

    function getRequestStatus(uint256 _requestId) external view returns (
        address to,
        uint256 brand,
        uint256 collectionId,
        bool fulfilled, 
        uint256[] memory randomWords,
        uint256 dateCreated
    ) {
        require(mintRequests[_requestId].exists, "request not found");
        MintRequestStatus memory request = mintRequests[_requestId];
        return (request.to, request.brand, request.collectionId, request.fulfilled, request.randomWords, request.dateCreated);
    }

    /// @dev Get next tokenId
    function nextTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    /// @dev Get all mintable collection by brandID
    /// @param _brandId The brand id
    function getMintableCollectionIds(uint256 _brandId) public view returns (uint256[] memory) {
        uint256[] memory ids = _getCollectionIdsByBrand(_brandId);
        uint256 unmintableCount = 0;
        for (uint256 id = 0; id < ids.length; id++) {
            // if mintable is less than cap, add +1 to mintable count
            if (stormtroopers[ids[id]].minted >= stormtroopers[ids[id]].cap || !stormtroopers[ids[id]].enabled) {
                unmintableCount += 1;
            }
        }

        // return when unmintable == 0
        if (unmintableCount == 0) {
            return ids;
        }

        // size of mintable
        uint256[] memory mintable = new uint256[](ids.length - unmintableCount);
        uint256 mintableIndexCounter = 0;
        for (uint256 id = 0; id < ids.length; id++) {
            // if minted item is less than cap, store to memory
            // also make sure that collection is enabled
            if (stormtroopers[ids[id]].minted < stormtroopers[ids[id]].cap && stormtroopers[ids[id]].enabled) {
                // make sure that mintableIndexCounter is less or equal to (n - 1)
                if (mintableIndexCounter < mintable.length) {
                    mintable[mintableIndexCounter] = ids[id];
                    mintableIndexCounter += 1;
                }
            }
        }

        return mintable; // return mintable array
    }

    /// @notice Return all brand ids
    function getAllBrands() external view returns (uint256[] memory) {
        return brandIds;
    }

    /// @notice Return brand mint price
    /// @param brandId The Brand ID
    function getBrandMintPrice(uint256 brandId) external view returns (uint256) {
        return brands[brandId].mintPriceInWei;
    }

    function getBrandInfo(uint256 brandId) external view returns (Brand memory) {
        return brands[brandId];
    }

    function getRequestIdsByAccount(address account) external view returns (uint256[] memory) {
        return accountMintRequest[account];
    }

    /// @dev Get all collectionIds by brand
    /// @param _brandId The brand id
    function getCollectionIdsByBrand(uint256 _brandId) public view returns (uint256[] memory) {
        return _getCollectionIdsByBrand(_brandId);
    }

    /// @dev Get token collection info by ID
    /// @param _tokenId The token collection info
    function getCollectionInfoById(uint256 _tokenId) public view returns (StormTrooperItem memory) {
        require(stormtroopers[_tokenId].exist, "Token does not exist.");
        return stormtroopers[_tokenId];
    }

    /// @notice Return VRF callback gas limit
    function getCallbackGasLimit() external view returns (uint32) {
        return callbackGasLimit;
    }

    /// @notice Return VRF request confirmation
    function getRequestConfirmation() external view returns (uint16) {
        return requestConfirmations;
    }

    /// @notice Return VRF key hash
    function getVrfKeyHash() external view returns (bytes32) {
        return keyHash;
    }

    // === Admin === //
    function mint(address _to, uint256 _collectionId, uint256 _quantity) public onlyHasRole(ADMIN_ROLE) {
        require(stormtroopers[_collectionId].exist, "Collection ID doesnt exist.");
        require(stormtroopers[_collectionId].enabled, "Collection disabled.");
        require(stormtroopers[_collectionId].minted + _quantity >= stormtroopers[_collectionId].cap, "exceed total supply");
        stormtroopers[_collectionId].minted =  stormtroopers[_collectionId].minted + _quantity;

        _mint(_to, _collectionId, _quantity, "");
    }

    /// @dev Set new base URI, kindly take a look on https://eips.ethereum.org/EIPS/eip-1155 for the format
    /// @param newuri The new URI to set
    function setURI(string memory newuri) public onlyHasRole(ADMIN_ROLE) {
        _setURI(newuri);
    }
    
    /// @dev Set the number mint per tx
    /// @param _maxMintPerTx The number of mint per tx
    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyHasRole(ADMIN_ROLE) {
        maxMintPerTx = _maxMintPerTx;
    }

    /// @dev Update vrf keyhash
    /// @param _keyHash The VRF keyhash
    function updateVrfKeyHash(bytes32 _keyHash) public onlyHasRole(ADMIN_ROLE) {
        keyHash = _keyHash;
    }

    /// @dev Adjust VRF gas limit
    /// @param gasLimit The callback gas limit
    function updateCallbackGasLimit(uint32 gasLimit) public onlyHasRole(ADMIN_ROLE) {
        callbackGasLimit = gasLimit;
    }

    /// @dev Adjust request confirmation
    /// @param _requestConfirmation The VRF request confirmation
    function updateRequestConfirmation(uint16 _requestConfirmation) public onlyHasRole(ADMIN_ROLE) {
        requestConfirmations = _requestConfirmation;
    }

    /// @dev Update SubscriptionId
    /// @param _subscriptionId The VRF subscriptionId
    function updateSubscriptionId(uint16 _subscriptionId) public onlyHasRole(ADMIN_ROLE) {
        subscriptionId = _subscriptionId;
    }

    /// @dev Update brand mint price
    /// @param _brandId The brand ID
    /// @param _mintPriceInWei The new Mint Price
    function updateBrandPrice(uint256 _brandId, uint256 _mintPriceInWei) external onlyHasRole(ADMIN_ROLE) {
        require(brands[_brandId].exist, "Brand doesnt exist.");
        brands[_brandId].mintPriceInWei = _mintPriceInWei;

        emit UpdateBrandMintPrice({
            brand: _brandId,
            mintPriceInWei: _mintPriceInWei
        });
    }

    /// @dev Set Brand 
    /// @param brandId The Brand ID
    /// @param mintPriceInWei The mint price for this brand
    function createBrand(uint256 brandId, uint256 mintPriceInWei, bool isPremintOpen) public onlyHasRole(ADMIN_ROLE) {
        require(!brands[brandId].exist, "Brand already exist.");

        brands[brandId] = Brand({
            collectionIds: new uint256[](0),
            mintPriceInWei: mintPriceInWei,
            enabled: true,
            exist: true,
            isPremintOpen: isPremintOpen,
            whitelistMerkleRoot: ""
        });

        brandIds.push(brandId);

        emit BrandCreated({
            collectionIds: 0,
            mintPriceInWei: mintPriceInWei,
            enabled: true,
            exist: true
        });
    }

    /// @dev Create collection
    /// @param cap The collection supply
    /// @param brand The brand to categories collection
    function createCollection(uint256 cap, uint256 brand, bool isEnabled) external onlyHasRole(ADMIN_ROLE) {
        require(brands[brand].exist, "Brand doesnt exist.");
        require(cap > 0, "Collection supply cannot be zero");
        uint256 tokenId = nextTokenId();
        stormtroopers[tokenId] = StormTrooperItem(
            brand, // tag to categories collection
            cap, // token cap
            0, // mint count
            isEnabled, // enabled
            true // exist
        );

        _tokenIds.increment();

        collectionIds.push(tokenId);
        collectionIdsBrand[tokenId] = brand;
        brands[brand].collectionIds.push(tokenId);

        emit CollectionCreated({
            brand: brand, 
            collectionId: tokenId, 
            cap: cap,
            enabled: isEnabled,
            exist: true
        });
    }

    function setWhitelistForBrand(bytes32 _whitelistMerkleRoot, uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(brands[brandId].exist, "Brand doesnt exist");
        brands[brandId].whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function togglePremintStatus(uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(brands[brandId].exist, "Brand doesnt exist");
        brands[brandId].isPremintOpen = !brands[brandId].isPremintOpen;
    }

    /// @notice Enable Brand
    /// @param brandId The Brand to enable
    function enableBrand(uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(brands[brandId].exist, "Brand doesnt exist.");
        require(!brands[brandId].enabled, "Brand already enabled.");
        brands[brandId].enabled = true;
    }

    /// @notice Disable Brand
    /// @param brandId The Brand to disable
    function disableBrand(uint256 brandId) public onlyHasRole(ADMIN_ROLE) {
        require(brands[brandId].exist, "Brand doesnt exist.");
        require(brands[brandId].enabled, "Brand already disabled.");
        brands[brandId].enabled = false;
    }

    /// @notice Disable minting for this specific collection
    /// @param _id the collection id
    function enableCollection(uint256 _id) public onlyHasRole(ADMIN_ROLE) {
        require(stormtroopers[_id].exist, "Collection ID doesnt exist.");
        require(!stormtroopers[_id].enabled, "Collection already enabled.");
        stormtroopers[_id].enabled = true;
    }

    /// @notice Disable minting for this specific collection
    /// @param _id the collection id
    function disableCollection(uint256 _id) public onlyHasRole(ADMIN_ROLE) {
        require(stormtroopers[_id].exist, "Collection ID doesnt exist.");
        require(stormtroopers[_id].enabled, "Collection already disabled.");
        stormtroopers[_id].enabled = false;
    }

    /// @dev Update max supply of collection
    /// @param tokenId The collection id to update
    /// @param cap The collection supply
    function updateCapCollection(uint256 tokenId, uint256 cap) external onlyHasRole(ADMIN_ROLE) {
        require(cap > 0, "Collection supply cannot be zero");
        require(stormtroopers[tokenId].enabled, "Collection ID doesnt exist.");
        require(stormtroopers[tokenId].cap >= stormtroopers[tokenId].minted, "Cap cannot less than minted token.");
        StormTrooperItem storage item =  stormtroopers[tokenId];
        item.cap = cap;
    }

    // === Royalty === //

    /// @dev Set the royalty for all collection
    /// @param _feeNumerator The fee for collection
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyHasRole(ADMIN_ROLE)
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @dev Set royalty fee for specific token
    /// @param _tokenId The tokenId where to add the royalty
    /// @param _receiver The royalty receiver
    /// @param _feeNumerator the fee for specific tokenId
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) public onlyHasRole(ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /// @dev Allow owner to delete the default royalty for all collection
    function deleteDefaultRoyalty() external onlyHasRole(ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /// @dev Reset specific royalty
    /// @param tokenId The token id where to reset the royalty
    function resetTokenRoyalty(uint256 tokenId)
        external
        onlyHasRole(ADMIN_ROLE)
    {
        _resetTokenRoyalty(tokenId);
    }

    // === Verify MerkleProof === //

    function _verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _verifySenderProof(
        address sender,
        bytes32 merkleRoot,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return _verify(proof, merkleRoot, leaf);
    }

    // === Withdrawal ===

    /// @dev Set wallets shares
    /// @param _wallets The wallets
    /// @param _walletsShares The wallets shares
    function setWithdrawalInfo(
        address[] memory _wallets,
        uint256[] memory _walletsShares
    ) public onlyHasRole(ADMIN_ROLE) {
        require(_wallets.length == _walletsShares.length, "not equal");
        wallets = _wallets;
        walletsShares = _walletsShares;

        totalShares = 0;
        for (uint256 i = 0; i < _walletsShares.length; i++) {
            totalShares += _walletsShares[i];
        }
    }

    /// @dev Withdraw contract native token balance
    function withdraw() external onlyHasRole(ADMIN_ROLE) {
        require(address(this).balance > 0, "no eth to withdraw");
        uint256 totalReceived = address(this).balance;
        for (uint256 i = 0; i < walletsShares.length; i++) {
            uint256 payment = (totalReceived * walletsShares[i]) / totalShares;
            Address.sendValue(payable(wallets[i]), payment);
        }
    }

    // === SupportInterface === //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Internal functions

    /// @dev Get all collections by brand
    /// @param _brandId The brand id
    function _getCollectionIdsByBrand(uint256 _brandId) internal view returns (uint256[] memory) {
        return brands[_brandId].collectionIds;
    }

}