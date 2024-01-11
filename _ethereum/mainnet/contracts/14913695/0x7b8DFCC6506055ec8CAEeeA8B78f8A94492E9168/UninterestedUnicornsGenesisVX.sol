// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ERC721Upgradeable.sol";

import "./ECDSAUpgradeable.sol";

import "./ICandyToken.sol";

contract UninterestedUnicornsGenesisVX is
    AccessControlEnumerableUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    // Max Supply of UUv3
    uint256 public MAX_SUPPLY;

    // External Contracts
    ICandyToken public CANDY_TOKEN;

    // Private Variables
    CountersUpgradeable.Counter private _tokenIds;
    string private baseTokenURI;

    // UU Status
    mapping(uint256 => bool) public isGen1; // Mapping that determines if a Gen1 UU has been used to mint a voxel UU
    mapping(uint256 => bool) public isGen2; // Mapping that determines if a Gen2 UU has been used to mint a voxel UU

    // Toggles
    bool private voxelMintingOpen;
    bool private voxelMintingUcdOpen;

    // UCD Mint Cost
    uint256 public MINTING_COST;

    // Mint Caps
    mapping(address => uint8) public publicSaleMintedAmount;

    // Signer Address
    address private CLAIM_SIGNER;
    address private MINT_SIGNER;

    // Reserve Storage (important: New variables should be declared below)
    uint256[50] private ______gap;

    // ------------------------ EVENTS ----------------------------
    event VoxelCreated(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 parent_1_tokenId,
        uint256 parent_2_tokenId
    );

    event VoxelUcdCreated(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 parent_1_tokenId
    );

    event Airdropped(
        address indexed reciever,
        uint256 indexed tokenId,
        uint256 parent_1_tokenId
    );

    // ---------------------- MODIFIERS ---------------------------

    /// @dev Only EOA modifier
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "UUv3: Only EOA");
        _;
    }

    // ---------------------- INITIALIZER ---------------------------
    /**
     * @dev Constructor for UninterestedUnicornsV3
     * @param owner Address of the owner of this collection
     * @param candyToken Address of ICandyToken
     * @param __baseURI Base URI for the UUv3
     * @param __claimSigner Address of the claimSigner
     * @param __mintSigner Address of the mintSigner
     */
    function __UninterestedUnicornsGenesisVX_init(
        address owner,
        address candyToken,
        string memory __baseURI,
        address __claimSigner,
        address __mintSigner
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(
            "UninterestedUnicornsGenesisVX",
            "UU Genesis VX"
        );
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ReentrancyGuard_init_unchained();

        MINTING_COST = 1000 ether; // UCD (minting cost for phase3)
        MAX_SUPPLY = 6900; // Maximum of 6900 UUv3
        transferOwnership(owner);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // To revoke access after deployment
        _setBaseURI(__baseURI);
        CANDY_TOKEN = ICandyToken(candyToken);
        CLAIM_SIGNER = __claimSigner;
        MINT_SIGNER = __mintSigner;
    }

    // ------------------------- USER FUNCTION ---------------------------

    /**
     * @notice Takes the input of a gen 1 UU id and a gen 2 UU id and breed them together to get a Gen 3 Voxel (No UCD required)
     * @dev isVoxelMintingOpen() must be true
     * @dev Caller must be the owner of the Gen1 UU with `parent_1_tokenId` and the Gen2 UU with `parent_2_tokenId`
     * @dev parent_1_tokenId and parent_2_tokenId must not have been used before in claiming
     * @param parent_1_tokenId Token ID of Gen 1 Collection token 1
     * @param parent_2_tokenId Token ID of Gen 2 Collection token
     * @param signature Signature provider by CLAIM_SIGNER
     */
    function createVoxelFree(
        uint256 parent_1_tokenId,
        uint256 parent_2_tokenId,
        bytes memory signature
    ) external {
        require(isVoxelMintingOpen(), "UUv3: Voxel Generation is not open");
        require(
            _tokenIds.current() < MAX_SUPPLY,
            "UUv3: No more UUs available"
        );

        require(
            claimSigned(
                msg.sender,
                parent_1_tokenId,
                parent_2_tokenId,
                signature
            ),
            "UUv3: Claim Invalid Signature"
        );

        require(
            !isGen1[parent_1_tokenId] && !isGen2[parent_2_tokenId],
            "UUv3: UUs have been used before!"
        );

        // Increase Token ID
        _tokenIds.increment();

        // Set Gen 1 and Gen 2 flag to true
        isGen1[parent_1_tokenId] = true;
        isGen2[parent_2_tokenId] = true;

        // Mint
        _safeMint(msg.sender, _tokenIds.current());

        emit VoxelCreated(
            msg.sender,
            _tokenIds.current(),
            parent_1_tokenId,
            parent_2_tokenId
        );
    }

    /**
     * @notice Creates a VX Unicorn based on the parent_1_tokenId and UCD
     * @dev isVoxelMintingUcdOpen() must be true
     * @dev Caller must be the owner of the Gen1 UU with `parent_1_tokenId`
     * @dev parent_1_tokenId and parent_2_tokenId must not have been used before in claiming
     * @param parent_1_tokenId Token ID of Gen 1 Collection token 1
     * @param signature Signature provided by the MINT_SIGNER
     */
    function createVoxelUCD(uint256 parent_1_tokenId, bytes memory signature)
        external
    {
        require(
            mintSigned(msg.sender, parent_1_tokenId, signature),
            "UUv3: Mint Invalid Signature"
        );

        require(
            isVoxelMintingUcdOpen(),
            "UUv3: Voxel Generation (UCD) is not open"
        );
        require(
            _tokenIds.current() < MAX_SUPPLY,
            "UUv3: No more UUs available"
        );

        require(!isGen1[parent_1_tokenId], "UUv3: UUs have been used before!");

        // Increase Token ID
        _tokenIds.increment();

        // Set Gen 1 flag to true
        isGen1[parent_1_tokenId] = true;

        // Burn UCD Token
        CANDY_TOKEN.burn(msg.sender, MINTING_COST);

        // Mint
        _safeMint(msg.sender, _tokenIds.current());

        emit VoxelUcdCreated(
            _msgSender(),
            _tokenIds.current(),
            parent_1_tokenId
        );
    }

    // --------------------- VIEW FUNCTIONS ---------------------

    /**
     * @dev Determines if UU with tokenId `tokenId` from Gen1 has already been used for minting previous voxels
     */
    function canUseGen1UU(uint256 tokenId) external view returns (bool) {
        return !isGen1[tokenId];
    }

    /**
     * @dev Determines if UU with tokenId `tokenId` from Gen2 has already been used for minting previous voxels
     */
    function canUseGen2UU(uint256 tokenId) external view returns (bool) {
        return !isGen2[tokenId];
    }

    /**
     *  @dev Check if voxelMinting is open
     */
    function isVoxelMintingOpen() public view returns (bool) {
        return voxelMintingOpen;
    }

    /**
     *  @dev Check if voxelMintingUcd is open
     */
    function isVoxelMintingUcdOpen() public view returns (bool) {
        return voxelMintingUcdOpen;
    }

    /**
     * @dev Get Token URI Concatenated with Base URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "UUv3: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     *  @notice Get Total Supply of UUv3
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------

    /**
     *  @notice Airdrop UUv2 to addresses
     *  @param parent_1_tokenIds tokenId of gen 1 parent
     *  @param addresses Addresses to airdrop Gen2 UU
     */
    function airdrop(
        uint256[] memory parent_1_tokenIds,
        address[] memory addresses
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            parent_1_tokenIds.length == addresses.length,
            "UUv3: parent_1_tokenIds and addresses length mismatch"
        );
        require(
            _tokenIds.current() + parent_1_tokenIds.length <= MAX_SUPPLY,
            "UUv3: No more UUs available"
        );

        for (uint256 i; i < addresses.length; i++) {
            _tokenIds.increment();

            require(
                !isGen1[parent_1_tokenIds[i]],
                "UUv3: UUs have been used before!"
            );

            // Set Gen 1 flag to true
            isGen1[parent_1_tokenIds[i]] = true;

            _safeMint(addresses[i], _tokenIds.current());
            emit Airdropped(
                addresses[i],
                _tokenIds.current(),
                parent_1_tokenIds[i]
            );
        }
    }

    /// @dev Set MAX_SUPPLY of UUv3
    function setMaxSupply(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_SUPPLY = _amount;
    }

    /// @dev Update token metadata baseURI
    function updateBaseURI(string memory newURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(newURI);
    }

    /// @dev Toggle Voxel Minting Open
    function toggleVoxelMinting() public onlyRole(DEFAULT_ADMIN_ROLE) {
        voxelMintingOpen = !voxelMintingOpen;
    }

    /// @dev Toggle Voxel Minting Open
    function toggleVoxelUcdMinting() public onlyRole(DEFAULT_ADMIN_ROLE) {
        voxelMintingUcdOpen = !voxelMintingUcdOpen;
    }

    /// @dev Set UniCandy address
    function setUniCandy(address _uniCandyAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        CANDY_TOKEN = ICandyToken(_uniCandyAddress);
    }

    /// @dev Set Set Mint Cost
    function setMintCost(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MINTING_COST = _amount;
    }

    // --------------------- INTERNAL FUNCTIONS ---------------------

    /// @dev Set Base URI internal function
    function _setBaseURI(string memory _baseTokenURI) internal virtual {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Gets baseToken URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     *  @dev Check if whitelist signature is valid
     *  @param sender User address
     *  @param parent_1_tokenId Id of parent 1
     *  @param signature Signature generated by mintSigner
     */
    function mintSigned(
        address sender,
        uint256 parent_1_tokenId,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, parent_1_tokenId));
        return MINT_SIGNER == hash.recover(signature);
    }

    /**
     *  @dev Check if whitelist signature is valid
     *  @param sender User address
     *  @param parent_1_tokenId Id of parent 1
     *  @param parent_2_tokenId Id of parent 2
     *  @param signature Signature generated by claimSigner
     */
    function claimSigned(
        address sender,
        uint256 parent_1_tokenId,
        uint256 parent_2_tokenId,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(sender, parent_1_tokenId, parent_2_tokenId)
        );
        return CLAIM_SIGNER == hash.recover(signature);
    }
}
