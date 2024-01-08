//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./ECDSAUpgradeable.sol";

import "./VRFConsumerBaseUpgradeable.sol";

import "./RandomLib.sol";

contract PropertyNFT is
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    VRFConsumerBaseUpgradable
{
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using RandomLib for RandomLib.Random;

    struct Whitelist {
        uint8 tier;
        uint8 cap;
    }

    // Max Supply
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant RESERVED = 200;

    // Mint Prices
    uint256 public constant LAUNCH_PRICE = 0.09 ether;
    uint256[] public PRIVATE_SALE_PRICES;
    uint256 public constant PARTNER_SALE_PRICE = 0.08 ether;

    // Wallet Restrictions
    uint8 public constant MAX_QUANTITY = 8; // maximum number of mint per transaction
    uint8 public constant WALLET_LIMIT_PUBLIC = 16; // to change
    mapping(address => bool) public whitelistedPartners;

    // Sales Timings
    uint256 public PRIVATE_SALE_START;
    uint256 public PUBLIC_SALE_START;

    // Treasury Address
    address payable public TREASURY;

    // Metadata
    string public baseTokenURI;
    string public notRevealedURI;
    bool public revealed;

    // Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;

    // PRIVATE VARIABLES
    mapping(address => uint8) private publicSaleMintedAmount; // number of NFT minted for each wallet during public sale
    mapping(address => uint8) private privateSaleMintedAmount;
    mapping(bytes => bool) private _nonceUsed; // nonce was used to mint already
    address private signerAddress;

    uint32[] private available;

    RandomLib.Random internal random;

    // Reserve Storage
    uint256[50] private ______gap;

    // ---------------------- MODIFIERS ---------------------------

    /// @dev Only EOA modifier
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "PropertyNFT: Only EOA");
        _;
    }

    // ---------------------- INITIALIZER -------------------------

    function __PropertyNFT_init(
        string memory _notRevealedUri,
        address _owner,
        address _treasury,
        uint256 _privateSaleStart,
        uint256 _publicSaleStart,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        address _signerAddress
    ) public initializer {
        __AccessControlEnumerable_init();
        __Ownable_init();
        __Pausable_init();
        __ERC721_init_unchained("PropertyNFT", "PP");
        __ERC721Enumerable_init();
        __VRFConsumableBase_init(_vrfCoordinator, _link);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(DEFAULT_ADMIN_ROLE, _treasury);
        notRevealedURI = _notRevealedUri;
        TREASURY = payable(_treasury);
        PRIVATE_SALE_START = _privateSaleStart;
        PUBLIC_SALE_START = _publicSaleStart;
        PRIVATE_SALE_PRICES = [0.08 ether, 0.0725 ether, 0.065 ether];
        keyHash = _keyHash;
        fee = _fee;
        signerAddress = _signerAddress;
        transferOwnership(_owner);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        if (!revealed) {
            return notRevealedURI;
        } else {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, tokenId.toString())
                    )
                    : "";
        }
    }

    // -------------------------- PUBLIC FUNCTIONS ----------------------------

    /// @dev Presale Mint
    function presaleMint(
        uint8 _mintAmount,
        uint8 tier,
        bytes memory nonce,
        bytes memory signature
    ) public payable onlyEOA whenNotPaused {
        require(isPresaleOpen(), "PropertyNFT: Presale Mint not open!");
        require(!_nonceUsed[nonce], "PropertyNFT: Nonce was used");
        require(
            isSignedBySigner(
                msg.sender,
                nonce,
                signature,
                signerAddress,
                _mintAmount,
                tier
            ),
            "PropertyNFT: Invalid signature"
        );
        require(tier > 0, "PropertyNFT: Whitelist Tier < 1.");
        require(tier <= 3, "PropertyNFT: Whitelist Tier > 3.");

        require(
            privateSaleMintedAmount[msg.sender] + _mintAmount <= tier,
            "PropertyNFT: Presale Limit Exceeded!"
        );

        require(
            msg.value == PRIVATE_SALE_PRICES[tier - 1] * _mintAmount,
            "PropertyNFT: Insufficient ETH!"
        );
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "PropertyNFT: Maximum Supply Reached!"
        );

        (bool success, ) = TREASURY.call{value: msg.value}(""); // forward amount to treasury wallet
        require(success, "PropertyNFT: Unable to forward message to treasury!");

        for (uint256 i = 0; i < _mintAmount; i++) {
            privateSaleMintedAmount[msg.sender]++;
            _mintRandom(msg.sender);
        }
    }

    /// @dev partner Mint
    function partnerMint(bytes memory nonce, bytes memory signature)
        public
        payable
        onlyEOA
        whenNotPaused
    {
        require(isPresaleOpen(), "PropertyNFT: Presale Mint not open!");
        require(!_nonceUsed[nonce], "PropertyNFT: Nonce was used");
        require(
            isSignedBySigner(msg.sender, nonce, signature, signerAddress, 0, 0),
            "PropertyNFT: Invalid signature"
        );
        require(
            whitelistedPartners[msg.sender] == false,
            "PropertyNFT: You have already minted!"
        );

        require(
            msg.value == PARTNER_SALE_PRICE,
            "PropertyNFT: Insufficient ETH!"
        );
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "PropertyNFT: Maximum Supply Reached!"
        );

        (bool success, ) = TREASURY.call{value: msg.value}(""); // forward amount to treasury wallet
        require(success, "PropertyNFT: Unable to forward message to treasury!");

        // Update whitelisted partner mint
        whitelistedPartners[msg.sender] = true;
        _mintRandom(msg.sender);
    }

    /// @dev Public sale
    function publicMint(uint8 _mintAmount)
        public
        payable
        onlyEOA
        whenNotPaused
    {
        require(
            (isPublicSaleOpen()),
            "PropertyNFT: Public sale has not started!"
        );
        require(
            publicSaleMintedAmount[msg.sender] + _mintAmount <=
                WALLET_LIMIT_PUBLIC,
            "PropertyNFT: Maximum amount of mints exceeded!"
        );
        require(
            _mintAmount <= MAX_QUANTITY,
            "PropertyNFT: Maximum mint amount per transaction exceeded!"
        );
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY - RESERVED,
            "PropertyNFT: Maximum Supply Reached!"
        );
        require(
            msg.value == LAUNCH_PRICE * _mintAmount,
            "PropertyNFT: Insufficient ETH!"
        );

        (bool success, ) = TREASURY.call{value: msg.value}(""); // forward amount to treasury wallet
        require(success, "PropertyNFT: Unable to forward message to treasury!");

        publicSaleMintedAmount[msg.sender] += _mintAmount;

        for (uint256 i; i < _mintAmount; i++) {
            _mintRandom(msg.sender);
        }
    }

    // ----------------- VIEW FUNCTIONS ------------------------

    /// @dev Returns mint count during private sale
    function privateSaleMintCount(address user) public view returns (uint256) {
        return privateSaleMintedAmount[user];
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /// @dev Check if Presale is Open
    function isPresaleOpen() public view returns (bool) {
        return
            block.timestamp >= PRIVATE_SALE_START &&
            block.timestamp < PUBLIC_SALE_START;
    }

    /// @dev Check if Public Sale is Open
    function isPublicSaleOpen() public view returns (bool) {
        return block.timestamp >= PUBLIC_SALE_START;
    }

    /// @dev Get Whitelist Price
    function getWhitelistPrice(uint8 tier) public view returns (uint256) {
        return PRIVATE_SALE_PRICES[tier - 1];
    }

    // ------------------ PURE FUNCTIONS ------------------------
    /// @dev Parse Bytes postal code form into array
    function parsePostalCode(bytes memory postalCode)
        public
        pure
        returns (uint8[4] memory)
    {
        return [
            uint8(postalCode[0]),
            uint8(postalCode[1]),
            uint8(postalCode[2]),
            uint8(postalCode[3])
        ];
    }

    /// @dev Parse token id into bytes form
    function getPostalCode(uint32 tokenId) public pure returns (bytes memory) {
        return abi.encodePacked(tokenId);
    }

    // ------------------ INTERNAL FUNCTIONS ------------------------

    /// @dev Sets baseURI
    function _setBaseURI(string memory _baseTokenURI) internal virtual {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Gets baseToken URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Initialize Randomness using chainlink
    function initializeRandomness()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /// @dev Callback function for Chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        RandomLib.setInitialRandom(random, randomness);
    }

    function _mintRandom(address user) internal {
        require(
            available.length > 0,
            "PropertyNFT: No more available Propertys"
        );
        uint256 randN = RandomLib.nextRandom(random);
        uint256 postalCode = available[randN % available.length];
        _removeFromAvailable(randN % available.length);
        _mint(user, postalCode);
    }

    // ------------------------ ADMIN FUNCTIONS ----------------------------

    /// @dev Set Available mints
    function pushAvailable(uint32[] memory _available)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < _available.length; i++) {
            available.push(_available[i]);
        }
    }

    /// @dev Reserve some NFTS
    function airdrop(address[] memory addressList)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < addressList.length; i++) {
            _mintRandom(addressList[i]);
        }
    }

    ///  @dev Pauses all token transfers.
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpauses all token transfers.
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function updateBaseURI(string memory _newBaseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _reveal();
        _setBaseURI(_newBaseURI);
    }

    /// @dev Emergency Function to withdraw ETH from this contract
    function withdrawToTreasury() public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = TREASURY.call{value: address(this).balance}("");
        require(success);
    }

    /// @dev Updates presale Start Time
    function updatePresaleStart(uint256 _startTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PRIVATE_SALE_START = _startTime;
    }

    /// @dev Emergency Function to withdraw ETH from this contract
    function updatePublicSaleStart(uint256 _startTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PUBLIC_SALE_START = _startTime;
    }

    // -------------------------- INTERNAL FUNCTIONS -----------------------------

    function _reveal() internal {
        revealed = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // ------------------------- PRIVATE FUNCTIONS ------------------------------

    /// @dev Checks if the the signature is signed by a valid signer
    function isSignedBySigner(
        address sender,
        bytes memory nonce,
        bytes memory signature,
        address _signerAddress,
        uint256 mintAmount,
        uint256 tier
    ) private pure returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(sender, nonce, mintAmount, tier)
        );
        return _signerAddress == hash.recover(signature);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId ==
            type(IAccessControlEnumerableUpgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _removeFromAvailable(uint256 index) private {
        require(index < available.length);
        available[index] = available[available.length - 1];
        available.pop();
    }

    function getAvailable()
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint32[] memory)
    {
        return available;
    }
}
