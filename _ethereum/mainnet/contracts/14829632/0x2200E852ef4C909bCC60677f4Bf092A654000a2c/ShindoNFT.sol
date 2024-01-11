// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ERC721AUpgradeable.sol";
import "./MerkleDistributor.sol";

contract ShindoNFT is
    Initializable,
    ERC721AUpgradeable,
    MerkleDistributor,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 public MAX_SUPPLY;
    uint256 public MAX_ALLOWLIST_MINT; // TOTAL amount allowed to be minted during whitelisting
    uint256 public MAX_PUBLIC_MINT; // Amount allowed to be minted in a single transaction
    uint256 public TOTAL_MINTABLE_AMOUNT; // Total amount allowed to be minted
    uint256 public PRICE_PER_TOKEN;

    string private _baseTokenURI;
    bool public saleActive;

    string private unrevealedUrl;
    address payable public teamAddress;
    address payable public devAddress;
    bytes32 public version;

    function initialize() public initializer {
        __ERC721AUpgradeable_init("Shindo", "SHND");
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        version = "1.0";

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        MAX_SUPPLY = 5555;
        MAX_PUBLIC_MINT = 2;

        teamAddress = payable(0xfFadC02B18bF4EA2B6B12F88A0c80Ba1D2433Ac7); 
        devAddress = payable(0xdd148b045546A6ee9A4eA313813136DfFeD2c947);

        unrevealedUrl = "https://ipfs.io/ipfs/QmX5FGVgtF8JJ3GeiF3i97SSFeFhB8vsXHjfFu1iucDeK1/unrevealed.json";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : unrevealedUrl;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function setMaxSupply(uint256 number)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_SUPPLY = number;
    }

    function setUnrevealedUrl(string memory _string)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unrevealedUrl = _string;
    }

    function setMaxPublicMint(uint256 number)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_PUBLIC_MINT = number;
    }

    function setTotalMintableAmount(uint256 number)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        TOTAL_MINTABLE_AMOUNT = number;
    }

    function setPricePerToken(uint256 number)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PRICE_PER_TOKEN = number;
    }

    modifier ableToMint(uint256 numberOfTokens) {
        require(
            _totalMinted() + numberOfTokens < MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        _;
    }

    modifier isPublicSaleActive() {
        require(saleActive, "Public sale is not active");
        _;
    }

    /**
     * @notice Allows the CONTRACT_ADMIN_ROLE to toggle the public sale
     *
     * Requirements
     * - Only the CONTRACT_ADMIN_ROLE can execute
     *
     */
    function setSaleActive() external onlyRole(CONTRACT_ADMIN_ROLE) {
        deactivateAllowList();
        saleActive = true;
        TOTAL_MINTABLE_AMOUNT = 2;
        PRICE_PER_TOKEN = 0.075 ether;
    }

    function deactivateSale() external onlyRole(CONTRACT_ADMIN_ROLE) {
        saleActive = false;
    }

    /**
     * @notice Allows the CONTRACT_ADMIN_ROLE to toggle the whitelist sale
     *
     * Requirements
     * - Only the CONTRACT_ADMIN_ROLE can execute
     *
     */
    function setAllowListActive() external onlyRole(CONTRACT_ADMIN_ROLE) {
        _setAllowListActive(true);
        TOTAL_MINTABLE_AMOUNT = 2;
        PRICE_PER_TOKEN = 0.06 ether;
    }

    function deactivateAllowList() public onlyRole(CONTRACT_ADMIN_ROLE) {
        _setAllowListActive(false);
    }

    /**
     * @notice Allows the CONTRACT_ADMIN_ROLE to set whitelisted users with a merkle root
     *
     * Requirements
     * - Only the CONTRACT_ADMIN_ROLE can execute
     *
     * @param merkleRoot The root containing all the whitelisted users
     */
    function setAllowList(bytes32 merkleRoot)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        _setAllowList(merkleRoot);
    }

    /**
     * @notice Allows the CONTRACT_ADMIN_ROLE to set the base token URI
     *
     * Requirements
     * - Only the CONTRACT_ADMIN_ROLE can execute
     *
     * @param baseURI_ The base token URI
     */
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Allows users to check the supported interfaces
     *
     * @param interfaceId The id of the interface to check
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Allows the whitelisted addresses to mint NFTs
     *
     * Requirements
     * - isAllowListActive must be true
     * - Must be on the whitelist (ableToClaim)
     * - Minting must not exceed MAX_SUPPLY
     * - Must pay the right amount of Ether
     * - Must not mint more than the TOTAL_MINTABLE_AMOUNT
     *
     * @param numberOfTokens The number of NFTs to mint
     */
    function mintAllowList(uint256 numberOfTokens, bytes32[] memory merkleProof)
        external
        payable
        isAllowListActive
        ableToClaim(msg.sender, merkleProof)
        ableToMint(numberOfTokens)
        nonReentrant
    {
        require(
            numberOfTokens * PRICE_PER_TOKEN == msg.value,
            "Ether value sent is not correct"
        );
        require(
            _numberMinted(msg.sender) + numberOfTokens <= TOTAL_MINTABLE_AMOUNT,
            "Total mintable amount exceeded"
        );

        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @notice Allows the public to mint NFTs
     *
     * Requirements
     * - isPublicSaleActive must be true
     * - Minting must not exceed MAX_SUPPLY
     * - Minting must not exceed TOTAL_MINTABLE_AMOUNT
     * - Must not mint more than the MAX_PUBLIC_MINT
     * - Must pay the right amount of ether
     *
     * @param numberOfTokens The number of NFTs to mint
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        isPublicSaleActive
        ableToMint(numberOfTokens)
        nonReentrant
    {
        require(
            numberOfTokens <= MAX_PUBLIC_MINT,
            "Exceeded max token purchase"
        );
        require(
            numberOfTokens * PRICE_PER_TOKEN == msg.value,
            "Ether value sent is not correct"
        );
        // require(
        //     _numberMinted(msg.sender) + numberOfTokens <= TOTAL_MINTABLE_AMOUNT,
        //     "Total mintable amount exceeded"
        // );
        _safeMint(msg.sender, numberOfTokens);
    }

    function airdrop(address[] memory users, uint256[] memory numberOfTokens)
        external
        payable
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            users.length == numberOfTokens.length,
            "Number of users and number of tokens must be the same"
        );
        for (uint256 i = 0; i < users.length; i++) {
            require(
                _totalMinted() + numberOfTokens[i] < MAX_SUPPLY,
                "Purchase would exceed max tokens"
            );
            _safeMint(users[i], numberOfTokens[i]);
        }
    }

    /**
     * @notice Allows the DEFAULT_ADMIN_ROLE to withdraw Ether to respective parties
     *
     * Requirements
     * - Only DEFAULT_ADMIN_ROLE can execute
     *
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {

        uint256 devAmount = (address(this).balance / 100) * 5;
        (bool devSuccess, ) = devAddress.call{value: devAmount }(""); // 5% to developer
        require(devSuccess, "Transfer failed.");

        (bool success, ) = teamAddress.call{value: address(this).balance }(""); // 95% to rest of team
        require(success, "Transfer failed.");
    }

    function pause() public onlyRole(CONTRACT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(CONTRACT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    /**
     * @notice Allows the contract to receive Ether
     */
    receive() external payable {}

    /**
     * @notice Allows the UPGRADER_ROLE to upgrade the smart contract
     *
     * Requirements
     * - Only the UPGRADER_ROLE can execute
     *
     * @param newImplementation The address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
