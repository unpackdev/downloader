//SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./HasSecondarySaleFees.sol";
import "./ERC1155Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";

/// @title Async preorder contract
/// @author Avo Labs GmbH
/// @notice Allows users to preorder artworks, and redeem preorder tokens for NFTs
/// @dev ERC1155 standard used for fungible (pre-order) tokens types
contract AsyncPreorder is
    ERC1155Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable
{
    mapping(uint256 => bool) public isPreorder;
    mapping(uint256 => uint256) public numberOfTokens;
    mapping(uint256 => uint256) public pricePerToken;
    mapping(uint256 => address) public artistAddress;

    uint256 public constant basisPointsDenominator = 10000;

    // primary sale percentage default
    uint256 public defaultArtistPrimarySalePercentage;

    // secondary percentage sale default
    uint256 public defaultArtistSecondarySalePercentage;
    uint256 public defaultPlatformSecondarySalePercentage;

    // Roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");

    address public asyncSaleFeesRecipient;

    ////////////////////////////////////
    /////////// EVENTS /////////////////
    ////////////////////////////////////

    event V0ContractsLaunched(address initialAsyncAdmin);
    event UpdateAsyncSaleFeesRecipient(address asyncSaleFeesRecipient);

    event MinimumPriceUpdated(uint256 tokenId, uint256 pricePerToken);
    event ArtistAddressUpdated(uint256 tokenId, address artistAddress);

    event PreorderCreated(
        uint256 preorderTokenId,
        uint256 numberOfEditions,
        uint256 minimumPrice,
        address artistAddress
    );

    event ArtworkPreordered(
        uint256 tokenId,
        uint256 numberOfEditionsToBuy,
        address user
    );
    event ArtworkPreorderedPlatform(
        uint256 tokenId,
        uint256 numberOfEditionsAcquired
    );
    event PreorderRedeemed(
        uint256 tokenId,
        uint256 numberOfEditions,
        address user
    );

    ////////////////////////////////////
    /////////// MODIFIERS /////////////
    ////////////////////////////////////

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    modifier onlyPlatform() {
        require(hasRole(PLATFORM_ROLE, msg.sender));
        _;
    }

    ////////////////////////////////////
    ///// INITIALIZE THE CONTRACT :) ///
    ////////////////////////////////////

    function initialize(string memory uri) public initializer {
        ERC1155Upgradeable.__ERC1155_init(uri);
        HasSecondarySaleFees._initialize();
        address initialAdmin = 0xdB8ac7027ce4a09C640eA07d582c700e78B95536;
        address initialPlatform = 0x60874f721A66a2B9018C7CaCC46151708864f52d;

        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _setupRole(OPERATOR_ROLE, initialAdmin);
        _setupRole(PLATFORM_ROLE, initialPlatform);

        defaultArtistPrimarySalePercentage = 7500; //75%
        defaultArtistSecondarySalePercentage = 1000; // 10%
        defaultPlatformSecondarySalePercentage = 500; //5%

        asyncSaleFeesRecipient = msg.sender;

        emit V0ContractsLaunched(msg.sender);
    }

    ////////////////////////////////////
    //////// ADMIN FUNCTIONS ///////////
    ////////////////////////////////////

    function setAsyncFeeRecipient(address _asyncSaleFeesRecipient)
        external
        onlyAdmin
    {
        asyncSaleFeesRecipient = _asyncSaleFeesRecipient;
        emit UpdateAsyncSaleFeesRecipient(_asyncSaleFeesRecipient);
    }

    function updateTokenUri(string memory newUri) external onlyAdmin {
        _setURI(newUri);
    }

    function changeDefaultArtistPrimarySalePercentage(uint256 _basisPoints)
        external
        onlyAdmin
    {
        require(_basisPoints <= basisPointsDenominator);
        defaultArtistPrimarySalePercentage = _basisPoints;
    }

    function changeDefaultArtistSecondarySalePercentage(uint256 _basisPoints)
        external
        onlyAdmin
    {
        require(
            _basisPoints + defaultPlatformSecondarySalePercentage <=
                basisPointsDenominator
        );
        defaultArtistSecondarySalePercentage = _basisPoints;
    }

    function changeDefaultPlatformSecondarySalePercentage(uint256 _basisPoints)
        external
        onlyAdmin
    {
        require(
            _basisPoints + defaultArtistSecondarySalePercentage <=
                basisPointsDenominator
        );
        defaultPlatformSecondarySalePercentage = _basisPoints;
    }

    function addGlobalOperator(address operatorAddress) external {
        grantRole(OPERATOR_ROLE, operatorAddress);
    }

    function removeGlobalOperator(address operatorAddress) external {
        revokeRole(OPERATOR_ROLE, operatorAddress);
    }

    function addPlatformAddress(address platformAddress) external {
        grantRole(PLATFORM_ROLE, platformAddress);
    }

    function removePlatformAddress(address platformAddress) external {
        revokeRole(PLATFORM_ROLE, platformAddress);
    }

    ////////////////////////////////////
    ////// PLATFORM ONLY FUNCTIONS /////
    ////////////////////////////////////

    function changeMinimumPrice(uint256 tokenId, uint256 _pricePerToken)
        external
        onlyPlatform
    {
        pricePerToken[tokenId] = _pricePerToken;
        emit MinimumPriceUpdated(tokenId, _pricePerToken);
    }

    function changeArtistAddress(uint256 tokenId, address _artistAddress)
        external
        onlyPlatform
    {
        artistAddress[tokenId] = _artistAddress;
        emit ArtistAddressUpdated(tokenId, _artistAddress);
    }

    ////////////////////////////////////
    // CREATE ARTWORK FOR PREORDER /////
    ////////////////////////////////////

    /// @notice Admin creates a pre-order artwork for artist
    /// @dev This function automatically handles indexing
    /// @param _preorderTokenId Unique ID of the artwork preorder product
    /// @param _numberOfEditions how many preorder copies will exist
    /// @param _artistAddress address of the artist going to create the work
    /// @param _minimumPrice min price per pre order token
    function createPreorder(
        uint256 _preorderTokenId,
        uint256 _numberOfEditions,
        address _artistAddress,
        uint256 _minimumPrice
    ) external onlyPlatform {
        require(_numberOfEditions > 0 && _minimumPrice > 0);
        require(!isPreorder[_preorderTokenId]); // is not already created

        isPreorder[_preorderTokenId] = true;
        numberOfTokens[_preorderTokenId] = _numberOfEditions;
        pricePerToken[_preorderTokenId] = _minimumPrice;
        artistAddress[_preorderTokenId] = _artistAddress;

        emit PreorderCreated(
            _preorderTokenId,
            _numberOfEditions,
            _minimumPrice,
            _artistAddress
        );
    }

    ////////////////////////////////////
    // PLATFORM PREORDER OF TOKENS /////
    ////////////////////////////////////

    /// @notice Platform can get free pre-order copies of an artwork
    /// @dev Mints fungible pre-order tokens for the platform
    /// @param tokenId The ID of the artwork to preorder
    /// @param numberOfEditionsToBuy How many copies the platform wants to preorder
    function preorderArtworkPlatform(
        uint256 tokenId,
        uint256 numberOfEditionsToBuy
    ) external onlyPlatform {
        require(isPreorder[tokenId], "not preorder token");

        // Will revert if enough editions do not exist
        // Safe math should revert this.
        numberOfTokens[tokenId] =
            numberOfTokens[tokenId] -
            numberOfEditionsToBuy;

        _mint(msg.sender, tokenId, numberOfEditionsToBuy, "");
        emit ArtworkPreorderedPlatform(tokenId, numberOfEditionsToBuy);
    }

    ////////////////////////////////////
    ///////// PLACE PREORDER ///////////
    ////////////////////////////////////

    /// @notice User can pre-order copies of an artwork
    /// @dev Mints fungible pre-order tokens for the buyer
    /// @param tokenId The ID of the artwork to preorder
    /// @param numberOfEditionsToBuy How many copies the user wants to preorder
    function preorderArtwork(uint256 tokenId, uint256 numberOfEditionsToBuy)
        external
        payable
    {
        require(isPreorder[tokenId], "not preorder token");
        require(
            msg.value == numberOfEditionsToBuy * pricePerToken[tokenId],
            "send exact ETH value"
        );

        numberOfTokens[tokenId] =
            numberOfTokens[tokenId] -
            numberOfEditionsToBuy;

        _forwardFunds(tokenId);
        _mint(msg.sender, tokenId, numberOfEditionsToBuy, "");
        emit ArtworkPreordered(tokenId, numberOfEditionsToBuy, msg.sender);
    }

    /// @notice Forwards pre-order funds to artist and platform
    /// @dev Calculates the specific cut, and sends to artist and platform
    /// @param tokenId used to know the artist and cut amount to send
    function _forwardFunds(uint256 tokenId) internal {
        uint256 artistAmount =
            (msg.value * defaultArtistPrimarySalePercentage) /
                basisPointsDenominator;

        uint256 platformAmount = msg.value - artistAmount;
        payable(artistAddress[tokenId]).transfer(artistAmount);
        payable(asyncSaleFeesRecipient).transfer(platformAmount);
    }

    ////////////////////////////////////
    ///////// REDEEM PREORDERS /////////
    ////////////////////////////////////

    /// @notice Redeem a preorder token to get a NFT
    /// @dev Will burn the preorder token and mint the NFT
    /// @param tokenId of preorder token you want to redeem
    /// @param numberOfEditions how many preorder editions to redeem
    function redeemPreorder(uint256 tokenId, uint256 numberOfEditions)
        external
    {
        _burn(msg.sender, tokenId, numberOfEditions);
        emit PreorderRedeemed(tokenId, numberOfEditions, msg.sender);
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
        feeRecipients[1] = payable(artistAddress[id]);

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
    /// Required function override /////
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
        override(ERC1155Upgradeable, ERC165StorageUpgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId);
    }
}
