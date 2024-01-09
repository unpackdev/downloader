// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./ERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721.sol";
import "./IDecentralandEstate.sol";

// Error Table
// -----------
// E0 = tokenId cannot be 0
// E1 = contract not enabled
// E2 = must have exactly 1 fingerprint per ESTATE
// E3 = estate not in registry
// E4 = estate has wrong fingerprint
// E5 = token not in registry
// EA = unauthorized
// EB = tokenId out of bounds
// EE = token cannot be transferred w/o all registered lands escrowed

contract Resort is
    Initializable,
    ERC721Upgradeable,
    IERC721ReceiverUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    uint256 public constant MIN_TOKEN_ID = 1;
    uint256 public constant MAX_TOKEN_ID = 55;

    string public baseURI;
    string public contractURI; // OpenSea store-front metadata

    // Arweave mirror of metadata
    mapping(uint256 => string) public arweaveTx;

    // Verification of stored metadata.  Metadata storage can now be independent
    mapping(uint256 => bytes32) public metadataHash;

    // Generic ERC721 register (Decentraland LAND, Sandbox LAND, etc.)
    // ERC721 contract => enabled
    mapping(address => bool) public erc721ContractRegistry;
    // ERC721 contract => token ID => resort ID (0 for not present)
    mapping(address => mapping(uint256 => uint256)) public erc721TokenRegistry;

    struct ERC721Register {
        address contractAddress;
        uint256[] tokenIds;
    }

    // RESORT token id => ERC721 registers
    mapping(uint256 => ERC721Register[]) public erc721Registry;

    // Decentraland ESTATE register
    address public DECENTRALAND_ESTATE;
    // ESTATE token id => fingerprint
    mapping(uint256 => bytes32) public decentralandEstateFingerprints;
    // ESTATE token id => RESORT token id (0 for not present)
    mapping(uint256 => uint256) public decentralandEstateRegistry;
    // RESORT token id => ESTATE token ids
    mapping(uint256 => uint256[]) public decentralandEstateIds;

    event RegistryChanged(address indexed sender, uint256 indexed id);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("Resort", "RESORT");
        __Ownable_init();
        __UUPSUpgradeable_init();

        enableDecentralandEstate(0x959e104E1a4dB6317fA58F8295F586e1A978c297);
        // Decentraland LAND
        enableERC721(0xF87E31492Faf9A91B02Ee0dEAAd50d51d56D5d4d, true);
        // Sandbox LAND
        enableERC721(0x50f5474724e0Ee42D9a4e711ccFB275809Fd6d4a, true);

        _setContractURI("https://extraverse.xyz/metadata/resorts/index");
        _setBaseURI("https://extraverse.xyz/metadata/resorts/");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // Accessor functions

    function getDecentralandEstateIds(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return decentralandEstateIds[tokenId];
    }

    function getERC721(uint256 tokenId)
        external
        view
        returns (ERC721Register[] memory)
    {
        return erc721Registry[tokenId];
    }

    // Owner-only registry modifiers

    function enableERC721(address contractAddress, bool enabled)
        public
        onlyOwner
    {
        erc721ContractRegistry[contractAddress] = enabled;
    }

    function enableDecentralandEstate(address contractAddress)
        public
        onlyOwner
    {
        DECENTRALAND_ESTATE = contractAddress;
    }

    // URI accessors and modifiers

    function _setContractURI(string memory contractURI_) private {
        contractURI = contractURI_;
    }

    function setContractURI(string calldata contractURI_) public onlyOwner {
        _setContractURI(contractURI_);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseURI_) private {
        baseURI = baseURI_;
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    // Metadata modifiers

    function _setMetadata(
        uint256 id,
        string memory _arweaveTx,
        bytes32 hash
    ) private {
        arweaveTx[id] = _arweaveTx;
        metadataHash[id] = hash;
    }

    function setMetadata(
        uint256 id,
        string calldata _arweaveTx,
        bytes32 hash
    ) external onlyOwner {
        _setMetadata(id, _arweaveTx, hash);
    }

    // Owner-only registry modifiers

    function _registerERC721(uint256 id, ERC721Register[] memory registers)
        private
    {
        // Zero out existing register
        ERC721Register[] storage existing = erc721Registry[id];
        for (uint256 i = 0; i < existing.length; i++) {
            address contractAddress = existing[i].contractAddress;
            uint256[] storage tokenIds = existing[i].tokenIds;
            require(erc721ContractRegistry[contractAddress], "E1");
            for (uint256 j = 0; j < tokenIds.length; j++) {
                erc721TokenRegistry[contractAddress][tokenIds[j]] = 0;
            }
        }

        // Set new register
        delete erc721Registry[id];
        for (uint256 i = 0; i < registers.length; i++) {
            erc721Registry[id].push(registers[i]);
            address contractAddress = registers[i].contractAddress;
            uint256[] memory tokenIds = registers[i].tokenIds;
            require(erc721ContractRegistry[contractAddress], "E1");
            for (uint256 j = 0; j < tokenIds.length; j++) {
                erc721TokenRegistry[contractAddress][tokenIds[j]] = id;
            }
        }

        // Emit change event
        emit RegistryChanged(msg.sender, id);
    }

    // WARNING: changing the registry when NFTs are still in escrow will render
    // them unredeemable.  This can be fixed by changing the registry back to
    // how it was, but it wastes gas and could potentially be held up
    // politically if e.g. the owner is a DAO.
    //
    // WARNING: it isn't obvious that the registerERC721 totally resets any
    // previous registry state for the given token id.
    function registerERC721(uint256 id, ERC721Register[] calldata registers)
        external
        onlyOwner
    {
        _registerERC721(id, registers);
    }

    function _registerDecentralandEstates(
        uint256 id,
        uint256[] memory estateIds,
        bytes32[] memory estateFingerprints
    ) private {
        require(estateIds.length == estateFingerprints.length, "E2");

        // Zero out existing register
        uint256[] storage existing = decentralandEstateIds[id];
        for (uint256 i = 0; i < existing.length; i++) {
            decentralandEstateFingerprints[existing[i]] = 0;
            decentralandEstateRegistry[existing[i]] = 0;
        }

        // Set new register
        for (uint256 i = 0; i < estateIds.length; i++) {
            decentralandEstateFingerprints[estateIds[i]] = estateFingerprints[
                i
            ];
            decentralandEstateRegistry[estateIds[i]] = id;
        }
        decentralandEstateIds[id] = estateIds;

        // Emit change event
        emit RegistryChanged(msg.sender, id);
    }

    function registerDecentralandEstates(
        uint256 id,
        uint256[] calldata estateIds,
        bytes32[] calldata estateFingerprints
    ) external onlyOwner {
        _registerDecentralandEstates(id, estateIds, estateFingerprints);
    }

    // Owner-only mint

    // NB: resorts are not randomly generated, so no need for token provenance
    function safeMint(
        uint256 tokenId,
        address to,
        string calldata _arweaveTx,
        bytes32 hash
    ) external onlyOwner {
        require(tokenId != 0, "E0");
        require(tokenId >= MIN_TOKEN_ID, "EB");
        require(tokenId <= MAX_TOKEN_ID, "EB");
        _safeMint(to, tokenId);
        _setMetadata(tokenId, _arweaveTx, hash);
    }

    // Escrow functionality

    // Check if the contract is holding all the registered NFTs for escrow
    function isEscrowed(uint256 tokenId) public view returns (bool) {
        ERC721Register[] storage registers = erc721Registry[tokenId];
        for (uint256 i = 0; i < registers.length; i++) {
            IERC721 erc721 = IERC721(registers[i].contractAddress);
            for (uint256 j = 0; j < registers[i].tokenIds.length; j++) {
                if (erc721.ownerOf(registers[i].tokenIds[j]) != address(this)) {
                    return false;
                }
            }
        }

        IDecentralandEstate ESTATE = IDecentralandEstate(DECENTRALAND_ESTATE);
        uint256[] storage estateIds = decentralandEstateIds[tokenId];
        for (uint256 i = 0; i < estateIds.length; i++) {
            uint256 estateId = estateIds[i];
            if (ESTATE.ownerOf(estateId) != address(this)) {
                return false;
            }
            if (
                ESTATE.getFingerprint(estateId) !=
                decentralandEstateFingerprints[estateId]
            ) {
                return false;
            }
        }

        return true;
    }

    // Redeem all registered NFTs from escrow to address
    function redeem(uint256 tokenId, address to) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EA");

        ERC721Register[] storage registers = erc721Registry[tokenId];
        for (uint256 i = 0; i < registers.length; i++) {
            IERC721 erc721 = IERC721(registers[i].contractAddress);
            for (uint256 j = 0; j < registers[i].tokenIds.length; j++) {
                erc721.safeTransferFrom(
                    address(this),
                    to,
                    registers[i].tokenIds[j]
                );
            }
        }

        IERC721 ESTATE = IERC721(DECENTRALAND_ESTATE);
        uint256[] storage estateIds = decentralandEstateIds[tokenId];
        for (uint256 i = 0; i < estateIds.length; i++) {
            ESTATE.safeTransferFrom(address(this), to, estateIds[i]);
        }
    }

    // Backup redeem function, if one of the contracts in the registry becomes
    // malformed for any reason, malicious or not; can still recover individual
    // NFTs from the resort, without resorting to changing the registry.
    function redeemOne(
        uint256 tokenId,
        address contractAddress,
        uint256 contractTokenId,
        address to
    ) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EA");

        if (contractAddress == DECENTRALAND_ESTATE) {
            require(
                decentralandEstateRegistry[contractTokenId] == tokenId,
                "E3"
            );
            // NB: exempt from strict fingerprint checking, in case the estate
            // somehow got changed from under us due to DCL admin action
        } else {
            require(erc721ContractRegistry[contractAddress], "E1");
            require(
                erc721TokenRegistry[contractAddress][contractTokenId] ==
                    tokenId,
                "E5"
            );
        }

        IERC721(contractAddress).safeTransferFrom(
            address(this),
            to,
            contractTokenId
        );
    }

    // Receiver check

    // NB: NFTs may mint directly into the Resort contract which would bypass
    // this receiver.  Benign for now, but something to keep in mind.
    function onERC721Received(
        address, // operator
        address, // from
        uint256 tokenId,
        bytes calldata // data
    ) external override(IERC721ReceiverUpgradeable) returns (bytes4) {
        if (msg.sender == DECENTRALAND_ESTATE) {
            require(decentralandEstateRegistry[tokenId] != 0, "E3");
            require(
                IDecentralandEstate(msg.sender).getFingerprint(tokenId) ==
                    decentralandEstateFingerprints[tokenId],
                "E4"
            );
        } else {
            require(erc721ContractRegistry[msg.sender], "E1");
            require(erc721TokenRegistry[msg.sender][tokenId] != 0, "E5");
        }
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(isEscrowed(tokenId), "EE");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
