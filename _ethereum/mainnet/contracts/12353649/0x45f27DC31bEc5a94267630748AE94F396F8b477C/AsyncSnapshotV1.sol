//SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC721Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./HasSecondarySaleFees.sol";

contract AsyncSnapshotV1 is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable
{
    uint256 public defaultArtistSecondarySalePercentage;
    uint256 public defaultPlatformSecondarySalePercentage;

    address public asyncSaleFeesRecipient;

    mapping(uint256 => address) public artist;

    // ROLES
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(uint256 => string) tokenUris;

    ////////////////////////////////////
    /////////// EVENTS /////////////////
    ////////////////////////////////////

    event PreorderNFTMinted(
        uint256 preorderTokenId,
        uint256 blockNumberOfRedemption,
        address userAddress,
        uint256 snapshotTokenId,
        address artist
    );

    event V0SnapshotsLaunched(address initialAsyncAdmin);
    event UpdateAsyncSaleFeesRecipient(address asyncSaleFeesRecipient);

    ////////////////////////////////////
    //////////// Modifier //////////////
    ////////////////////////////////////

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender));
        _;
    }

    ////////////////////////////////////
    ////// Contract Initializer ////////
    ////////////////////////////////////

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(name_, symbol_);

        HasSecondarySaleFees._initialize();

        // Clean access control for minting.
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        defaultArtistSecondarySalePercentage = 1000; // 10%
        defaultPlatformSecondarySalePercentage = 500; //5%

        asyncSaleFeesRecipient = msg.sender;
        emit V0SnapshotsLaunched(msg.sender);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    function setAsyncFeeRecipient(address _asyncSaleFeesRecipient)
        external
        onlyAdmin
    {
        asyncSaleFeesRecipient = _asyncSaleFeesRecipient;
        emit UpdateAsyncSaleFeesRecipient(_asyncSaleFeesRecipient);
    }

    function changeDefaultArtistSecondarySalePercentage(uint256 _basisPoints)
        external
        onlyAdmin
    {
        require(_basisPoints + defaultPlatformSecondarySalePercentage <= 10000);
        defaultArtistSecondarySalePercentage = _basisPoints;
    }

    function changeDefaultPlatformSecondarySalePercentage(uint256 _basisPoints)
        external
        onlyAdmin
    {
        require(_basisPoints + defaultArtistSecondarySalePercentage <= 10000);
        defaultPlatformSecondarySalePercentage = _basisPoints;
    }

    function changeArtistAddress(uint256 tokenId, address _artistAddress)
        external
        onlyAdmin
    {
        artist[tokenId] = _artistAddress;
    }

    function addGlobalOperator(address operatorAddress) external {
        grantRole(OPERATOR_ROLE, operatorAddress);
    }

    function removeGlobalOperator(address operatorAddress) external {
        revokeRole(OPERATOR_ROLE, operatorAddress);
    }

    function addMinter(address minterAddress) external {
        grantRole(MINTER_ROLE, minterAddress);
    }

    function removeMinter(address minterAddress) external {
        revokeRole(MINTER_ROLE, minterAddress);
    }

    ////////////////////////////////////
    //////// Mint tokens ///////////////
    ////////////////////////////////////

    // preorderTokenId tells us which token it was minted for
    function mint(
        uint256 preorderTokenId,
        uint256 blockNumberOfRedemption,
        address to,
        uint256 tokenId,
        address artistAddress,
        string memory tokenUri
    ) external onlyMinter {
        _safeMint(to, tokenId);

        tokenUris[tokenId] = tokenUri;

        emit PreorderNFTMinted(
            preorderTokenId,
            blockNumberOfRedemption,
            to,
            tokenId,
            artistAddress
        );
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return tokenUris[tokenId];
    }

    function changeTokenUri(uint256 tokenId, string memory tokenUri)
        external
        onlyAdmin
    {
        tokenUris[tokenId] = tokenUri;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    function getFeeRecipients(uint256 id)
        public
        view
        override
        returns (address payable[] memory)
    {
        address payable[] memory feeRecipients = new address payable[](2);
        feeRecipients[0] = payable(asyncSaleFeesRecipient);
        feeRecipients[1] = payable(artist[id]);

        return feeRecipients;
    }

    function getFeeBps(uint256 id)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory fees = new uint256[](2);
        fees[0] = defaultPlatformSecondarySalePercentage;
        fees[1] = defaultArtistSecondarySalePercentage;

        return fees;
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
            hasRole(OPERATOR_ROLE, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC165StorageUpgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId);
    }
}
