// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC165StorageUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProof.sol";

import "./NonblockingLzAppUpgradeable.sol";

import "./IAPMorgan.types.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./HasSecondarySaleFees.sol";

import "./SettableCountersUpgradeable.sol";
import "./APMorganMinter.sol";

contract APMorgan is
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable,
    IAPMorganTypes,
    ILayerZeroReceiver,
    NonblockingLzAppUpgradeable,
    HasSecondarySaleFees
{
    using SettableCountersUpgradeable for SettableCountersUpgradeable.Counter;

    /// LayerZero gas value for bridging
    uint256 lzGas;

    /// token id counter
    SettableCountersUpgradeable.Counter _tokenIdCounter;

    /// Mapping of layer combination to used status
    mapping(bytes32 => bool) public layerComboUsed;

    //. Mapping of token id to layer and source chain information
    mapping(uint256 => LayerData) public tokenLayers;

    /// Preminted token data for vrf
    mapping(uint256 => PremintedTokenData) public premintedTokens;

    /// Mapping of greenlisted user to mint claimed
    mapping(address => bool) public claimed;

    /// Mapping from owner address to owner's preferred token (pfp)
    mapping(address => uint256) public preferredToken;

    /// Greenlist merkle root
    bytes32 public merkleRoot;

    /// chain specific starting index (used for reading offchain)
    uint16 public startIndex;

    /// chain specific end index
    uint16 public endIndex;

    /// num of assets per layer
    LayerCounts public layerCounts;

    APMorganMinter apMorganMinter;

    uint256 public vrfPaymentContribution;

    ///Secondary Sales Fees:

    address public saleFeesRecipient;

    uint32 public secondarySalePercentage;

    uint256 constant basisPointsDenominator = 10_000;

    /// Roles
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GREENLIST_ADMIN_ROLE =
        keccak256("GREENLIST_ADMIN_ROLE");

    /// cross chain event
    event ReceiveNFT(uint16 _srcChainId, address _from, uint256 _tokenId);

    modifier isTokenOwnerOrApproved(uint256 tokenId) {
        require(
            msg.sender == ownerOf(tokenId) ||
                getApproved(tokenId) == msg.sender,
            "Not the owner or approved"
        );
        _;
    }

    // auto initialize implementation for production environment - require explicitly stating if contract is for testing.
    constructor(bool isTestingContract) {
        if (!isTestingContract) {
            //// @custom:oz-upgrades-unsafe-allow constructor
            _disableInitializers();
        }
    }

    /// @notice initialize A.P Morgan Sailing Club contract
    /// @param _endpoint - the source chain endpoint for LayerZero implementation
    /// @param admin - admin account address
    /// @param _startIndex - index for the first token mintable for a specific chain
    /// @param _endIndex - index for the last token mintable for a specific chain
    /// @param root - greenlist merkle root
    /// @param numl2 - layer 2 identifier
    /// @param numl3 - layer 3 identifier
    /// @param numl4 - layer 4 identifier
    /// @param numl5 - layer 5 identifier
    /// @param numl6 - layer 6 identifier
    /// @param _vrfPaymentContribution - native token payment amount for randomness subsidy
    function initialize(
        address _endpoint,
        address admin,
        uint16 _startIndex,
        uint16 _endIndex,
        bytes32 root,
        uint8 numl2,
        uint8 numl3,
        uint8 numl4,
        uint8 numl5,
        uint8 numl6,
        uint256 _vrfPaymentContribution,
        address _apMorganMinter
    ) public initializer {
        __ERC721_init("A.P. Morgan Sailing Club", "APM");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(GREENLIST_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, _apMorganMinter);

        __NonblockingLzAppUpgradeable_init_unchained(_endpoint);

        lzGas = 500_000; // sufficiently high

        HasSecondarySaleFees._initialize();

        // start ids from for sensible preferredToken mapping deletion.
        _tokenIdCounter.set(_startIndex);

        layerCounts = LayerCounts({
            numImagesLayer2: numl2,
            numImagesLayer3: numl3,
            numImagesLayer4: numl4,
            numImagesLayer5: numl5,
            numImagesLayer6: numl6
        });

        merkleRoot = root;

        startIndex = _startIndex;
        endIndex = _endIndex;

        vrfPaymentContribution = _vrfPaymentContribution;
        apMorganMinter = APMorganMinter(_apMorganMinter);
    }

    /// @notice public mint function using a proof
    /// @param proof - proof used to give minting permission
    /// @param layer2 - unique layer 2
    /// @param layer3 - unique layer 3
    /// @param layer4 - unique layer 4
    /// @param layer5 - unique layer 5
    /// @param layer6 - unique layer 6
    function mintGreenList(
        bytes32[] calldata proof,
        uint8 layer2,
        uint8 layer3,
        uint8 layer4,
        uint8 layer5,
        uint8 layer6
    ) external payable {
        require(
            msg.value == vrfPaymentContribution,
            "Incorrect randomness subsidy"
        );
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not greenlisted!"
        );
        require(!claimed[msg.sender], "Already claimed!");
        claimed[msg.sender] = true;
        require(
            layer2 < layerCounts.numImagesLayer2 &&
                layer3 < layerCounts.numImagesLayer3 &&
                layer4 < layerCounts.numImagesLayer4 &&
                layer5 < layerCounts.numImagesLayer5 &&
                layer6 < layerCounts.numImagesLayer6,
            "Layers out of bounds!"
        );
        validateUniqueness(
            block.chainid,
            layer2,
            layer3,
            layer4,
            layer5,
            layer6
        );
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= endIndex, "Max supply reached for chain!");
        _tokenIdCounter.increment();

        uint256 s_requestId = apMorganMinter.sendVrfRequest{value: msg.value}();

        premintedTokens[s_requestId] = PremintedTokenData({
            layer2: layer2,
            layer3: layer3,
            layer4: layer4,
            layer5: layer5,
            layer6: layer6,
            tokenId: uint96(tokenId),
            owner: msg.sender
        });
    }

    /// @notice first time minting of A.P. Morgan (internal)
    /// @param requestId - vrf requestId
    /// @param randomLayer0 - first random layer
    /// @param randomLayer1 - second random layer
    function mintAPMorgan(
        uint256 requestId,
        uint8 randomLayer0,
        uint8 randomLayer1
    ) external onlyRole(MINTER_ROLE) {
        PremintedTokenData memory tokenData = premintedTokens[requestId];
        // Once data read and fulfilled delete storage to get some gas back 😊
        delete premintedTokens[requestId];

        if (balanceOf(tokenData.owner) == 0) {
            preferredToken[tokenData.owner] = tokenData.tokenId;
        }

        tokenLayers[tokenData.tokenId] = LayerData(
            randomLayer0,
            randomLayer1,
            tokenData.layer2,
            tokenData.layer3,
            tokenData.layer4,
            tokenData.layer5,
            tokenData.layer6,
            uint200(block.chainid)
        );

        emit TokenLayersDetermined(
            tokenData.tokenId,
            block.chainid,
            randomLayer0,
            randomLayer1,
            tokenData.layer2,
            tokenData.layer3,
            tokenData.layer4,
            tokenData.layer5,
            tokenData.layer6
        );
        //Uses _mint over _safeMint as this function should not revert
        _mint(tokenData.owner, tokenData.tokenId);
    }

    function getTokenUniquenessKey(
        uint256 originatingChainId,
        uint8 layer2,
        uint8 layer3,
        uint8 layer4,
        uint8 layer5,
        uint8 layer6
    ) public pure returns (bytes32) {
        return
            bytes32(
                abi.encodePacked(
                    uint16(0), /* a space for the 2 randomly generated layers -- useful for future coversion from the full token data to user selected and packed layers via 'AND'/& and a bitmask*/
                    layer2,
                    layer3,
                    layer4,
                    layer5,
                    layer6,
                    uint200(originatingChainId)
                )
            );
    }

    /// @notice ensures each layer combination is unique (accompanied by the chain id minted on)
    /// @param originatingChainId - chain id of orginally minted token
    /// @param layer2 - unique layer 2
    /// @param layer3 - unique layer 3
    /// @param layer4 - unique layer 4
    /// @param layer5 - unique layer 5
    /// @param layer6 - unique layer 6
    /// @dev virtual for mock contracts for testing lz ignoring originatingChainId
    function validateUniqueness(
        uint256 originatingChainId,
        uint8 layer2,
        uint8 layer3,
        uint8 layer4,
        uint8 layer5,
        uint8 layer6
    ) internal virtual {
        bytes32 combo = getTokenUniquenessKey(
            originatingChainId,
            layer2,
            layer3,
            layer4,
            layer5,
            layer6
        );

        require(!layerComboUsed[combo], "Non unique mint!");
        layerComboUsed[combo] = true;
    }

    /// @notice function to transfer the token from one chain to another
    /// @param _dstChainId - the layer zero unique chain id
    /// @param tokenId - id of token to bridge
    /// @param receiver - receiving address relevant for smart contract transferring cross chain when it likely doesnt exist on the other chain
    function transferCrossChain(
        uint16 _dstChainId,
        uint256 tokenId,
        address receiver
    ) external payable isTokenOwnerOrApproved(tokenId) {
        // burn NFT
        _burn(tokenId);

        LayerData memory tokenLayersCrossChain = tokenLayers[tokenId];

        bytes memory payload = abi.encode(
            receiver,
            tokenId,
            tokenLayersCrossChain.originatingChainId,
            tokenLayersCrossChain.randomLayer0,
            tokenLayersCrossChain.randomLayer1,
            tokenLayersCrossChain.layer2,
            tokenLayersCrossChain.layer3,
            tokenLayersCrossChain.layer4,
            tokenLayersCrossChain.layer5,
            tokenLayersCrossChain.layer6
        );

        bytes memory adapterParams = abi.encodePacked(uint16(1), lzGas); // version, lzgas
        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(msg.value >= messageFee, "To little to cover msgFee");

        _lzSend(
            _dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param - the source sending contract address from the source chain
    /// @param - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes encoded to be sent
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        (
            address toAddress,
            uint256 tokenId,
            uint256 originatingChainId,
            uint8 randomLayer0,
            uint8 randomLayer1,
            uint8 layer2,
            uint8 layer3,
            uint8 layer4,
            uint8 layer5,
            uint8 layer6
        ) = abi.decode(
                _payload,
                (
                    address,
                    uint256,
                    uint256,
                    uint8,
                    uint8,
                    uint8,
                    uint8,
                    uint8,
                    uint8,
                    uint8
                )
            );
        // mint the tokens
        _mintCrossChain(
            toAddress,
            tokenId,
            originatingChainId,
            randomLayer0,
            randomLayer1,
            layer2,
            layer3,
            layer4,
            layer5,
            layer6
        );
        emit ReceiveNFT(_srcChainId, toAddress, tokenId);
    }

    /// @notice unique mint function when being bridged via layerzero
    /// @param receiver - user who will receive token on receiving chain
    /// @param tokenId - token id to mint it with, note this can fall outside of the startIndex & endIndex of this chains contract
    /// @param originatingChainId - normal blockchain id where the token was originally minted
    /// @param randomLayer0 - unique random layer 0
    /// @param randomLayer1 - unique random layer 1
    /// @param layer2 - unique layer 2
    /// @param layer3 - unique layer 3
    /// @param layer4 - unique layer 4
    /// @param layer5 - unique layer 5
    /// @param layer6 - unique layer 6
    function _mintCrossChain(
        address receiver,
        uint256 tokenId,
        uint256 originatingChainId,
        uint8 randomLayer0,
        uint8 randomLayer1,
        uint8 layer2,
        uint8 layer3,
        uint8 layer4,
        uint8 layer5,
        uint8 layer6
    ) internal {
        if (balanceOf(receiver) == 0) preferredToken[receiver] = tokenId;

        tokenLayers[tokenId] = LayerData(
            randomLayer0,
            randomLayer1,
            layer2,
            layer3,
            layer4,
            layer5,
            layer6,
            uint200(originatingChainId)
        );
        //Using _mint over _safeMint as this function should not revert
        _mint(receiver, tokenId);
    }

    /// @notice after token transfer hook to remove currently set preferredToken
    /// @param from - sender
    /// @param to - receiver
    /// @param tokenId - token id to remove and set as preferred token
    function _afterTokenTransfer(
        address from, // is always the owner of the token
        address to,
        uint256 tokenId
    ) internal override {
        // if transfering token to self do nothing
        if (from == to) return;

        // if not a new mint && transferred token was owners preferred token
        if (from != address(0) && preferredToken[from] == tokenId) {
            if (balanceOf(from) > 0)
                // set preferred token to another that from owns
                preferredToken[from] = tokenOfOwnerByIndex(from, 0);
            else delete preferredToken[from];
        }

        if (to != address(0) && preferredToken[to] == 0) {
            preferredToken[to] = tokenId;
        }
    }

    /// @notice used for upgrading
    /// @param newImplementation - Address of new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /// @notice used for upgrading
    /// @param interfaceId - interface identifier for contract
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable,
            ERC165StorageUpgradeable
        )
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId);
    }

    /// @notice set the users preferred tokenId
    /// @param tokenId - id of token to set as pfp
    function setPreferredToken(uint256 tokenId)
        public
        isTokenOwnerOrApproved(tokenId)
    {
        preferredToken[ownerOf(tokenId)] = tokenId;
    }

    /// @notice Admin function to introduce new assets to layers
    /// @param numl2 - number of assets for layer 2
    /// @param numl3 - number of assets for layer 3
    /// @param numl4 - number of assets for layer 4
    /// @param numl5 - number of assets for layer 5
    /// @param numl6 - number of assets for layer 6
    function setNumberOfAssetsInLayer(
        uint8 numl2,
        uint8 numl3,
        uint8 numl4,
        uint8 numl5,
        uint8 numl6
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            numl2 >= layerCounts.numImagesLayer2 &&
                numl3 >= layerCounts.numImagesLayer3 &&
                numl4 >= layerCounts.numImagesLayer4 &&
                numl5 >= layerCounts.numImagesLayer5 &&
                numl6 >= layerCounts.numImagesLayer6,
            "Can't decrease layers"
        );
        layerCounts = LayerCounts({
            numImagesLayer2: numl2,
            numImagesLayer3: numl3,
            numImagesLayer4: numl4,
            numImagesLayer5: numl5,
            numImagesLayer6: numl6
        });
    }

    /// @notice Helper function for getting next tokenId
    function getTokenIdCounter() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Returns the base Uniform Resource Identifier (URI) for all tokens
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://morganning.float-nfts.com/";
    }

    //////////////////// ADMIN FUNCTIONS ////////////////////

    /// @notice update the mint greenlist by setting a new merkle root
    /// @param root - new greenlist merkle root
    function setMerkleRoot(bytes32 root)
        external
        virtual
        onlyRole(GREENLIST_ADMIN_ROLE)
    {
        merkleRoot = root;
    }

    function setFeeParams(address _saleFeesRecipient, uint32 _feeBasisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_feeBasisPoints <= basisPointsDenominator);
        secondarySalePercentage = _feeBasisPoints;
        saleFeesRecipient = _saleFeesRecipient;
    }

    function getFeeRecipients(uint256)
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory feeRecipients = new address[](1);
        feeRecipients[0] = saleFeesRecipient;

        return feeRecipients;
    }

    function getFeeBps(uint256) public view override returns (uint32[] memory) {
        uint32[] memory fees = new uint32[](1);
        fees[0] = secondarySalePercentage;

        return fees;
    }

    function setIndexes(uint16 _startIndex, uint16 _endIndex)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startIndex = _startIndex;
        endIndex = _endIndex;
    }

    function configurePaymentContributionAndLzGas(
        uint256 _vrfPaymentContribution,
        uint256 _lzGas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vrfPaymentContribution = _vrfPaymentContribution;
        lzGas = _lzGas;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}
