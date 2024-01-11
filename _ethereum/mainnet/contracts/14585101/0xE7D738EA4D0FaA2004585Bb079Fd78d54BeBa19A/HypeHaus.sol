// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721ABurnable.sol";
import "./HypeHausAccessControl.sol";

contract HypeHaus is ERC721ABurnable, HypeHausAccessControl, ReentrancyGuard {
    using Strings for uint256;

    // ====== TYPES ======

    /**
     * @dev An enumeration of all the possible sales the contract may be in.
     *
     * A `Closed` state indicates that the contract has either not begun
     * the pre-sale (i.e. `Community` sale) or has finished the `Public` sale.
     * As a result, the contract will not accept any mints if `activeSale` is
     * set to `Closed`.
     */
    enum Sale {
        Closed,
        Community,
        Public
    }

    /**
     * @dev A struct that informs the total amount of HYPEHAUSes claimed during
     * each sale.
     */
    struct TotalClaimedPerSale {
        uint256 communitySale;
        uint256 publicSale;
    }

    // ====== PUBLIC STATE VARIABLES ======

    uint8 public maxMintAlpha = 3;
    uint8 public maxMintHypelister = 2;
    uint8 public maxMintHypemember = 1;
    uint8 public maxMintPublic = 2;

    uint256 public communitySalePrice = 0.05 ether;
    uint256 public publicSalePrice = 0.08 ether;

    Sale public activeSale = Sale.Closed;
    uint256 public maxSupply;

    // ====== INTERNAL STATE VARIABLES ======

    string internal _baseTokeURI;
    bool internal _baseTokenURIHasExtension;
    address internal _teamWalletAddress;
    mapping(address => TotalClaimedPerSale) internal _totalClaimed;

    bytes32 internal _alphaMerkleRoot;
    bytes32 internal _hypelisterMerkleRoot;
    bytes32 internal _hypememberMerkleRoot;

    // ====== CONSTRUCTOR ======

    constructor(
        uint256 maxSupply_,
        string memory baseTokeURI,
        address teamWalletAddress
    ) ERC721A("HYPEHAUS", "HYPE") {
        maxSupply = maxSupply_;
        _baseTokeURI = baseTokeURI;
        _baseTokenURIHasExtension = false;
        _teamWalletAddress = teamWalletAddress;
    }

    // ====== MODIFIERS ======

    modifier isCommunitySaleActive() {
        require(activeSale == Sale.Community, "HH_COMMUNITY_SALE_NOT_ACTIVE");
        _;
    }

    modifier isPublicSaleActive() {
        require(activeSale == Sale.Public, "HH_PUBLIC_SALE_NOT_ACTIVE");
        _;
    }

    modifier isSupplyAvailable(uint256 amount) {
        require((_totalMinted() + amount) <= maxSupply, "HH_SUPPLY_EXHAUSTED");
        _;
    }

    modifier isValidMintAmount(uint256 amount, uint256 maximum) {
        require(amount >= 1 && amount <= maximum, "HH_INVALID_MINT_AMOUNT");
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 amount) {
        require(msg.value >= price * amount, "HH_INSUFFICIENT_FUNDS");
        _;
    }

    modifier hasNotClaimedBeforeInCommunitySale(uint256 amount) {
        require(
            _totalClaimed[msg.sender].communitySale == 0,
            "HH_ALREADY_CLAIMED"
        );
        _totalClaimed[msg.sender].communitySale = amount;
        _;
    }

    modifier hasNotClaimedMaximumInPublicSale(uint256 amount) {
        require(
            _totalClaimed[msg.sender].publicSale + amount <= maxMintPublic,
            "HH_ALREADY_CLAIMED"
        );
        _totalClaimed[msg.sender].publicSale += amount;
        _;
    }

    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "HH_VERIFICATION_FAILURE"
        );
        _;
    }

    // ====== MINTING FUNCTIONS ======

    /**
     * @dev Mints `amount` number of HYPEHAUSes to `receiver`.
     *
     * As the name suggests, this function does not validate the receiver or the
     * provided amount, except ensuring that there is enough supply available
     * to mint `amount` HYPEHAUSes.
     *
     * This function is useful for manually gifting HYPEHAUSes to someone. It
     * requires that the caller have at least the `OPERATOR_ROLE` role.
     */
    function mintUnchecked(address receiver, uint256 amount)
        external
        onlyOperator
        isSupplyAvailable(amount)
    {
        if (activeSale == Sale.Community) {
            _totalClaimed[msg.sender].communitySale += amount;
        } else if (activeSale == Sale.Public) {
            _totalClaimed[msg.sender].publicSale += amount;
        }
        _mintToAddress(receiver, amount);
    }

    /**
     * @dev Mints `amount` number of HYPEHAUSes as an ALPHA.
     *
     * This function requires several prerequisites to be met for `msg.sender`
     * to successfully mint HYPEHAUSes as an ALPHA:
     *
     *   - The community sale is currently active;
     *   - There is enough supply available to mint `amount` HYPEHAUSes;
     *   - `msg.sender` has not already claimed any amount of HYPEHAUSes during
     *     the community sale;
     *   - The provided `amount` is a value within the inclusive range of 1 and
     *     the maximum mint amount for ALPHAs (3 by default);
     *   - Sufficient amount of ETH is provided to purchase `amount` number of
     *     HYPEHAUSes at a discounted price; and
     *   - It can be verified that `msg.sender` is an ALPHA using the provided
     *     `merkleProof`.
     *
     * If any of the above prerequisites are not met, this function will reject
     * the mint and throw an error.
     */
    function mintAlpha(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        isCommunitySaleActive
        isSupplyAvailable(amount)
        isValidMintAmount(amount, maxMintAlpha)
        isCorrectPayment(communitySalePrice, amount)
        hasNotClaimedBeforeInCommunitySale(amount)
        isValidMerkleProof(merkleProof, _alphaMerkleRoot)
    {
        _mintToAddress(msg.sender, amount);
    }

    /**
     * @dev Mints `amount` number of HYPEHAUSes as a HYPELISTER.
     *
     * This function has identical prerequisites to `mintAlpha` to be met for
     * `msg.sender` to successfully mint HYPEHAUSes as a HYPELISTER, with the
     * exception of the following:
     *
     *   - The provided `amount` is a value within the inclusive range of 1 and
     *     the maximum mint amount for HYPELISTERs (2 by default)
     *
     * If any of the prerequisites are not met, this function will reject the
     * mint and throw an error.
     */
    function mintHypelister(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        isCommunitySaleActive
        isSupplyAvailable(amount)
        isValidMintAmount(amount, maxMintHypelister)
        isCorrectPayment(communitySalePrice, amount)
        hasNotClaimedBeforeInCommunitySale(amount)
        isValidMerkleProof(merkleProof, _hypelisterMerkleRoot)
    {
        _mintToAddress(msg.sender, amount);
    }

    /**
     * @dev Mints `amount` number of HYPEHAUSes as a HYPEMEMBER.
     *
     * This function has identical prerequisites to `mintAlpha` to be met for
     * `msg.sender` to successfully mint HYPEHAUSes as a HYPEMEMBER, with the
     * exception of the following:
     *
     *   - The provided `amount` is a value within the inclusive range of 1 and
     *     the maximum mint amount for HYPEMEMBERs (1 by default)
     *
     * If any of the prerequisites are not met, this function will reject the
     * mint and throw an error.
     */
    function mintHypemember(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        isCommunitySaleActive
        isSupplyAvailable(amount)
        isValidMintAmount(amount, maxMintHypemember)
        isCorrectPayment(communitySalePrice, amount)
        hasNotClaimedBeforeInCommunitySale(amount)
        isValidMerkleProof(merkleProof, _hypememberMerkleRoot)
    {
        _mintToAddress(msg.sender, amount);
    }

    /**
     * @dev Mints `amount` number of HYPEHAUSes as a member of the public.
     *
     * This function requires several prerequisites to be met for `msg.sender`
     * to successfully mint HYPEHAUSes as a member of the public:
     *
     *   - The public sale is currently active;
     *   - There is enough supply available to mint `amount` HYPEHAUSes;
     *   - `msg.sender` has not already claimed any amount of HYPEHAUSes during
     *     the public sale;
     *   - The provided `amount` is a value within the inclusive range of 1 and
     *     the maximum mint amount for members of the public (2 by default); and
     *   - Sufficient amount of ETH is provided to purchase `amount` number of
     *     HYPEHAUSes at full price.
     *
     * If any of the above is not met, this function will throw an error.
     */
    function mintPublic(uint256 amount)
        external
        payable
        nonReentrant
        isPublicSaleActive
        isSupplyAvailable(amount)
        isValidMintAmount(amount, maxMintPublic)
        isCorrectPayment(publicSalePrice, amount)
        hasNotClaimedMaximumInPublicSale(amount)
    {
        _mintToAddress(msg.sender, amount);
    }

    /**
     * @dev Internal function that mints `amount` number of HYPEHAUSes to
     * `receiver`.
     */
    function _mintToAddress(address receiver, uint256 amount) internal {
        // The second argument of `_safeMint` in AZUKI's `ERC721A` contract
        // expects the amount to mint, not a token ID.
        _safeMint(receiver, amount);
    }

    // ====== OVERRIDES ======

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokeURI;
    }

    // ====== EXTERNAL/PUBLIC FUNCTIONS ======

    /**
     * @dev Returns the address of the contract's owner.
     *
     * This function is required by OpenSea. Normally, you'd inherit from
     * `Ownable` and get the owner from there, but since we're using
     * `AccessControl`, we'll return the only user with `DEFAULT_ADMIN_ROLE`.
     */
    function owner() external view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Reports the count of all the valid HYPEHAUSes tracked by this
     * contract.
     *
     * @return uint256 The count of minted HYPEHAUSes tracked by this contract,
     * where each one of them has an assigned and queryable owner not equal to
     * the zero address.
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Returns the URI of a HYPEHAUS with the given token ID.
     *
     * Throws if the given token ID is not a valid (i.e. it does not point to a
     * minted HYPEHAUS).
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "HH_NONEXISTENT_TOKEN");
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    tokenId.toString(),
                    // No file extension for masked token URI since it points to
                    // a URL to an API that generates a JSON file on demand.
                    _baseTokenURIHasExtension ? ".json" : ""
                )
            );
    }

    // ====== ONLY-WITHDRAWER FUNCTIONS ======

    /**
     * @dev Transfers any pending balance available in the contract to the
     * designated team wallet address.
     */
    function withdraw() external onlyWithdrawer {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_teamWalletAddress).call{value: balance}("");
        require(success, "HH_TRANSFER_FAILURE");
    }

    // ====== ONLY-OPERATOR FUNCTIONS ======

    function setMaxMintAlpha(uint8 newMax) external onlyOperator {
        maxMintAlpha = newMax;
    }

    function setMaxMintHypelister(uint8 newMax) external onlyOperator {
        maxMintHypelister = newMax;
    }

    function setMaxMintHypemember(uint8 newMax) external onlyOperator {
        maxMintHypemember = newMax;
    }

    function setMaxMintPublic(uint8 newMax) external onlyOperator {
        maxMintPublic = newMax;
    }

    function setCommunitySalePrice(uint256 newPrice) external onlyOperator {
        communitySalePrice = newPrice;
    }

    function setPublicSalePrice(uint256 newPrice) external onlyOperator {
        publicSalePrice = newPrice;
    }

    function setActiveSale(Sale newSale) external onlyOperator {
        activeSale = newSale;
    }

    function setMaxSupply(uint256 newSupply) external onlyOperator {
        maxSupply = newSupply;
    }

    function setBaseTokenURI(string memory newTokenURI, bool hasExtension)
        external
        onlyOperator
    {
        _baseTokeURI = newTokenURI;
        _baseTokenURIHasExtension = hasExtension;
    }

    function setTeamWalletAddress(address newAddress) external onlyOperator {
        _teamWalletAddress = newAddress;
    }

    function setAlphaMerkleRoot(bytes32 newRoot) external onlyOperator {
        _alphaMerkleRoot = newRoot;
    }

    function setHypelisterMerkleRoot(bytes32 newRoot) external onlyOperator {
        _hypelisterMerkleRoot = newRoot;
    }

    function setHypememberMerkleRoot(bytes32 newRoot) external onlyOperator {
        _hypememberMerkleRoot = newRoot;
    }

    // ====== MISCELLANEOUS ======

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
