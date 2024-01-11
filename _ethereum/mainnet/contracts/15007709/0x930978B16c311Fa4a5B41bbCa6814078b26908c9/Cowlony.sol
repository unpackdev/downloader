// SPDX-License-Identifier: MIT
// Creator: https://github.com/cowlony-org

pragma solidity ^0.8.4;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721ABurnable.sol";
import "./AllowlistSale.sol";
import "./ProxyRegistry.sol";

/**
 * @title Cowlony contract
 * @dev Extends ERC721A
 */
contract Cowlony is ERC721ABurnable, AllowlistSale, Ownable, AccessControlEnumerable, ReentrancyGuard {
    using ECDSA for bytes32;

    /**
    @notice Role of administrative users allowed to expel a Cows from grazing.
    @dev See expelFromGrazing().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    /**
     @notice collection and contract meta data
     */
    uint256 public COLLECTION_SIZE = 4998;
    string public PROVENANCE_HASH;
    string public baseURI;
    string private _contractURI;
    uint256 private defaultPublicSaleId;

    constructor(
        string memory name,
        string memory symbol,
        string memory provenance,
        string memory initBaseURI,
        string memory initContractURI,
        uint256 _defaultPublicSaleId,
        address payable _beneficiary
    ) ERC721A(name, symbol) {
        PROVENANCE_HASH = provenance;
        baseURI = initBaseURI;
        _contractURI = initContractURI;
        defaultPublicSaleId = _defaultPublicSaleId;
        beneficiary = _beneficiary;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // allowlist sale 
        _addSale(1, SaleConfig(1655913600, 1655917200, 20000000000000000, 5, 0xe12e7B6DDA6bC392b8441240459f7960E016D7Cb, false, false, true));
        // public sale
        _addSale(2, SaleConfig(1655917200, 1656090000, 40000000000000000, 5, address(0), true, false, true));
        // freelist
        _addSale(3, SaleConfig(1656090000, 1656104400, 0, 1, 0x842404201Be7CC0bc01f2afe9aF49dFe1A70Bf64, false, true, true));

        // test sale only for one test mint after contract deploy
        _addSale(42, SaleConfig(1655895600, 1655906400, 20000000000000000, 5, 0x83C6A23e0bBB11C17cC25dA0F5e3B36D64470deb, false, false, true));
    }

    // setup sales

    /**
    @dev creates allowlist config with the given id
    */
    function addSale(
        uint256 id,
        uint256 startDate,
        uint256 endDate,
        uint256 price,
        uint256 quantityLimit,
        address signer,
        bool checkUsedKeys) external onlyOwner {

        _addSale(id, SaleConfig({
            startDate: startDate,
            endDate: endDate,
            price: price,
            quantityLimit: quantityLimit,
            signer: signer,
            isPublicSale: false,
            checkUsedKeys: checkUsedKeys,
            exists: true
        }));
    }

    /**
    @dev creates publicSale config with the given id
    */
    function addPublicSale(
        uint256 id,
        uint256 startDate,
        uint256 endDate,
        uint256 price,
        uint256 quantityLimit) external onlyOwner {

        _addSale(id, SaleConfig({
            startDate: startDate,
            endDate: endDate,
            price: price,
            quantityLimit: quantityLimit,
            signer: address(0),
            isPublicSale: true,
            checkUsedKeys: false,
            exists: true
        }));
    }

    /**
    @dev removes the given sale id
    */
    function removeSale(uint256 id) external onlyOwner {
        _removeSale(id);
    }

    // mint functions

    /**
    @notice mints with verifying the provided key and saleId
    *       you can get your saleKey and saleId on cowlony.io
    *       this function handles both the free and allowlist mints
    */
    function allowlistMint(uint256 quantity, bytes calldata saleKey, uint256 saleId) external payable nonReentrant {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "purchase would exceed max supply of Cows");
        verify(quantity, saleKey, saleId);
        _safeMint(msg.sender, quantity);
    }

    /**
    @notice mints on public sale without verifying any key
    */
    function publicMint(uint256 quantity) external payable nonReentrant {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "purchase would exceed max supply of Cows");
        verifyPublicSale(quantity, defaultPublicSaleId);
        _safeMint(msg.sender, quantity);
    }

    /**
    @dev owner mint to fill up our treasury
    */
    function ownerMint(uint256 quantity, address recipient) external onlyOwner nonReentrant {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "purchase would exceed max supply of Cows");
        _safeMint(recipient, quantity);
    }

    // metadata

    function setProvenance(string calldata provenance) external onlyOwner {
        PROVENANCE_HASH = provenance;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setDefaultPublicSaleId(uint256 saleId) external onlyOwner {
        defaultPublicSaleId = saleId;
    }

    function getDefaultPublicSaleId() public view returns (uint256) {
        return defaultPublicSaleId;
    }

    // OpenSeaFreeListing

    /**
    @dev configurations, feature switch and address
    */
    bool public openSeaProxyOn = true;
    address public openSeaProxy = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    /**
    @notice When openSeaProxyOn no need to manually whitelist the OpenSea proxy to be able to list an item,
    *       it is whitelisted by us.
    */
    function isApprovedForAll(address _owner, address operator) public view override  returns (bool) {
        if (openSeaProxyOn) {
            ProxyRegistry openSeaProxyRegistry = ProxyRegistry(openSeaProxy);
            if (address(openSeaProxyRegistry.proxies(_owner)) == operator) return true;
        }

        return super.isApprovedForAll(_owner, operator);
    }

    /**
    @dev set the status of openSeaProxyOn
    */
    function setOpenSeaProxyStatus(bool status) external onlyOwner {
        openSeaProxyOn = status;
    }

    /**
    @dev set OpenSea's proxy address, probably will be never used
    */
    function setOpenSeaProxyAddress(address _address) external onlyOwner {
        openSeaProxy = _address;
    }

    
    // grazing based on the Moonbirds nesting
    // https://etherscan.io/token/0x23581767a106ae21c074b2276D25e5C3e136a68b

    /**
    @dev tokenId to active grazing start time (0 = not grazing).
    */
    mapping(uint256 => uint256) private grazingStarted;

    /**
    @dev Cumulative per-token all time grazing, excluding the current period.
    */
    mapping(uint256 => uint256) private grazingTotal;

    /**
    @dev Longest continuous grazing streak, excluding the current period.
    */
    mapping(uint256 => uint256) private grazingMax;

    /**
    @notice Returns the length of time, in seconds, that the Cow has been grazing.
    @dev Grazing is tied to a specific Cow, not to the owner, so it doesn't reset after a sale.
    @return grazing Whether the Cow is currently grazing. MAY be true with zero current nesting if
    *       in the same block as grazing began.
    @return current Zero if not currently grazing, otherwise the length of time since the most recent
    *       grazing began.
    @return total Total period of time for which the Cow has been grazing across its life, including
    *       the current period.
    @return max Longest continuous period of time for which the Cow has been grazing across its life,
    *       including the current period.
    */
    function grazingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool grazing,
            uint256 current,
            uint256 total,
            uint256 max
        ) {
            uint256 start = grazingStarted[tokenId];
            if (start != 0) {
                grazing = true;
                current = block.timestamp - start;
        }
        total = current + grazingTotal[tokenId];
        max = grazingMax[tokenId];
        max = max > current ? max : current;
    }

    /**
    @dev MUST only be modified by safeTransferWhileGrazing() if set to 1 then
    *    the _beforeTokenTransfer() block while grazing is disabled.
    */
    uint256 private grazingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the Cow is grazing, thus not resetting the grazing period.
    */
    function safeTransferWhileGrazing(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "cowlony: Only owner");
        grazingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        grazingTransfer = 1;
    }

    /**
    @dev Blocks normal transfers while grazing.
    */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                grazingStarted[tokenId] == 0 || grazingTransfer == 2,
                "cowlony: grazing"
            );
        }
    }

    /**
    @dev Emitted when a Cow begins grazing.
     */
    event GrazingStarted(uint256 indexed tokenId);

    /**
    @dev Emitted when a Cow stops grazing, either through standard means or by expulsion.
    */
    event GrazingStopped(uint256 indexed tokenId);

    /**
    @dev Emitted when a Cow is expelled from grazing.
    */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether grazing is currently allowed.
    @dev If false then grazing is blocked, but stopGrazing is always allowed.
    */
    bool public grazingOpen = false;

    /**
    @notice Toggles the `grazingOpen` flag.
    */
    function setGrazingOpen(bool open) external onlyOwner {
        grazingOpen = open;
    }

    /**
    @dev checks the Cow's owner
    */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "Not approved nor owner"
        );
        _;
    }

    /**
    @notice Changes the Cow's grazing status.
    */
    function toggleGrazing(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = grazingStarted[tokenId];
        if (start == 0) {
            require(grazingOpen, "cowlony: grazing unavailable");
            grazingStarted[tokenId] = block.timestamp;
            emit GrazingStarted(tokenId);
        } else {
            uint256 grazingTime = block.timestamp - start;
            grazingTotal[tokenId] += grazingTime;
            grazingStarted[tokenId] = 0;
            if (grazingMax[tokenId] < grazingTime) {
                grazingMax[tokenId] = grazingTime;
            } 
            emit GrazingStopped(tokenId);
        }
    }

    /**
    @dev Changes the listed Cows' grazing statuses.
    */
    function toggleGrazing(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleGrazing(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to terminate the grazing of a cow.
    @dev Listing a cow while it is grazing is prohabited, but checking this at a contract level is
    *    impossible, so we have to monitor with an off-chian service the large marketplaces and 
    *    terminate manually the grazing if needed. We have to do this since grazing cows could not
    *    be transfered, so enabling a listing of them could result false market prices.
    */
    function expelFromGrazing(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(grazingStarted[tokenId] != 0, "cowlony: not grazing");
        uint256 grazingTime = block.timestamp - grazingStarted[tokenId];
        grazingTotal[tokenId] += grazingTime;
        grazingStarted[tokenId] = 0;
        if (grazingMax[tokenId] < grazingTime) {
            grazingMax[tokenId] = grazingTime;
        } 
        emit GrazingStopped(tokenId);
        emit Expelled(tokenId);
    }

    // transfer revenues

    /**
    @notice Recipient of revenues.
    */
    address payable public beneficiary;

    /**
    @notice Sets the recipient of revenues
    */
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
    @notice Send revenues to beneficiary
    */
    function transferRevenues() external onlyOwner {
        require(beneficiary != address(0), "No beneficiary address defined");
        (bool success, ) = beneficiary.call{value: address(this).balance}("Sending revenues from cowlony");
        require(success, "Transfer failed.");
    }

    /**
    @notice Limits the COLLECTION_SIZE to the current totalSupply
    */
    function burnUnsoldCows() external onlyOwner {
        COLLECTION_SIZE = totalSupply();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}