// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./MerkleProof.sol";
import "./Strings.sol";

import "./ERC721AQueryableUpgradeable.sol";

import "./ISiku.sol";

contract Siku is
    ISiku,
    ERC721AQueryableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    uint256 public MINT_PRICE;
    uint256 public MAX_LIMIT;
    string public baseTokenURI;
    uint256 public mintStart;
    uint256 public MAX_LIMIT_PER_WALLET;

    // Whitelist
    bool public enabledGroup1;
    bool public enabledGroup2;
    uint256 public priceGroup1;
    uint256 public priceGroup2;
    bytes32 public merkleRoot1;
    bytes32 public merkleRoot2;

    mapping(address => uint256) public whitelistMinted;

    function initialize (
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _mintPrice,
        uint256 _maxLimit,
        uint256 _maxPerWallet,
        uint256 _whitelistPrice1,
        uint256 _whitelistPrice2,
        bytes32 _merkleRoot1,
        bytes32 _merkleRoot2
    ) public initializerERC721A initializer {       
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721A_init(_name, _symbol);

        baseTokenURI = _baseTokenURI;
        MINT_PRICE = _mintPrice;
        MAX_LIMIT = _maxLimit;
        MAX_LIMIT_PER_WALLET = _maxPerWallet;

        priceGroup1 = _whitelistPrice1;
        priceGroup2 = _whitelistPrice2;
        merkleRoot1 = _merkleRoot1;
        merkleRoot2 = _merkleRoot2;

    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    /**
     * @notice Increases MAX_LIMIT by _increment
     */
    function increaseLimit(uint256 _increment) public onlyOwner {
        MAX_LIMIT = MAX_LIMIT + _increment;
    }

    /**
     * @notice set MAX_LIMIT_PER_WALLET to _maxLimitPerWallet
     */
    function setLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
        MAX_LIMIT_PER_WALLET = _maxLimitPerWallet;
    }

    /**
     * @notice If _enabled, only allows whitelisted addresses in group1 to mint
     */
    function enableMintGroup1(bool _enabled) public onlyOwner {
        enabledGroup1 = _enabled;
    }

    /**
     * @notice If _enabled, only allows whitelisted addresses in group2 to mint
     */
    function enableMintGroup2(bool _enabled) public onlyOwner {
        enabledGroup2 = _enabled;
    }

    /**
     * @notice Starts/reset minting for whitelisted addresses
     */
    function startMint() public onlyOwner {
        mintStart = block.timestamp;
    }

    /**
     * @notice Sets price for public mint
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    /**
     * @notice Sets price for whitelisted addresses in group1 to mint in decimals
     */
    function setPriceGroup1(uint256 _price) public onlyOwner {
        priceGroup1 = _price;
    }

    /**
     * @notice Sets price for whitelisted addresses in group2 to mint in decimals
     */
    function setPriceGroup2(uint256 _price) public onlyOwner {
        priceGroup2 = _price;
    }

    /**
     * @notice Sets merkleroot calculated on client side for group1
     */
    function setRoot1(bytes32 _merkleRoot1) public onlyOwner {
        merkleRoot1 = _merkleRoot1;
    }

    /**
     * @notice Sets merkleroot calculated on client side for group2
     */
    function setRoot2(bytes32 _merkleRoot2) public onlyOwner {
        merkleRoot2 = _merkleRoot2;
    }

    /**
     * @notice Withdraws accumulated ether balance to _beneficiary
     */
    function withdraw(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "Siku: provide valid address");
        uint balance = address(this).balance;
        payable(_beneficiary).transfer(balance);
    }

    /**
     * @notice Withdraws accumulated ether balance to _beneficiary
     */
    function ownerMint(uint256 quantity, address beneficiary) public onlyOwner {
        require(beneficiary != address(0), "Siku: provide valid address");
        require(quantity > 0, "Siku: quantity cannot be zero");
        require(
            _totalMinted()+ quantity <= MAX_LIMIT,
            "Siku: Mint limit reached"
        );
        _safeMint(beneficiary, quantity);
    }

    function verifyMerkleProof(bytes32[] memory proof, bytes32 root)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    function whitelistedOnlyMint() public view returns (bool) {
        return block.timestamp <= mintStart + 3 hours;
    }

    /**
     * @notice Mint nfts based on quantity
     *
     */
    function mint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        override
    {
        require(quantity > 0, "Siku: quantity cannot be zero");
        require(
            _totalMinted()+ quantity <= MAX_LIMIT,
            "Siku: Mint limit reached"
        );
        require(mintStart > 0, "Siku: Minting not started");

        uint256 price = MINT_PRICE;
        // Only whitelisted minting allowed for first 2 days
        if (whitelistedOnlyMint()) {
            require(whitelistMinted[msg.sender] + quantity <= MAX_LIMIT_PER_WALLET, "Siku: Wallet limit reached");

            if (enabledGroup1 && verifyMerkleProof(_merkleProof, merkleRoot1)) {
                price = priceGroup1;
            } else if (enabledGroup2 && verifyMerkleProof(_merkleProof, merkleRoot2)) {
                price = priceGroup2;
            } else {
                revert onlyWhitelistedAllowed();
            }

            whitelistMinted[msg.sender] = whitelistMinted[msg.sender] + quantity;
        }


        uint256 finalPrice = quantity * price;
        require(msg.value >= finalPrice, "Siku: Insufficient amount");

        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Change the base URI for returning metadata
     *
     * @param _baseTokenURI the respective base URI
     */
    function setBaseURI(string memory _baseTokenURI)
        external
        override
        onlyOwner
    {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Return the baseTokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }
}
