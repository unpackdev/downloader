// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721AUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OperatorFiltererUpgradeable.sol";
import "./LibPRNG.sol";
import "./Base64.sol";
import "./SSTORE2.sol";
import "./DynamicBuffer.sol";
import "./HelperLib.sol";
import "./MerkleProof.sol";
import "./IIndelibleSecurity.sol";
import "./IDelegateRegistry.sol";
import "./ICommon.sol";

/*

  _  _ _____ __  ____     _    ____  __  __    _    ____    _    
 | || |___  / /_|___ \   / \  |  _ \|  \/  |  / \  |  _ \  / \   
 | || |_ / / '_ \ __) | / _ \ | |_) | |\/| | / _ \ | | | |/ _ \  
 |__   _/ /| (_) / __/ / ___ \|  _ <| |  | |/ ___ \| |_| / ___ \ 
    |_|/_/  \___/_____/_/   \_\_| \_\_|  |_/_/   \_\____/_/   \_\
                                                                
*/

struct LinkedTraitDTO {
    uint256[] traitA;
    uint256[] traitB;
}

struct TraitDTO {
    string name;
    string mimetype;
    uint256 occurrence;
    bytes data;
    bool hide;
    bool useExistingData;
    uint256 existingDataIndex;
}

struct Trait {
    string name;
    string mimetype;
    uint256 occurrence;
    address dataPointer;
    bool hide;
}

struct Layer {
    string name;
    uint256 primeNumber;
    uint256 numberOfTraits;
}

struct Settings {
    bool isContractSealed;
    string description;
}

struct ClaimCondition {
    uint256 startTimestamp;
    uint256 maxClaimableSupply;
    uint256 supplyClaimed;
    uint256 quantityLimitPerWallet;
    bytes32 merkleRoot;
    uint256 pricePerToken;
    string metadata;
}

struct IntelectualPropertySignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct AllowlistProof {
    bytes32[] proof;
    uint256 quantityLimitPerWallet;
    uint256 pricePerToken;
}

contract IndelibleGenerative is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    OperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable
{
    using HelperLib for string;
    using DynamicBuffer for bytes;
    using LibPRNG for LibPRNG.PRNG;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    mapping(uint256 => Layer) private layers;
    mapping(uint256 => mapping(uint256 => Trait)) private traits;
    mapping(uint256 => mapping(uint256 => uint256[])) private linkedTraits;
    mapping(uint256 => bool) private renderTokenOffChain;
    mapping(uint256 => string) private hashOverride;
    mapping(address => uint256) private latestBlockNumber;

    address private indelibleSecurity;
    bool private shouldWrapSVG = true;
    uint256 private revealSeed;
    uint256 private numberOfLayers;

    string public baseURI;
    uint256 public maxSupply;
    Settings public settings;

    address public punk4762;
    string public ipURI;
    IntelectualPropertySignature public ipSignature;

    address private royaltyAddress;

    address private constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The active conditions for claiming tokens.
    ClaimCondition public claimCondition;

    /// @dev The ID for the active claim condition.
    bytes32 private conditionId;

    ///  @dev Map from a claim condition uid and account to supply claimed by account.
    mapping(bytes32 => mapping(address => uint256))
        private supplyClaimedByWallet;

    string private placeholderImage;

    modifier whenUnsealed() {
        if (settings.isContractSealed) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyPunk4762() {
        require(msg.sender == punk4762, "NotAuthorized");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /** @dev initialize from factory */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        Settings calldata _settings,
        RoyaltySettings calldata _royaltySettings,
        FactorySettings calldata _factorySettings
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();

        maxSupply = _maxSupply;

        settings = _settings;
        settings.isContractSealed = false;
        indelibleSecurity = _factorySettings.indelibleSecurity;

        _setDefaultRoyalty(
            _royaltySettings.royaltyAddress,
            _royaltySettings.royaltyAmount
        );

        royaltyAddress = _royaltySettings.royaltyAddress;

        transferOwnership(_factorySettings.deployer);

        placeholderImage = "https://www.4762armada.com/Twerk_PFP_pre_reveal_";

        OperatorFiltererUpgradeable.__OperatorFilterer_init(
            _factorySettings.operatorFilter,
            _factorySettings.operatorFilter != address(0) // only subscribe if a filter is provided
        );
    }

    /**
     *  @dev Lets a contract owner set claim conditions.
     * */

    function setClaimConditions(
        ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) public onlyOwner nonReentrant {
        bytes32 targetConditionId = conditionId;
        uint256 supplyClaimedAlready = claimCondition.supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(
                abi.encodePacked(msg.sender, block.number)
            );
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        claimCondition = ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerWallet: _condition.quantityLimitPerWallet,
            merkleRoot: _condition.merkleRoot,
            pricePerToken: _condition.pricePerToken,
            metadata: _condition.metadata
        });

        conditionId = targetConditionId;
    }

    function intelectualPropertySignature(
        string memory _ipURI,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyPunk4762 whenUnsealed {
        ipURI = _ipURI;
        ipSignature = IntelectualPropertySignature(r, s, v);
    }

    function setIPSigner(address _punk4762) public onlyOwner {
        punk4762 = _punk4762;
    }

    function mint(
        address _receiver,
        uint256 _quantity,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof
    ) external payable nonReentrant {
        address claimer = msg.sender;

        /// @dev Delegate.xyz implementation
        if (_receiver != address(0) && _receiver != claimer) {
            if (
                IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493)
                    .checkDelegateForContract(
                        _receiver,
                        msg.sender,
                        address(this),
                        "0x"
                    )
            ) {
                // update the claimer if delegation is true
                claimer = _receiver;
            }
        }

        verifyMint(claimer, _quantity, _pricePerToken, _allowlistProof);

        bytes32 activeConditionId = conditionId;

        // Update contract state.
        claimCondition.supplyClaimed += _quantity;
        supplyClaimedByWallet[activeConditionId][claimer] += _quantity;

        // Mint the relevant NFTs to claimer.
        handleMint(_quantity, claimer);
    }

    /**
     * @dev Checks a request to claim NFTs against the active claim condition's criteria.
     */
    function verifyMint(
        address _claimer,
        uint256 _quantity,
        uint256 _pricePerToken,
        AllowlistProof calldata _allowlistProof
    ) internal returns (bool isOverride) {
        // Get the current claimCondition
        ClaimCondition memory currentClaimPhase = claimCondition;

        // Get the public limit per wallet
        uint256 claimLimit = currentClaimPhase.quantityLimitPerWallet;

        // Get the public mint price per token
        uint256 claimPrice = currentClaimPhase.pricePerToken;

        // set the claim currency always to eth
        address claimCurrency = address(0);

        // If the merkleRoot not empty, we got a current claim phase with allowlist
        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            // check if is in the allowlist
            (isOverride, ) = MerkleProof.verify(
                _allowlistProof.proof,
                currentClaimPhase.merkleRoot,
                keccak256(
                    abi.encodePacked(
                        _claimer,
                        _allowlistProof.quantityLimitPerWallet,
                        _allowlistProof.pricePerToken
                    )
                )
            );
        }

        /// @dev if true have to override claimLimit and claimPrice,
        /// @dev if false, this is a public mint and we keep limit and price from claim condition
        if (isOverride) {
            claimLimit = _allowlistProof.quantityLimitPerWallet != 0
                ? _allowlistProof.quantityLimitPerWallet
                : claimLimit;
            claimPrice = _allowlistProof.pricePerToken != type(uint256).max
                ? _allowlistProof.pricePerToken
                : claimPrice;
            claimCurrency = address(0);
        }

        /// @dev get the supply for this address
        uint256 _supplyClaimedByWallet = supplyClaimedByWallet[conditionId][
            _claimer
        ];

        /// @dev must rever, the tx is sending a price that is diferent from the allowlist or the current claim phase
        if (claimPrice * _quantity != msg.value) {
            revert("InvalidValue");
        }

        /// @dev must rever, the tx is sending a price that is diferent from the allowlist or the current claim phase
        if (_pricePerToken != claimPrice) {
            revert("!Price");
        }

        /// @dev 0 = nothing to mint || the requested mint qty + the current supply already claimed is more than the claim limit
        if (
            _quantity == 0 || (_quantity + _supplyClaimedByWallet > claimLimit)
        ) {
            revert("!Qty");
        }

        if (
            currentClaimPhase.supplyClaimed + _quantity >
            currentClaimPhase.maxClaimableSupply ||
            currentClaimPhase.supplyClaimed + _quantity > maxSupply
        ) {
            revert("!MaxSupply");
        }

        if (currentClaimPhase.startTimestamp > block.timestamp) {
            revert("cant claim yet");
        }
    }

    function handleMint(uint256 quantity, address recipient) internal {
        uint256 batchQuantity = quantity / 20;
        uint256 remainder = quantity % 20;

        for (uint256 i = 0; i < batchQuantity; ) {
            _mint(recipient, 20);
            unchecked {
                ++i;
            }
        }

        if (remainder > 0) {
            _mint(recipient, remainder);
        }
    }

    /**
     * @dev call this function to reveal tokens
     */
    function setRevealSeed() external onlyOwner {
        if (revealSeed != 0) {
            revert NotAuthorized();
        }
        revealSeed = uint256(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );

        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function isRevealed() public view returns (bool) {
        return revealSeed != 0;
    }

    /**
     * @dev Send contract balance to trasury address
     */

    function withdraw() external onlyOwner nonReentrant {
        AddressUpgradeable.sendValue(
            payable(royaltyAddress),
            address(this).balance
        );
    }

    /**
     * @dev Token Data functions
     */

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidInput();
        }

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);

        jsonBytes.appendSafe(
            abi.encodePacked(
                '{"name":"',
                name(),
                " #",
                _toString(tokenId),
                '","description":"',
                settings.description,
                '",'
            )
        );

        if (revealSeed == 0) {
            jsonBytes.appendSafe(
                abi.encodePacked('"animation_url":"', placeholderImage, '"}')
            );
        } else {
            string memory tokenHash = tokenIdToHash(tokenId);

            if (bytes(baseURI).length > 0 && renderTokenOffChain[tokenId]) {
                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"image":"',
                        baseURI,
                        _toString(tokenId),
                        "?dna=",
                        tokenHash,
                        "&networkId=",
                        _toString(block.chainid),
                        '",'
                    )
                );
            } else {
                string memory svgCode = "";
                if (shouldWrapSVG) {
                    string memory svgString = hashToSVG(tokenHash);
                    svgCode = string(
                        abi.encodePacked(
                            "data:image/svg+xml;base64,",
                            Base64.encode(
                                abi.encodePacked(
                                    '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                    svgString,
                                    '"></image></svg>'
                                )
                            )
                        )
                    );
                } else {
                    svgCode = hashToSVG(tokenHash);
                }

                jsonBytes.appendSafe(
                    abi.encodePacked('"image_data":"', svgCode, '",')
                );
            }

            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"attributes":',
                    hashToMetadata(tokenHash),
                    "}"
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(jsonBytes)
                )
            );
    }

    function tokenIdToSVG(uint256 tokenId) public view returns (string memory) {
        return
            revealSeed == 0
                ? placeholderImage
                : hashToSVG(tokenIdToHash(tokenId));
    }

    /**
     * @dev from a token id you can get a hash to query metadata and svg
     */

    function tokenIdToHash(
        uint256 tokenId
    ) public view returns (string memory) {
        if (revealSeed == 0 || !_exists(tokenId)) {
            revert NotAvailable();
        }
        if (bytes(hashOverride[tokenId]).length > 0) {
            return hashOverride[tokenId];
        }
        bytes memory hashBytes = DynamicBuffer.allocate(numberOfLayers * 4);
        uint256 tokenDataId = getTokenDataId(tokenId);

        uint256[] memory hash = new uint256[](numberOfLayers);
        bool[] memory modifiedLayers = new bool[](numberOfLayers);
        uint256 traitSeed = revealSeed % maxSupply;

        for (uint256 i = 0; i < numberOfLayers; ) {
            uint256 traitIndex = hash[i];
            if (modifiedLayers[i] == false) {
                uint256 traitRangePosition = ((tokenDataId + i + traitSeed) *
                    layers[i].primeNumber) % maxSupply;
                traitIndex = rarityGen(i, traitRangePosition);
                hash[i] = traitIndex;
            }

            if (linkedTraits[i][traitIndex].length > 0) {
                hash[linkedTraits[i][traitIndex][0]] = linkedTraits[i][
                    traitIndex
                ][1];
                modifiedLayers[linkedTraits[i][traitIndex][0]] = true;
            }
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < hash.length; ) {
            if (hash[i] < 10) {
                hashBytes.appendSafe("00");
            } else if (hash[i] < 100) {
                hashBytes.appendSafe("0");
            }
            if (hash[i] > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(hash[i])));
            }
            unchecked {
                ++i;
            }
        }

        return string(hashBytes);
    }

    function setHashOverride(
        uint256 tokenId,
        string calldata tokenHash
    ) external whenUnsealed onlyOwner {
        hashOverride[tokenId] = tokenHash;
    }

    function rarityGen(
        uint256 layerIndex,
        uint256 randomInput
    ) internal view returns (uint256) {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < layers[layerIndex].numberOfTraits; ) {
            uint256 thisPercentage = traits[layerIndex][i].occurrence;
            if (
                randomInput >= currentLowerBound &&
                randomInput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
            unchecked {
                ++i;
            }
        }

        revert("");
    }

    function getTokenDataId(uint256 tokenId) internal view returns (uint256) {
        uint256[] memory indices = new uint256[](maxSupply);

        for (uint256 i; i < maxSupply; ) {
            indices[i] = i;
            unchecked {
                ++i;
            }
        }

        LibPRNG.PRNG memory prng;
        prng.seed(revealSeed);
        prng.shuffle(indices);

        return indices[tokenId];
    }

    /**
     * @dev Will return svg from token hash, can get hash from tokenIdToHash
     */

    function hashToSVG(
        string memory _hash
    ) public view returns (string memory) {
        uint256 thisTraitIndex;

        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe(
            '<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-image:url('
        );

        for (uint256 i = 0; i < numberOfLayers - 1; ) {
            thisTraitIndex = _hash.subStr((i * 3), (i * 3) + 3).parseInt();
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    traits[i][thisTraitIndex].mimetype,
                    ";base64,",
                    Base64.encode(
                        SSTORE2.read(traits[i][thisTraitIndex].dataPointer)
                    ),
                    "),url("
                )
            );
            unchecked {
                ++i;
            }
        }

        thisTraitIndex = _hash
            .subStr((numberOfLayers * 3) - 3, numberOfLayers * 3)
            .parseInt();

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                traits[numberOfLayers - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(
                    SSTORE2.read(
                        traits[numberOfLayers - 1][thisTraitIndex].dataPointer
                    )
                ),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svgBytes)
                )
            );
    }

    /**
     * @dev Will return metadata from token hash,  can get hash from tokenIdToHash
     */

    function hashToMetadata(
        string memory _hash
    ) public view returns (string memory) {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");
        bool afterFirstTrait;

        for (uint256 i = 0; i < numberOfLayers; ) {
            uint256 thisTraitIndex = _hash
                .subStr((i * 3), (i * 3) + 3)
                .parseInt();
            if (traits[i][thisTraitIndex].hide == false) {
                if (afterFirstTrait) {
                    metadataBytes.appendSafe(",");
                }
                metadataBytes.appendSafe(
                    abi.encodePacked(
                        '{"trait_type":"',
                        layers[i].name,
                        '","value":"',
                        traits[i][thisTraitIndex].name,
                        '"}'
                    )
                );
                if (afterFirstTrait == false) {
                    afterFirstTrait = true;
                }
            }

            if (i == numberOfLayers - 1) {
                metadataBytes.appendSafe("]");
            }

            unchecked {
                ++i;
            }
        }

        return string(metadataBytes);
    }

    /**
     * @dev Layer and traits functions
     */

    function addLayer(
        uint256 index,
        string calldata name,
        uint256 primeNumber,
        TraitDTO[] calldata _traits,
        uint256 _numberOfLayers
    ) public onlyOwner whenUnsealed {
        layers[index] = Layer(name, primeNumber, _traits.length);
        numberOfLayers = _numberOfLayers;
        for (uint256 i = 0; i < _traits.length; ) {
            address dataPointer;
            if (_traits[i].useExistingData) {
                dataPointer = traits[index][_traits[i].existingDataIndex]
                    .dataPointer;
            } else {
                dataPointer = SSTORE2.write(_traits[i].data);
            }
            traits[index][i] = Trait(
                _traits[i].name,
                _traits[i].mimetype,
                _traits[i].occurrence,
                dataPointer,
                _traits[i].hide
            );
            unchecked {
                ++i;
            }
        }
        return;
    }

    function addTraitsToLayer(
        uint256 layerIndex,
        TraitDTO[] calldata _traits
    ) public onlyOwner whenUnsealed {
        require(layerIndex < numberOfLayers, "Invalid layer index");

        Layer storage layer = layers[layerIndex];

        for (uint256 i = 0; i < _traits.length; i++) {
            address dataPointer;
            if (_traits[i].useExistingData) {
                require(
                    _traits[i].existingDataIndex < layer.numberOfTraits,
                    "Invalid existing data index"
                );
                dataPointer = traits[layerIndex][_traits[i].existingDataIndex]
                    .dataPointer;
            } else {
                dataPointer = SSTORE2.write(_traits[i].data);
            }

            traits[layerIndex][layer.numberOfTraits + i] = Trait(
                _traits[i].name,
                _traits[i].mimetype,
                _traits[i].occurrence,
                dataPointer,
                _traits[i].hide
            );
        }

        layer.numberOfTraits += _traits.length;
    }

    /**
     * @dev add a single trait to a layer, in case add layer tx is too big
     * */

    function addTrait(
        uint256 layerIndex,
        uint256 traitIndex,
        TraitDTO calldata _trait
    ) public onlyOwner whenUnsealed {
        address dataPointer;
        if (_trait.useExistingData) {
            dataPointer = traits[layerIndex][traitIndex].dataPointer;
        } else {
            dataPointer = SSTORE2.write(_trait.data);
        }
        traits[layerIndex][traitIndex] = Trait(
            _trait.name,
            _trait.mimetype,
            _trait.occurrence,
            dataPointer,
            _trait.hide
        );
        return;
    }

    /**
     *  @dev Link traits from diferent layers
     */

    function setLinkedTraits(
        LinkedTraitDTO[] calldata _linkedTraits
    ) public onlyOwner whenUnsealed {
        for (uint256 i = 0; i < _linkedTraits.length; ) {
            linkedTraits[_linkedTraits[i].traitA[0]][
                _linkedTraits[i].traitA[1]
            ] = [_linkedTraits[i].traitB[0], _linkedTraits[i].traitB[1]];
            unchecked {
                ++i;
            }
        }
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;

        if (_totalMinted() > 0) {
            emit BatchMetadataUpdate(0, _totalMinted() - 1);
        }
    }

    function sealContract() external whenUnsealed onlyOwner {
        settings.isContractSealed = true;
    }

    function setPlaceholderImage(
        string calldata _placeholderImage
    ) external onlyOwner {
        placeholderImage = _placeholderImage;
    }

    function traitDetails(
        uint256 layerIndex,
        uint256 traitIndex
    ) public view returns (Trait memory) {
        return traits[layerIndex][traitIndex];
    }

    function traitData(
        uint256 layerIndex,
        uint256 traitIndex
    ) public view returns (bytes memory) {
        return SSTORE2.read(traits[layerIndex][traitIndex].dataPointer);
    }

    /**
     * @dev supportsInterface override
     */

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
