// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;
import "./ERC721AUpgradable.sol";
import "./ERC721AUpgradableOwnersExplicit.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol"; 

contract GenesisClovers is Initializable, ERC721AUpgradable, ERC721AUpgradableOwnersExplicit, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// ============ Libraries ============

    /// @notice safe math for arithmetic operations
    using SafeMathUpgradeable for uint256;

    /// @notice upradeable addresses
    using AddressUpgradeable for address;

    /// ============ Constants ============

    /// @notice sale state
    enum SaleState { NOT_LIVE, PRESALE, PUBLIC_SALE }

    /// @notice total number of tokens in the collection
    uint256 public constant SUPPLY_MAX = 777;

    /// @notice total number of tokens for presale
    uint256 public constant PRESALE_MAX = 0;

    /// @notice total number of tokens for promotion and team reserve (multiple of PER_WALLET_MAX)
    uint256 public constant RESERVE_MAX = 100;

    /// @notice max mints per wallet
    uint256 public constant PER_WALLET_MAX = 10;

    /// @notice mint price of tokens
    uint256 public constant MINT_PRICE = 0 ether;


    /// ============ Events ============

    event Created(address indexed to, uint256 amount);


    // ============ Mutable storage ============

    /// @notice Current state of sale
    SaleState public state;

    /// @notice Whether collection has been revealed
    bool public revealed;

    /// @notice Random offset
    uint256 public offset;

    /// @notice ERC721-presale inclusion root
    bytes32 public presaleMerkleRoot;


    // ============ Private storage ============

    /// @notice base URI for tokens
    string private _baseTokenURI;

    /// @notice number of reserved team tokens
    uint256 private _reservedTeamTokens;

    // ============ Initialization ============

    /// @notice main initializer for contract
    function initialize() public initializer {
        __erc721a_init("GenesisClovers", "GENESIS-CLOVERS");
        __Ownable_init();
        __ReentrancyGuard_init();
        __genesisClovers_init_unchained();
    }

    // @notice local initializer
    function __genesisClovers_init_unchained() internal onlyInitializing {
        state = SaleState.NOT_LIVE;
        offset = SUPPLY_MAX;
    }

    /// @notice start tokens at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ============ Sale ============

    /// @notice Allows presale minting of tokens if address is part of merkle tree
    /// @param quantity number of tokens to mint
    /// @param maxQuantity max number of quantity of the user
    /// @param proof merkle proof to prove address and token mint count are in tree
    function presaleMint(
        uint256 quantity,
        uint256 maxQuantity,
        bytes32[] calldata proof
    ) external payable isMintValid(quantity, maxQuantity) isPresaleLive() {
        require(_mintOf(msg.sender) == 0, "GC/invalid-double-mint");
        require(
            MerkleProofUpgradeable.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender, maxQuantity))),
            "GC/invalid-address-proof"
        );
        _safeMint(msg.sender, quantity);
        emit Created(msg.sender, quantity);
    }

    /// @notice Allows public minting of tokens
    /// @param quantity number of tokens to mint
    /// @dev user can only mint less than PER_WALLET_MAX of tokens
    function publicMint(uint256 quantity)
        external
        payable
        isMintValid(quantity, PER_WALLET_MAX)
        isPublicSaleLive()
    {
        _safeMint(msg.sender, quantity);
        emit Created(msg.sender, quantity);
    }

    /// @notice force override the merkle root used in presale mint
    /// @param _presaleMerkleRoot root of the merklelized whitelist
    function setMintMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    /// @notice ensures that minters need valid quantity + value to mint
    modifier isMintValid(uint256 quantity, uint256 maxQuantity) {
        require(tx.origin == msg.sender, "GC/invalid-mint-caller");
        require(totalSupply().add(quantity) <= SUPPLY_MAX, "GC/invalid-total-supply");
        require(quantity > 0, "GC/invalid-quantity-value");
        
        if (MINT_PRICE > 0) {
            require(msg.value == MINT_PRICE.mul(quantity), "GC/invalid-mint-value");
            require(msg.value > 0, "GC/invalid-value-lower-boundary");
        } else {
            require(msg.value == 0, "GC/invalid-value");
        }
        
        require(
            _mintOf(msg.sender).add(quantity) <= maxQuantity,
            "GC/invalid-quantity-upper-boundary"
        );
        _;
    }

    /// @notice used to check the whether Presale is live
    modifier isPresaleLive() {
        require(state == SaleState.PRESALE, "GC/presale-not-live");
        _;
    }

    /// @notice used to check the whether Public sale is live
    modifier isPublicSaleLive() {
        require(state == SaleState.PUBLIC_SALE, "GC/public-sale-not-live");
        _;
    }

    /// @notice set the sale state (Admin)
    function setSaleState(SaleState _state) external onlyOwner {
        state = _state;
    }

    /// =========== Metadata ===========

    /// @notice set the new baseURI to change the tokens metadata  (Admin)
    function setBaseURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice core metadata baseURI used for tokens metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice baseURI used for tokens metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "GC/nonexistant-token-uri");
        uint256 shiftedTokenId = tokenId.add(offset).mod(SUPPLY_MAX);
        return string(abi.encodePacked(_baseURI(), StringsUpgradeable.toString(shiftedTokenId)));
    }

    /// =========== Randomness ===========

    /// @notice configure offset (Admin)
    /// @param nonce a nonce used for random number generation
    function setOffset(uint256 nonce) external onlyOwner returns (uint256) {
        require(offset == SUPPLY_MAX, "GC/offset-already-declared");

        // Force offset to nonce
        offset = nonce.mod(SUPPLY_MAX);

        // uint256 randomness = _getRandomValue(nonce);
        // offset = randomness.mod(SUPPLY_MAX);

        return offset;
    }

    /// @notice get random value
    function _getRandomValue(uint256 nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, nonce, block.timestamp)));
    }

    /// =========== Dev ===========

    /// @notice used by owner to mint reserved NFTs
    /// @param quantity the number of quantity to batch mint
    function reserveMint(uint256 quantity) external onlyOwner {
        require(totalSupply().add(quantity) <= RESERVE_MAX, "GC/invalid-reserve-supply");
        require(_reservedTeamTokens.add(quantity) <= RESERVE_MAX, "GC/not-enough-team-tokens");

        uint256 maxBatchSize = PER_WALLET_MAX;
        require(quantity.mod(maxBatchSize) == 0, "GC/invalid-batch-multiple");
        
        uint256 blocks = quantity.div(maxBatchSize);
        for (uint256 i = 0; i < blocks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        
        _reservedTeamTokens = _reservedTeamTokens.add(quantity);
        emit Created(msg.sender, quantity);
    }

    /// @notice withdraws the ether in the contract to owner
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "GC/invalid-withdraw-money");
    }

    /// @notice sets the owners quantity explicity
    /// @dev eliminate loops in future calls of ownerOf()
    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    /// @notice internally returns the number of mints of an address
    function _mintOf(address _owner) internal view returns (uint256) {
        return _numberMinted(_owner);
    }

    /// @notice returns the number of mints of an address
    function mintOf(address _owner) public view returns (uint256) {
        return _mintOf(_owner);
    }

    /// @notice total minted
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
}