//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";

import "./INiftyForge721.sol";
import "./NFBaseModule.sol";
import "./INFModuleTokenURI.sol";
import "./INFModuleRenderTokenURI.sol";
import "./INFModuleWithRoyalties.sol";

import "./AstragladeUpgrade.sol";

import "./IERC2981Royalties.sol";

import "./Randomize.sol";
import "./Base64.sol";

/// @title PlanetsModule
/// @author Simon Fremaux (@dievardump)
contract PlanetsModule is
    Ownable,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleRenderTokenURI,
    INFModuleWithRoyalties
{
    // using ECDSA for bytes32;
    using Strings for uint256;
    using Randomize for Randomize.Random;

    uint256 constant SEED_BOUND = 1000000000;

    // emitted when planets are claimed
    event PlanetsClaimed(uint256[] tokenIds);

    // contract actually holding the planets
    address public planetsContract;

    // astraglade contract to claim ids from
    address public astragladeContract;

    // contract operator next to the owner
    address public contractOperator =
        address(0xD1edDfcc4596CC8bD0bd7495beaB9B979fc50336);

    // project base render URI
    string private _baseRenderURI;

    // whenever all images are uploaded on arweave/ipfs and
    // this flag allows to stop all update of images, scripts etc...
    bool public frozenMeta;

    // base image rendering URI
    // before all Planets are minted, images will be stored on our servers since
    // they need to be generated after minting
    // after all planets are minted, they will all be stored in a decentralized way
    // and the _baseImagesURI will be updated
    string private _baseImagesURI;

    // project description
    string internal _description;

    address[3] public feeRecipients = [
        0xe4657aF058E3f844919c3ee713DF09c3F2949447,
        0xb275E5aa8011eA32506a91449B190213224aEc1e,
        0xdAC81C3642b520584eD0E743729F238D1c350E62
    ];

    mapping(uint256 => bytes32) public planetSeed;

    // saving already taken seeds to ensure not reusing a seed
    mapping(uint256 => bool) public seedTaken;

    modifier onlyOperator() {
        require(isOperator(msg.sender), 'Not operator.');
        _;
    }

    function isOperator(address operator) public view returns (bool) {
        return owner() == operator || contractOperator == operator;
    }

    /// @dev Receive, for royalties
    receive() external payable {}

    /// @notice constructor
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    /// @param astragladeContract_ the contract holding the astraglades
    constructor(
        string memory contractURI_,
        address owner_,
        address planetsContract_,
        address astragladeContract_
    ) NFBaseModule(contractURI_) {
        planetsContract = planetsContract_;
        astragladeContract = astragladeContract_;

        if (address(0) != owner_) {
            transferOwnership(owner_);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleRenderTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        return royaltyInfo(msg.sender, tokenId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256)
        public
        view
        override
        returns (address receiver, uint256 basisPoint)
    {
        receiver = address(this);
        basisPoint = 1000;
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(msg.sender, tokenId);
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        (
            uint256 seed,
            uint256 astragladeSeed,
            uint256[] memory attributes
        ) = getPlanetData(tokenId);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Planet - ',
                            tokenId.toString(),
                            '","license":"CC BY-SA 4.0","description":"',
                            getDescription(),
                            '","created_by":"Fabin Rasheed","twitter":"@astraglade","image":"',
                            abi.encodePacked(
                                getBaseImageURI(),
                                tokenId.toString()
                            ),
                            '","seed":"',
                            seed.toString(),
                            abi.encodePacked(
                                '","astragladeSeed":"',
                                astragladeSeed.toString(),
                                '","attributes":[',
                                _generateJSONAttributes(attributes),
                                '],"animation_url":"',
                                _renderTokenURI(
                                    seed,
                                    astragladeSeed,
                                    attributes
                                ),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /// @notice function that returns a string that can be used to render the current token
    /// @param tokenId tokenId
    /// @return the URI to render token
    function renderTokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return renderTokenURI(msg.sender, tokenId);
    }

    /// @notice function that returns a string that can be used to render the current token
    /// @param tokenId tokenId
    /// @return the URI to render token
    function renderTokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        (
            uint256 seed,
            uint256 astragladeSeed,
            uint256[] memory attributes
        ) = getPlanetData(tokenId);

        return _renderTokenURI(seed, astragladeSeed, attributes);
    }

    /// @notice Helper returning all data for a Planet
    /// @param tokenId the planet id
    /// @return the planet seed, the astraglade seed and the planet attributes (the integer form)
    function getPlanetData(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        require(planetSeed[tokenId] != 0, '!UNKNOWN_TOKEN!');

        uint256 seed = uint256(planetSeed[tokenId]) % SEED_BOUND;
        uint256[] memory attributes = _getAttributes(seed);

        AstragladeUpgrade.AstragladeMeta memory astraglade = AstragladeUpgrade(
            payable(astragladeContract)
        ).getAstraglade(tokenId);

        return (seed, astraglade.seed, attributes);
    }

    /// @notice Returns Metadata for Astraglade id
    /// @param tokenId the tokenId we want metadata for
    function getAstraglade(uint256 tokenId)
        public
        view
        returns (AstragladeUpgrade.AstragladeMeta memory astraglade)
    {
        return
            AstragladeUpgrade(payable(astragladeContract)).getAstraglade(
                tokenId
            );
    }

    /// @notice helper to get the description
    function getDescription() public view returns (string memory) {
        if (bytes(_description).length == 0) {
            return
                "Astraglade Planets is an extension of project Astraglade (https://nurecas.com/astraglade). Planets are an interactive and generative 3D art that can be minted for free by anyone who owns an astraglade at [https://astraglade.beyondnft.io/planets/](https://astraglade.beyondnft.io/planets/). When a Planet is minted, the owner's astraglade will orbit forever around the planet that they mint.";
        }

        return _description;
    }

    /// @notice helper to get the baseRenderURI
    function getBaseRenderURI() public view returns (string memory) {
        if (bytes(_baseRenderURI).length == 0) {
            return 'ar://JYtFvtxlpyur2Cdpaodmo46XzuTpmp0OwJl13rFUrrg/';
        }

        return _baseRenderURI;
    }

    /// @notice helper to get the baseImageURI
    function getBaseImageURI() public view returns (string memory) {
        if (bytes(_baseImagesURI).length == 0) {
            return 'https://astraglade-api.beyondnft.io/planets/images/';
        }

        return _baseImagesURI;
    }

    /// @inheritdoc	INFModule
    function onAttach()
        external
        virtual
        override(INFModule, NFBaseModule)
        returns (bool)
    {
        // only the first attach is accepted, saves a "setPlanetsContract" call
        if (planetsContract == address(0)) {
            planetsContract = msg.sender;
            return true;
        }

        return false;
    }

    /// @notice Claim tokenIds[] from the astraglade contract
    /// @param tokenIds the tokenIds to claim
    function claim(uint256[] calldata tokenIds) external {
        address operator = msg.sender;

        // saves some reads
        address astragladeContract_ = astragladeContract;
        address planetsContract_ = planetsContract;

        for (uint256 i; i < tokenIds.length; i++) {
            _claim(
                operator,
                tokenIds[i],
                astragladeContract_,
                planetsContract_
            );
        }
    }

    /// @notice Allows to freeze any metadata update
    function freezeMeta() external onlyOperator {
        frozenMeta = true;
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOperator {
        _setContractURI(newURI);
    }

    /// @notice sets planets contract
    /// @param planetsContract_ the contract containing planets
    function setPlanetsContract(address planetsContract_)
        external
        onlyOperator
    {
        planetsContract = planetsContract_;
    }

    /// @notice helper to set the description
    /// @param newDescription the new description
    function setDescription(string memory newDescription)
        external
        onlyOperator
    {
        require(frozenMeta == false, '!META_FROZEN!');
        _description = newDescription;
    }

    /// @notice helper to set the baseRenderURI
    /// @param newRenderURI the new renderURI
    function setBaseRenderURI(string memory newRenderURI)
        external
        onlyOperator
    {
        require(frozenMeta == false, '!META_FROZEN!');
        _baseRenderURI = newRenderURI;
    }

    /// @notice helper to set the baseImageURI
    /// @param newBaseImagesURI the new base image URI
    function setBaseImagesURI(string memory newBaseImagesURI)
        external
        onlyOperator
    {
        require(frozenMeta == false, '!META_FROZEN!');
        _baseImagesURI = newBaseImagesURI;
    }

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOperator {
        address[3] memory feeRecipients_ = feeRecipients;

        uint256 balance_ = address(this).balance;
        payable(address(feeRecipients_[0])).transfer((balance_ * 30) / 100);
        payable(address(feeRecipients_[1])).transfer((balance_ * 35) / 100);
        payable(address(feeRecipients_[2])).transfer(address(this).balance);
    }

    /// @notice helper to set the fee recipient at `index`
    /// @param newFeeRecipient the new address
    /// @param index the index to edit
    function setFeeRecipient(address newFeeRecipient, uint8 index)
        external
        onlyOperator
    {
        require(index < feeRecipients.length, '!INDEX_OVERFLOW!');
        require(newFeeRecipient != address(0), '!INVALID_ADDRESS!');

        feeRecipients[index] = newFeeRecipient;
    }

    /// @notice Helper for an operator to change the current operator address
    /// @param newOperator the new operator
    function setContractOperator(address newOperator) external onlyOperator {
        contractOperator = newOperator;
    }

    /// @dev Allows to claim a tokenId; the Planet will always be minted to the owner of the Astraglade
    /// @param operator the one launching the claim (needs to be owner or approved on the Astraglade)
    /// @param tokenId the Astraglade tokenId to claim
    /// @param astragladeContract_ the Astraglade contract to check ownership
    /// @param planetsContract_ the Planet contract (where to mint the tokens)
    function _claim(
        address operator,
        uint256 tokenId,
        address astragladeContract_,
        address planetsContract_
    ) internal {
        AstragladeUpgrade astraglade = AstragladeUpgrade(
            payable(astragladeContract_)
        );
        address owner_ = astraglade.ownerOf(tokenId);

        // verify that the operator has the right to claim
        require(
            owner_ == operator ||
                astraglade.isApprovedForAll(owner_, operator) ||
                astraglade.getApproved(tokenId) == operator,
            '!NOT_AUTHORIZED!'
        );

        // mint
        INiftyForge721 planets = INiftyForge721(planetsContract_);

        // always mint to owner_, not to operator
        planets.mint(owner_, '', tokenId, address(0), 0, address(0));

        // creates a seed
        bytes32 seed;
        do {
            seed = _generateSeed(
                tokenId,
                block.timestamp,
                owner_,
                blockhash(block.number - 1)
            );
        } while (seedTaken[uint256(seed) % SEED_BOUND]);

        planetSeed[tokenId] = seed;
        // ensure we won't have two seeds rendering the same planet
        seedTaken[uint256(seed) % SEED_BOUND] = true;
    }

    /// @dev Calculate next seed using a few on chain data
    /// @param tokenId tokenId
    /// @param timestamp current block timestamp
    /// @param operator current operator
    /// @param blockHash last block hash
    /// @return a new bytes32 seed
    function _generateSeed(
        uint256 tokenId,
        uint256 timestamp,
        address operator,
        bytes32 blockHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    tokenId,
                    timestamp,
                    operator,
                    blockHash,
                    block.coinbase,
                    block.difficulty,
                    tx.gasprice
                )
            );
    }

    /// @notice generates the attributes values according to seed
    /// @param seed the seed to generate the values
    /// @return attributes an array of attributes (integers)
    function _getAttributes(uint256 seed)
        internal
        pure
        returns (uint256[] memory attributes)
    {
        Randomize.Random memory random = Randomize.Random({seed: seed});

        // remember, all numbers returned by randomBetween are
        // multiplicated by 1000, because solidity has no decimals
        // so we will divide all those numbers later
        attributes = new uint256[](6);

        // density
        attributes[0] = random.randomBetween(10, 200);

        // radius
        attributes[1] = random.randomBetween(5, 15);

        // cube planet
        attributes[2] = random.randomBetween(0, 5000);
        if (attributes[2] < 20000) {
            // set radius = 10 if cube
            attributes[1] = 10000;
        }

        // shade - remember to actually change 1 into -1 in the HTML
        attributes[3] = random.randomBetween(0, 2) < 1000 ? 0 : 1;

        // rings
        // if cube, 2 or 3 rings
        if (attributes[2] < 20000) {
            attributes[4] = random.randomBetween(2, 4) / 1000;
        } else {
            // else 30% chances to have rings (1, 2 and 3)
            attributes[4] = random.randomBetween(0, 10) / 1000;
            // if more than 3, then none.
            if (attributes[4] > 3) {
                attributes[4] = 0;
            }
        }

        // moons, 0, 1, 2 or 3
        attributes[5] = random.randomBetween(0, 4) / 1000;
    }

    /// @notice Generates the JSON string from the attributes values
    /// @param attributes the attributes values
    /// @return jsonAttributes, the string for attributes
    function _generateJSONAttributes(uint256[] memory attributes)
        internal
        pure
        returns (string memory)
    {
        bytes memory coma = bytes(',');

        // Terrain
        bytes memory jsonAttributes = abi.encodePacked(
            _makeAttributes(
                'Terrain',
                attributes[0] < 50000 ? 'Dense' : 'Sparse'
            ),
            coma
        );

        // Size
        if (attributes[1] < 8000) {
            jsonAttributes = abi.encodePacked(
                jsonAttributes,
                _makeAttributes('Size', 'Tiny'),
                coma
            );
        } else if (attributes[1] < 12000) {
            jsonAttributes = abi.encodePacked(
                jsonAttributes,
                _makeAttributes('Size', 'Medium'),
                coma
            );
        } else {
            jsonAttributes = abi.encodePacked(
                jsonAttributes,
                _makeAttributes('Size', 'Giant'),
                coma
            );
        }

        // Form
        jsonAttributes = abi.encodePacked(
            jsonAttributes,
            _makeAttributes(
                'Form',
                attributes[2] < 20000 ? 'Tesseract' : 'Geo'
            ),
            coma,
            _makeAttributes('Shade', attributes[3] == 0 ? 'Vibrant' : 'Simple'),
            coma,
            _makeAttributes('Rings', attributes[4].toString()),
            coma,
            _makeAttributes('Moons', attributes[5].toString())
        );

        return string(jsonAttributes);
    }

    function _makeAttributes(string memory name_, string memory value)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{"trait_type":"',
                name_,
                '","value":"',
                value,
                '"}'
            );
    }

    /// @notice returns the URL to render the Planet
    /// @param seed the planet seed
    /// @param astragladeSeed the astraglade seed
    /// @param attributes all attributes needed for the planets
    /// @return the URI to render the planet
    function _renderTokenURI(
        uint256 seed,
        uint256 astragladeSeed,
        uint256[] memory attributes
    ) internal view returns (string memory) {
        bytes memory coma = bytes(',');

        bytes memory attrs = abi.encodePacked(
            attributes[0].toString(),
            coma,
            attributes[1].toString(),
            coma,
            attributes[2].toString(),
            coma
        );

        return
            string(
                abi.encodePacked(
                    getBaseRenderURI(),
                    '?seed=',
                    seed.toString(),
                    '&astragladeSeed=',
                    astragladeSeed.toString(),
                    '&attributes=',
                    abi.encodePacked(
                        attrs,
                        attributes[3].toString(),
                        coma,
                        attributes[4].toString(),
                        coma,
                        attributes[5].toString()
                    )
                )
            );
    }
}
