//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./HasSecondarySaleFees.sol";

import "./ERC721Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

contract BlueprintV7 is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable
{
    using StringsUpgradeable for uint256;

    uint32 public defaultPlatformPrimaryFeePercentage;    
    uint32 public defaultBlueprintSecondarySalePercentage;
    uint32 public defaultPlatformSecondarySalePercentage;
    uint64 public latestErc721TokenIndex;
    uint256 public blueprintIndex;

    address public asyncSaleFeesRecipient;
    address public platform;
    address public minterAddress;
    
    mapping(uint256 => uint256) tokenToBlueprintID;
    mapping(address => uint256) failedTransferCredits;
    mapping(uint256 => Blueprints) public blueprints;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    enum SaleState {
        not_prepared,
        not_started,
        started,
        paused
    }
    struct Blueprints {
        bool tokenUriLocked;
        uint32 mintAmountArtist;
        uint32 mintAmountPlatform;
        uint64 capacity;
        uint64 erc721TokenIndex;
        uint64 maxPurchaseAmount;
        uint128 price;          
        address artist;
        address ERC20Token;
        string baseTokenUri;
        bytes32 merkleroot;
        SaleState saleState;    
        uint32[] primaryFeeBPS;
        uint32[] secondaryFeeBPS;
        address[] primaryFeeRecipients;
        address[] secondaryFeeRecipients;
        mapping(address => bool) claimedWhitelistedPieces;
    }

    event BlueprintSeed(uint256 blueprintID, string randomSeed);

    event BlueprintMinted(
        uint256 blueprintID,
        address artist,
        address purchaser,
        uint128 tokenId,
        uint64 newCapacity,
        bytes32 seedPrefix
    );

    event BlueprintPrepared(
        uint256 blueprintID,
        address artist,
        uint64 capacity,
        string blueprintMetaData,
        string baseTokenUri
    );

    event BlueprintSettingsUpdated(
        uint256 blueprintID,
        uint128 price,
        uint32 newMintAmountArtist,
        uint32 newMintAmountPlatform,
        uint32 newSaleState,
        uint64 newMaxPurchaseAmount,
        bytes32 newMerkleRoot
    );

    event SaleStarted(uint256 blueprintID);

    event SalePaused(uint256 blueprintID);

    event SaleUnpaused(uint256 blueprintID);

    event BlueprintTokenUriUpdated(uint256 blueprintID, string newBaseTokenUri);

    modifier isBlueprintPrepared(uint256 _blueprintID) {
        require(
            blueprints[_blueprintID].saleState != SaleState.not_prepared,
            "blueprint not prepared"
        );
        _;
    }

    modifier hasSaleStarted(uint256 _blueprintID) {
        require(_hasSaleStarted(_blueprintID), "Sale not started");
        _;
    }

    modifier BuyerWhitelistedOrSaleStarted(
        uint256 _blueprintID,
        uint32 _quantity,
        bytes32[] calldata proof
    ) {
        require(
            _hasSaleStarted(_blueprintID) ||
                (_isBlueprintPreparedAndNotStarted(_blueprintID) &&
                    userWhitelisted(_blueprintID, uint256(_quantity), proof)),
            "not available to purchase"
        );
        _;
    }

    modifier isQuantityAvailableForPurchase(
        uint256 _blueprintID,
        uint32 _quantity
    ) {
        require(
            blueprints[_blueprintID].capacity >= _quantity,
            "quantity exceeds capacity"
        );
        _;
    }

    ///
    ///Initialize the implementation
    ///
    function initialize(
        string memory name_,
        string memory symbol_,
        address minter
    ) public initializer {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, minter);

        platform = msg.sender;
        minterAddress = minter;

        defaultPlatformPrimaryFeePercentage = 2000; // 20%

        defaultBlueprintSecondarySalePercentage = 750; // 7.5%
        defaultPlatformSecondarySalePercentage = 250; // 2.5%

        asyncSaleFeesRecipient = msg.sender;
    }

    function _hasSaleStarted(uint256 _blueprintID)
        internal
        view
        returns (bool)
    {
        return blueprints[_blueprintID].saleState == SaleState.started;
    }

    function _isBlueprintPreparedAndNotStarted(uint256 _blueprintID)
        internal
        view
        returns (bool)
    {
        return blueprints[_blueprintID].saleState == SaleState.not_started;
    }

    function _getFeePortion(uint256 _totalSaleAmount, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalSaleAmount * (_percentage)) / 10000;
    }

    function userWhitelisted(
        uint256 _blueprintID,
        uint256 _quantity,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        require(proof.length != 0, "no proof provided");
        require(
            !blueprints[_blueprintID].claimedWhitelistedPieces[msg.sender],
            "already claimed"
        );
        bytes32 _merkleroot = blueprints[_blueprintID].merkleroot;
        return _verify(_leaf(msg.sender, _quantity), _merkleroot, proof);
    }

    function feesApplicable(
        address[] memory _feeRecipients,
        uint32[] memory _feeBPS
    ) internal pure returns (bool) {
        if (_feeRecipients.length != 0 || _feeBPS.length != 0) {
            require(
                _feeRecipients.length == _feeBPS.length,
                "mismatched recipients & Bps"
            );
            uint32 totalPercent;
            for (uint256 i = 0; i < _feeBPS.length; i++) {
                totalPercent = totalPercent + _feeBPS[i];
            }
            require(totalPercent <= 10000, "Fee Bps exceed maximum");
            return true;
        }
        return false;
    }

    function setBlueprintPrepared(
        uint256 _blueprintID,
        string memory _blueprintMetaData
    ) internal {
        blueprints[_blueprintID].saleState = SaleState.not_started;
        //assign the erc721 token index to the blueprint
        blueprints[_blueprintID].erc721TokenIndex = latestErc721TokenIndex;
        uint64 _capacity = blueprints[_blueprintID].capacity;
        latestErc721TokenIndex += _capacity;
        blueprintIndex++;

        emit BlueprintPrepared(
            _blueprintID,
            blueprints[_blueprintID].artist,
            _capacity,
            _blueprintMetaData,
            blueprints[_blueprintID].baseTokenUri
        );
    }

    function setErc20Token(uint256 _blueprintID, address _erc20Token) internal {
        if (_erc20Token != address(0)) {
            blueprints[_blueprintID].ERC20Token = _erc20Token;
        }
    }

    function _setupBlueprint(
        uint256 _blueprintID,
        address _erc20Token,
        string memory _baseTokenUri,
        bytes32 _merkleroot,
        uint32 _mintAmountArtist,
        uint32 _mintAmountPlatform,
        uint32 _maxPurchaseAmount
    ) internal {
        setErc20Token(_blueprintID, _erc20Token);

        blueprints[_blueprintID].baseTokenUri = _baseTokenUri;

        if (_merkleroot != 0) {
            blueprints[_blueprintID].merkleroot = _merkleroot;
        }

        blueprints[_blueprintID].mintAmountArtist = _mintAmountArtist;
        blueprints[_blueprintID].mintAmountPlatform = _mintAmountPlatform;

        if (_maxPurchaseAmount != 0) {
            blueprints[_blueprintID].maxPurchaseAmount = _maxPurchaseAmount;
        }
    }

    function prepareBlueprint(
        address _artist,
        uint64 _capacity,
        uint128 _price,
        address _erc20Token,
        string memory _blueprintMetaData,
        string memory _baseTokenUri,
        bytes32 _merkleroot,
        uint32 _mintAmountArtist,
        uint32 _mintAmountPlatform,
        uint32 _maxPurchaseAmount
    ) external onlyRole(MINTER_ROLE) {
        uint256 _blueprintID = blueprintIndex;
        blueprints[_blueprintID].artist = _artist;
        blueprints[_blueprintID].capacity = _capacity;
        blueprints[_blueprintID].price = _price;

        _setupBlueprint(
            _blueprintID,
            _erc20Token,
            _baseTokenUri,
            _merkleroot,
            _mintAmountArtist,
            _mintAmountPlatform,
            _maxPurchaseAmount
        );
        setBlueprintPrepared(_blueprintID, _blueprintMetaData);
    }

    function updateBlueprintSettings (
        uint256 _blueprintID,
        uint128 _price,
        uint32 _mintAmountArtist,
        uint32 _mintAmountPlatform,
        uint32 _newSaleState,
        uint64 _newMaxPurchaseAmount,
        bytes32 _merkleroot
    ) external onlyRole(MINTER_ROLE) {
        blueprints[_blueprintID].price = _price;
        blueprints[_blueprintID].mintAmountArtist = _mintAmountArtist;
        blueprints[_blueprintID].mintAmountPlatform = _mintAmountPlatform;
        blueprints[_blueprintID].saleState = SaleState (_newSaleState);
        blueprints[_blueprintID].merkleroot = _merkleroot; 
        blueprints[_blueprintID].maxPurchaseAmount = _newMaxPurchaseAmount;

        emit BlueprintSettingsUpdated(_blueprintID, _price, _mintAmountArtist, _mintAmountPlatform, _newSaleState, _newMaxPurchaseAmount, _merkleroot);
    }

    function setFeeRecipients(
        uint256 _blueprintID,
        address[] memory _primaryFeeRecipients,
        uint32[] memory _primaryFeeBPS,
        address[] memory _secondaryFeeRecipients,
        uint32[] memory _secondaryFeeBPS
    ) external onlyRole(MINTER_ROLE) {
        require(
            blueprints[_blueprintID].saleState == SaleState.not_started,
            "sale started or not prepared"
        );
        if (feesApplicable(_primaryFeeRecipients, _primaryFeeBPS)) {
            blueprints[_blueprintID]
                .primaryFeeRecipients = _primaryFeeRecipients;
            blueprints[_blueprintID].primaryFeeBPS = _primaryFeeBPS;
        }

        if (feesApplicable(_secondaryFeeRecipients, _secondaryFeeBPS)) {
            blueprints[_blueprintID]
                .secondaryFeeRecipients = _secondaryFeeRecipients;
            blueprints[_blueprintID].secondaryFeeBPS = _secondaryFeeBPS;
        }
    }

    function beginSale(uint256 blueprintID) external onlyRole(MINTER_ROLE) {
        require(
            blueprints[blueprintID].saleState == SaleState.not_started,
            "sale started or not prepared"
        );
        blueprints[blueprintID].saleState = SaleState.started;
        emit SaleStarted(blueprintID);
    }

    function pauseSale(uint256 blueprintID)
        external
        onlyRole(MINTER_ROLE)
        hasSaleStarted(blueprintID)
    {
        blueprints[blueprintID].saleState = SaleState.paused;
        emit SalePaused(blueprintID);
    }

    function unpauseSale(uint256 blueprintID) external onlyRole(MINTER_ROLE) {
        require(
            blueprints[blueprintID].saleState == SaleState.paused,
            "Sale not paused"
        );
        blueprints[blueprintID].saleState = SaleState.started;
        emit SaleUnpaused(blueprintID);
    }

    function purchaseBlueprintsTo(
        uint256 blueprintID,
        uint32 quantity,
        uint256 tokenAmount,
        bytes32[] calldata proof,
        address nftRecipient
    )
        external
        payable
        BuyerWhitelistedOrSaleStarted(blueprintID, quantity, proof)
        isQuantityAvailableForPurchase(blueprintID, quantity)
    {
        require(
            blueprints[blueprintID].maxPurchaseAmount == 0 ||
                quantity <= blueprints[blueprintID].maxPurchaseAmount,
            "user cannot buy more than maxPurchaseAmount in single tx"
        );

        require (tx.origin == msg.sender, "purchase cannot be called from another contract");

        address _artist = blueprints[blueprintID].artist;
        _confirmPaymentAmountAndSettleSale(
            blueprintID,
            quantity,
            tokenAmount,
            _artist
        );

        if (blueprints[blueprintID].saleState == SaleState.not_started) {
            blueprints[blueprintID].claimedWhitelistedPieces[msg.sender] = true;
        }

        _mintQuantity(blueprintID, quantity, nftRecipient);
    }

    function purchaseBlueprints(
        uint256 blueprintID,
        uint32 quantity,
        uint256 tokenAmount,
        bytes32[] calldata proof
    )
        external
        payable
        BuyerWhitelistedOrSaleStarted(blueprintID, quantity, proof)
        isQuantityAvailableForPurchase(blueprintID, quantity)
    {
        require(
            blueprints[blueprintID].maxPurchaseAmount == 0 ||
                quantity <= blueprints[blueprintID].maxPurchaseAmount,
            "user cannot buy more than maxPurchaseAmount in single tx"
        );

        require (tx.origin == msg.sender, "purchase cannot be called from another contract");

        address _artist = blueprints[blueprintID].artist;
        _confirmPaymentAmountAndSettleSale(
            blueprintID,
            quantity,
            tokenAmount,
            _artist
        );

        if (blueprints[blueprintID].saleState == SaleState.not_started) {
            blueprints[blueprintID].claimedWhitelistedPieces[msg.sender] = true;
        }

        _mintQuantity(blueprintID, quantity, msg.sender);
    }

    function preSaleMint(uint256 blueprintID, uint32 quantity) external {
        require(
            _isBlueprintPreparedAndNotStarted(blueprintID),
            "Must be prepared and not started"
        );
        require(
            minterAddress == msg.sender ||
                blueprints[blueprintID].artist == msg.sender,
            "user cannot mint presale"
        );

        if (minterAddress == msg.sender) {
            require(
                quantity <= blueprints[blueprintID].mintAmountPlatform,
                "cannot mint quantity"
            );
            blueprints[blueprintID].mintAmountPlatform -= quantity;
        } else if (blueprints[blueprintID].artist == msg.sender) {
            require(
                quantity <= blueprints[blueprintID].mintAmountArtist,
                "cannot mint quantity"
            );
            blueprints[blueprintID].mintAmountArtist -= quantity;
        }
        _mintQuantity(blueprintID, quantity, msg.sender);
    }

    /*
     * Iterate and mint each blueprint for user
     */
    function _mintQuantity(uint256 _blueprintID, uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprints[_blueprintID].erc721TokenIndex;
        uint64 newCap = blueprints[_blueprintID].capacity;
        for (uint16 i = 0; i < _quantity; i++) {
            require(newCap > 0, "blueprint out of capacity");
            
            _mint(_nftRecipient, newTokenId + i);
            tokenToBlueprintID[newTokenId + i] = _blueprintID;

            bytes32 prefixHash = keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.coinbase,
                    newCap
                )
            );
            emit BlueprintMinted(
                _blueprintID,
                blueprints[_blueprintID].artist,
                _nftRecipient,
                newTokenId + i,
                newCap,
                prefixHash
            );
            --newCap;
        }

        blueprints[_blueprintID].erc721TokenIndex += _quantity;
        blueprints[_blueprintID].capacity = newCap;
    }

    function _confirmPaymentAmountAndSettleSale(
        uint256 _blueprintID,
        uint32 _quantity,
        uint256 _tokenAmount,
        address _artist
    ) internal {
        address _erc20Token = blueprints[_blueprintID].ERC20Token;
        uint128 _price = blueprints[_blueprintID].price;
        if (_erc20Token == address(0)) {
            require(_tokenAmount == 0, "cannot specify token amount");
            require(
                msg.value == _quantity * _price,
                "Purchase amount must match price"
            );
            _payFeesAndArtist(_blueprintID, _erc20Token, msg.value, _artist);
        } else {
            require(msg.value == 0, "cannot specify eth amount");
            require(
                _tokenAmount == _quantity * _price,
                "Purchase amount must match price"
            );

            IERC20(_erc20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            _payFeesAndArtist(_blueprintID, _erc20Token, _tokenAmount, _artist);
        }
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * Create a merkle tree with address: quantity pairs as the leaves.
     * The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     */

    function _leaf(address account, uint256 quantity)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, quantity));
    }

    function _verify(
        bytes32 leaf,
        bytes32 merkleroot,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    function updateBlueprintTokenUri(
        uint256 blueprintID,
        string memory newBaseTokenUri
    ) external onlyRole(MINTER_ROLE) isBlueprintPrepared(blueprintID) {
        require(
            !blueprints[blueprintID].tokenUriLocked,
            "blueprint URI locked"
        );

        blueprints[blueprintID].baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(blueprintID, newBaseTokenUri);
    }

    function lockBlueprintTokenUri(uint256 blueprintID)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isBlueprintPrepared(blueprintID)
    {
        require(
            !blueprints[blueprintID].tokenUriLocked,
            "blueprint URI locked"
        );

        blueprints[blueprintID].tokenUriLocked = true;
    }

    function _baseURIForBlueprint(uint256 tokenId) internal view returns (string memory) {
        return blueprints[tokenToBlueprintID[tokenId]].baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURIForBlueprint(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        tokenId.toString(),
                        "/",
                        "token.json"
                    )
                )
                : "";
    }

    function revealBlueprintSeed(uint256 blueprintID, string memory randomSeed)
        external
        onlyRole(MINTER_ROLE)
        isBlueprintPrepared(blueprintID)
    {
        emit BlueprintSeed(blueprintID, randomSeed);
    }

    function setAsyncFeeRecipient(address _asyncSaleFeesRecipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        asyncSaleFeesRecipient = _asyncSaleFeesRecipient;
    }

    function changeDefaultPlatformPrimaryFeePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints <= 10000);
        defaultPlatformPrimaryFeePercentage = _basisPoints;
    }

    function changeDefaultBlueprintSecondarySalePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints + defaultPlatformSecondarySalePercentage <= 10000);
        defaultBlueprintSecondarySalePercentage = _basisPoints;
    }

    function changeDefaultPlatformSecondarySalePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _basisPoints + defaultBlueprintSecondarySalePercentage <= 10000
        );
        defaultPlatformSecondarySalePercentage = _basisPoints;
    }

    function updatePlatformAddress(address _platform)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    // Allows the platform to change the minter address
    function updateMinterAddress(address newMinterAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, newMinterAddress);

        revokeRole(MINTER_ROLE, minterAddress);
        minterAddress = newMinterAddress;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    function _payFeesAndArtist(
        uint256 _blueprintID,
        address _erc20Token,
        uint256 _amount,
        address _artist
    ) internal {
        address[] memory _primaryFeeRecipients = getPrimaryFeeRecipients(
            _blueprintID
        );
        uint32[] memory _primaryFeeBPS = getPrimaryFeeBps(_blueprintID);
        uint256 feesPaid;

        for (uint256 i = 0; i < _primaryFeeRecipients.length; i++) {
            uint256 fee = _getFeePortion(_amount, _primaryFeeBPS[i]);
            feesPaid = feesPaid + fee;
            _payout(_primaryFeeRecipients[i], _erc20Token, fee);
        }
        if (_amount - feesPaid > 0) {
            _payout(_artist, _erc20Token, (_amount - feesPaid));
        }
    }

    function _payout(
        address _recipient,
        address _erc20Token,
        uint256 _amount
    ) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    function withdrawAllFailedCredits(address payable recipient) external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = recipient.call{value: amount, gas: 20000}(
            ""
        );
        require(successfulWithdraw, "withdraw failed");
    }

    function getPrimaryFeeRecipients(uint256 id)
        public
        view
        returns (address[] memory)
    {
        if (blueprints[id].primaryFeeRecipients.length == 0) {
            address[] memory primaryFeeRecipients = new address[](1);
            primaryFeeRecipients[0] = (asyncSaleFeesRecipient);
            return primaryFeeRecipients;
        } else {
            return blueprints[id].primaryFeeRecipients;
        }
    }

    function getPrimaryFeeBps(uint256 id)
        public
        view
        returns (uint32[] memory)
    {
        if (blueprints[id].primaryFeeBPS.length == 0) {
            uint32[] memory primaryFeeBPS = new uint32[](1);
            primaryFeeBPS[0] = defaultPlatformPrimaryFeePercentage;

            return primaryFeeBPS;
        } else {
            return blueprints[id].primaryFeeBPS;
        }
    }

    function getFeeRecipients(uint256 id)
        public
        view
        override
        returns (address[] memory)
    {
        if (blueprints[id].secondaryFeeRecipients.length == 0) {
            address[] memory feeRecipients = new address[](2);
            feeRecipients[0] = (asyncSaleFeesRecipient);
            feeRecipients[1] = (blueprints[id].artist);

            return feeRecipients;
        } else {
            return blueprints[id].secondaryFeeRecipients;
        }
    }

    function getFeeBps(uint256 id)
        public
        view
        override
        returns (uint32[] memory)
    {
        if (blueprints[id].secondaryFeeBPS.length == 0) {
            uint32[] memory feeBPS = new uint32[](2);
            feeBPS[0] = defaultPlatformSecondarySalePercentage;
            feeBPS[1] = defaultBlueprintSecondarySalePercentage;

            return feeBPS;
        } else {
            return blueprints[id].secondaryFeeBPS;
        }
    }

    ////////////////////////////////////
    /// Required function overide //////
    ////////////////////////////////////

    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(account, operator) ||
            hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC165StorageUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }
}
