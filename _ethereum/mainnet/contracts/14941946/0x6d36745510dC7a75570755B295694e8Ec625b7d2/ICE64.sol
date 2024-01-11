// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*


        .++++++    .-=+**++=:  -+++++++++++-      .-=+**.     .++++:      
         :@@@@. .+%@#++++#@@@@#=*@@@%++*@@@*   :*@@%+=-:      +@@@+       
          %@@# +@@+        :#@@#.@@@=    :#+ .#@@*.          -@@@+        
          #@@#*@@=           *@# @@@@-      -@@@*+*+=-      :@@@= =       
          #@@@@@@             += @@@@@@%%%=:@@@@*++#@@@#:  :@@@--%#       
          #@@@@@@                @@@= -*@@=#@@@     .*@@@--@@# +@@#   =   
          #@@@@@@-               @@@=    :.@@@%       #@@@@@+..+@@%-*@@   
          #@@#%@@@-           .%@@@@=      #@@@:      -@@@@@@@@@@@@@@@@   
          %@@# #@@@#-       :+@%-@@@=     :%@@@%.     *@@+     +@@%       
         :@@@@. :*@@@@%###%@@#= +@@@#++#%@@@**@@@#=-=%@%-     .@@@@-      
        .*****+    :=*###*+-.  -************:  -*###*=:      :******=

        O W N E R S H I P   C O N T R A C T

*/

import "./Owned.sol";
import "./ERC1155.sol";

import "./IERC20.sol";
import "./IERC721.sol";
import "./IICE64Renderer.sol";
import "./IICE64.sol";

/** 
@title ICE64, a photo collection by Sam King
@author Sam King (samkingstudio.eth)
@notice This contract stores token ownership, and allows minting using the ERC1155 standard.
        Collectors can purchase 721-like photos as original 1 of 1's, but also collect
        smaller on-chain versions as editions.

        Code is licensed as MIT.
        https://spdx.org/licenses/MIT.html

        Token metadata and images licensed as CC BY-NC 4.0
        https://creativecommons.org/licenses/by-nc/4.0/
        You are free to:
            - Share: copy and redistribute the material in any medium or format
            - Adapt: remix, transform, and build upon the material
        Under the following terms:
            - Attribution: You must give appropriate credit, provide a link to the license,
            and indicate if changes were made. You may do so in any reasonable manner, but not
            in any way that suggests the licensor endorses you or your use.
            - NonCommercial: You may not use the material for commercial purposes
            - No additional restrictions: You may not apply legal terms or technological measures
            that legally restrict others from doing anything the license permits.

*/
contract ICE64 is ERC1155, Owned, IICE64 {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Renderer contract for on-chain metadata
    IICE64Renderer public metadata;

    /// @dev Roots project contract address for owner claims
    IERC721 public roots;

    /// @dev uint256 to bool map for whether a Roots tokenId has used a free claim
    uint256 private _rootsClaims;

    /// @dev Token constants
    uint256 private constant _maxTokenId = 16;
    uint256 private constant _editionStartId = 100;
    uint256 private constant _maxEditions = 64;

    /// @dev Token prices
    uint256 public constant priceOriginal = 0.32 ether;
    uint256 public constant priceEdition = 0.04 ether;

    /// @dev Photo id (not token id) to packed uint256 with originals sold, editions sold,
    ///      and whether the original has claimed the reserved edition or not.
    ///      See `_encodeSalesData` and `_decodeSalesData`.
    mapping(uint256 => uint256) private _salesCount;

    /// @dev Store info about token royalties
    struct RoyaltyInfo {
        address receiver;
        uint24 amount;
    }

    RoyaltyInfo private _royaltyInfo;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event ICE64Emerges();
    event SetMetadataAddress(address indexed metadata);
    event RootsClaim(uint256 indexed rootsId, uint256 indexed originalId, uint256 editionId);

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error IncorrectEthAmount();
    error InvalidToken();
    error AlreadyOwnerOfEdition();
    error SoldOut();
    error EditionForOriginalStillReserved();
    error NotOwnerOfRootsPhoto();
    error RootsPhotoAlreadyUsedClaim();
    error NotOwner();
    error NoMetadataYet();
    error PaymentFailed();

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Limits purchases etc to a certain range of token ids
    /// @param id The id of the token to check
    modifier onlyValidToken(uint256 id) {
        if (id == 0 || id > _maxTokenId) revert InvalidToken();
        _;
    }

    /// @dev Checks the payment amount matches exactly (no more, no less)
    /// @param cost The amount that should be checked against
    modifier onlyCorrectPayment(uint256 cost) {
        if (msg.value != cost) revert IncorrectEthAmount();
        _;
    }

    /// @dev Require the metadata address to be set
    modifier onlyWithMetadata() {
        if (address(metadata) == address(0)) revert NoMetadataYet();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon deployment
    /// @param roots_ The Roots collection address
    constructor(
        address owner,
        address royalties,
        IERC721 roots_
    ) ERC1155() Owned(owner) {
        emit ICE64Emerges();
        // Set Roots contract address
        roots = roots_;
        // Set the initial storage value to non-zero to save gas costs for first roots claimer
        _rootsClaims = _setBool(_rootsClaims, 0, true);
        // Set the default royalties to 6.4% for the owner
        _royaltyInfo = RoyaltyInfo(royalties, 640);
    }

    /// @notice Sets the rendering/metadata contract address
    /// @dev The metadata address handles on-chain images and construction of baseURI for originals
    /// @param metadataAddr The address of the metadata contract
    function setMetadata(IICE64Renderer metadataAddr) external onlyOwner {
        metadata = metadataAddr;
        emit SetMetadataAddress(address(metadataAddr));
    }

    /* ------------------------------------------------------------------------
                                P U R C H A S I N G
    ------------------------------------------------------------------------ */

    /// @notice Purchase an original 1/1 photo and the included on-chain edition
    /// @dev Mints a 1/1 and an on-chain edition of the same token, but only if the buyer
    ///      doesn't already own an edition
    /// @param id The id of the photo to purchase
    function purchaseOriginal(uint256 id)
        external
        payable
        onlyValidToken(id)
        onlyCorrectPayment(priceOriginal)
    {
        (uint256 originalsSold, , ) = _decodeSalesCount(_salesCount[id]);
        if (originalsSold > 0) revert SoldOut();

        uint256 editionId = getEditionTokenId(id);
        if (balanceOf[msg.sender][editionId] > 0) {
            // Already owner of an edition so just mint an original and mark the
            // reserved edition as claimed so someone else can get an edition
            _mint(msg.sender, id, 1, "");
            _addSalesCount(id, 1, 0, true);
        } else {
            // Else mint both the original and the reserved edition
            /// @dev We could use `_batchMint` here, but there are issues with those tokens
            ///      not being picked up by certain marketplaces at the time of deployment.
            ///      Gas should be the same since we're only updating one of each token anyway.
            _mint(msg.sender, id, 1, "");
            _mint(msg.sender, editionId, 1, "");
            _addSalesCount(id, 1, 1, true);
        }
    }

    /// @notice Purchase an edition of a photo, rendered as a 64x64px on-chain SVG
    /// @dev Editions are sold out when `_maxEditions` editions have been minted, less one reserved
    ///      token for the holder of an original photo
    /// @param id The id of the edition to purchase (use original photo's id: `getEditionId(id)`)
    function purchaseEdition(uint256 id)
        external
        payable
        onlyValidToken(id)
        onlyCorrectPayment(priceEdition)
    {
        _mintEdition(id);
    }

    /// @notice Claim a free edition (whill supply lasts) if you hold a Roots photo. Check if the
    ///         Roots photo has been claimed with `hasEditionBeenClaimedForRootsPhoto`.
    /// @dev Requires holding a Roots photo that hasn't been previously used to claim an edition
    /// @param id The id of the photo to claim an edition for (use original photo's id)
    /// @param rootsId The id of the Roots photo to use when claiming
    function claimEditionAsRootsHolder(uint256 id, uint256 rootsId) external onlyValidToken(id) {
        if (roots.ownerOf(rootsId) != msg.sender) revert NotOwnerOfRootsPhoto();
        if (_getBool(_rootsClaims, rootsId)) revert RootsPhotoAlreadyUsedClaim();
        _mintEdition(id);
        _rootsClaims = _setBool(_rootsClaims, rootsId, true);
        emit RootsClaim(rootsId, id, getEditionTokenId(id));
    }

    /// @dev Internal function to mint an edition, checking if there's still supply
    /// @param id The id of the photo to mint an edition for (use original photo's id)
    function _mintEdition(uint256 id) internal {
        uint256 editionId = getEditionTokenId(id);
        (, uint256 editionsSold, bool reservedEditionClaimed) = _decodeSalesCount(_salesCount[id]);
        uint256 editionsAvailable = reservedEditionClaimed ? _maxEditions : _maxEditions - 1;
        if (editionsSold == editionsAvailable) {
            if (reservedEditionClaimed) {
                revert SoldOut();
            } else {
                revert EditionForOriginalStillReserved();
            }
        }
        if (balanceOf[msg.sender][editionId] > 0) revert AlreadyOwnerOfEdition();
        _mint(msg.sender, editionId, 1, "");
        _addSalesCount(id, 0, 1, reservedEditionClaimed);
    }

    /// @dev Increments sales data for a given id
    /// @param id The id of the photo to add sales data for
    /// @param originalsSold_ The number of originals sold for this given call
    /// @param editionsSold_ The number of editions sold for this given call
    /// @param reservedEditionClaimed_ Whether the original photo has claimed the reserved edition
    function _addSalesCount(
        uint256 id,
        uint256 originalsSold_,
        uint256 editionsSold_,
        bool reservedEditionClaimed_
    ) internal {
        (uint256 originalsSold, uint256 editionsSold, ) = _decodeSalesCount(_salesCount[id]);
        _salesCount[id] = _encodeSalesCount(
            originalsSold + originalsSold_,
            editionsSold + editionsSold_,
            reservedEditionClaimed_
        );
    }

    /// @dev Encodes sales data into a single uint256 for cheaper storage updates
    /// @param originalsSoldCount The number of originals sold
    /// @param editionsSoldCount The number of editions sold
    /// @param reservedEditionClaimed Whether the original photo has claimed the reserved edition
    /// @return salesCount A packed uint256
    function _encodeSalesCount(
        uint256 originalsSoldCount,
        uint256 editionsSoldCount,
        bool reservedEditionClaimed
    ) internal pure returns (uint256 salesCount) {
        salesCount = salesCount | (originalsSoldCount << 0);
        salesCount = salesCount | (editionsSoldCount << 8);
        salesCount = reservedEditionClaimed ? salesCount | (1 << 16) : salesCount | (0 << 16);
    }

    /// @dev Decodes sales data from a single uint256
    /// @param salesCount The packed uint256 to decode
    /// @return originalsSoldCount The number of originals sold
    /// @return editionsSoldCount The number of editions sold
    /// @return reservedEditionClaimed Whether the original photo has claimed the reserved edition
    function _decodeSalesCount(uint256 salesCount)
        internal
        pure
        returns (
            uint256 originalsSoldCount,
            uint256 editionsSoldCount,
            bool reservedEditionClaimed
        )
    {
        originalsSoldCount = uint8(salesCount >> 0);
        editionsSoldCount = uint8(salesCount >> 8);
        reservedEditionClaimed = uint8(salesCount >> 16) > 0;
    }

    /* ------------------------------------------------------------------------
                                 O R I G I N A L S
    ------------------------------------------------------------------------ */

    /// @notice Gets the original token id from an edition token id
    /// @param editionId The token id of the edition
    function getOriginalTokenId(uint256 editionId) public pure returns (uint256) {
        return editionId - _editionStartId;
    }

    /// @notice Checks if an original photo has been sold
    /// @param id The id of the photo
    function getOriginalSold(uint256 id) external view returns (bool) {
        (uint256 originalsSold, , ) = _decodeSalesCount(_salesCount[id]);
        return originalsSold > 0;
    }

    /* ------------------------------------------------------------------------
                                  E D I T I O N S
    ------------------------------------------------------------------------ */

    /// @notice Gets the edition token id from the original token id
    /// @param id The id of the original photo
    function getEditionTokenId(uint256 id) public pure returns (uint256) {
        return id + _editionStartId;
    }

    /// @notice Gets the total number of editions that have been sold for a photo
    /// @param id The id of the photo to get the number of editions sold
    function getEditionsSold(uint256 id) external view returns (uint256) {
        (, uint256 editionsSold, ) = _decodeSalesCount(_salesCount[id]);
        return editionsSold;
    }

    /// @notice Gets the maximum number of editions per photo
    function getMaxEditions() external pure returns (uint256) {
        return _maxEditions;
    }

    /// @notice Checks if a token id is an original or an edition
    /// @param id The token id to check
    function isEdition(uint256 id) public pure returns (bool) {
        return id > _editionStartId;
    }

    /// @notice Check if a particular Roots photo has been used to claim an edition
    /// @param rootsId The id of the Roots photo
    function hasEditionBeenClaimedForRootsPhoto(uint256 rootsId) external view returns (bool) {
        return _getBool(_rootsClaims, rootsId);
    }

    /* ------------------------------------------------------------------------
                                  E R C - 1 1 5 5
    ------------------------------------------------------------------------ */

    /// @notice Burn your token :(
    /// @param id The id of the token you want to burn
    function burn(uint256 id) external {
        if (balanceOf[msg.sender][id] == 0) revert NotOwner();
        _burn(msg.sender, id, 1);
    }

    /// @notice Standard URI function to get the token metadata
    /// @param id The token id to get metadata for
    function uri(uint256 id) public view virtual override onlyWithMetadata returns (string memory) {
        return metadata.tokenURI(id);
    }

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    /// @notice Withdraw the contracts ETH balance to the admin wallet
    function withdrawBalance() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert PaymentFailed();
    }

    /// @notice Withdraw all tokens for a given contract to the admin wallet
    function withdrawToken(IERC20 tokenAddress) external {
        tokenAddress.transfer(owner, tokenAddress.balanceOf(address(this)));
    }

    /* ------------------------------------------------------------------------
                                 R O Y A L T I E S
    ------------------------------------------------------------------------ */

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 10_000;
    }

    /// @notice Update royalty information
    /// @param receiver The receiver of royalty payments
    /// @param amount The royalty percentage with two decimals (10000 = 100)
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyOwner {
        _royaltyInfo = RoyaltyInfo(receiver, uint24(amount));
    }

    /// @dev Extend `supportsInterface` to suppoer EIP-2981
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // EIP-2981 = bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /* ------------------------------------------------------------------------
                                M I S C   U T I L S
    ------------------------------------------------------------------------ */

    /// @dev Internal function to store up to 256 bools in a single uint256
    /// @param packed The uint256 that contains the packed booleans
    /// @param idx The index of the boolean to set
    /// @param value Whether the bool is true or false
    /// @return packed The updated packed uint256
    function _setBool(
        uint256 packed,
        uint256 idx,
        bool value
    ) internal pure returns (uint256) {
        if (value) return packed | (uint256(1) << idx);
        return packed & ~(uint256(1) << idx);
    }

    /// @dev Internal function to get a specific boolean from a packed uint256
    /// @param packed The uint256 that contains the packed booleans
    /// @param idx The index of the boolean to get
    /// @return value If the value is set to true or false
    function _getBool(uint256 packed, uint256 idx) internal pure returns (bool) {
        uint256 flag = (packed >> idx) & uint256(1);
        return flag == 1;
    }
}
