// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";

contract ZenFrogs is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;

    /**********************
     * Variables & events *
     **********************/

    // Constants
    uint16 public constant MAX_SUPPLY = 10000;

    // Whitelisted minting params, owner-updatable until frozen
    bytes32 public whitelistMerkleRoot;
    uint256 public whitelistStartBlock = type(uint256).max;
    uint256 public whitelistTokenAmount = 1;
    uint256 public whitelistTokenPrice = 0.08 ether;
    bool public whitelistParamsFrozen;

    // Public minting params, owner-updatable until frozen
    uint256 public mintingStartBlock = type(uint256).max;
    uint256 public mintingTokenAmount = 10;
    uint256 public mintingTokenPrice = 0.08 ether;
    bool public mintingParamsFrozen;

    // Metadata params, owner-updatable until frozen
    string public baseURI;
    string public prerevealURI;
    bool public metadataFrozen;

    // Remaining team reserve, managed by the contract
    uint8 public teamReserve = 100;

    // Token reveal flag, managed by the contract
    bool public tokensRevealed;

    event TokenReveal();

    /***************************
     * Contract initialization *
     ***************************/

    constructor(address[] memory _payees, uint256[] memory _shares)
        ERC721A("ZenFrogs", "ZENFROG")
        PaymentSplitter(_payees, _shares)
    {}

    /********************
     * Public functions *
     ********************/

    /**
     * Mint new tokens (all wallets)
     */
    function mint(uint8 amount)
        external
        payable
        onlyEOA
        paymentProvided(amount * mintingTokenPrice)
        activeAfterBlock(mintingStartBlock)
    {
        require(amount <= mintingTokenAmount, "Amount too high");
        require(amount <= availableSupply(), "Not enough tokens left");

        _mintFrogs(msg.sender, amount);
    }

    /**
     * Mint new tokens (whitelisted wallets)
     */
    function mintWhitelisted(uint8 amount, bytes32[] calldata merkleProof)
        external
        payable
        onlyEOA
        paymentProvided(amount * whitelistTokenPrice)
        activeAfterBlock(whitelistStartBlock)
    {
        require(amount <= whitelistTokenAmount, "Amount too high");
        require(amount <= availableSupply(), "Not enough tokens left");
        require(isWhitelisted(msg.sender, merkleProof), "Not whitelisted");

        _hasMinted[msg.sender] = true;
        _mintFrogs(msg.sender, amount);
    }

    /**
     * Get the metadata URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return
            tokensRevealed
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _revealedID(tokenId, _revealSeed).toString(),
                        ".json"
                    )
                )
                : prerevealURI;
    }

    /**
     * Check if a specified wallet is whitelisted for minting
     */
    function isWhitelisted(address wallet, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        return
            !_hasMinted[wallet] &&
            MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf);
    }

    /**
     * Get the remaining mintable supply
     */
    function availableSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply() - teamReserve;
    }

    /**
     * Generate the full list of post-reveal token IDs
     */
    function revealedIDs()
        public
        view
        returns (uint256[MAX_SUPPLY] memory sequence)
    {
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            sequence[i] = _revealedID(i, _revealSeed);
        }
    }

    /*******************
     * Admin functions *
     *******************/

    /**
     * Manually reveal tokens
     */
    function revealTokens() external onlyOwner {
        _revealTokens();
    }

    /**
     * Mint a token from the team reserve
     */
    function mintReserved(uint8 amount, address to) external onlyOwner {
        require(teamReserve >= amount, "Not enough left in team reserve");

        teamReserve -= amount;
        _mintFrogs(to, amount);
    }

    /*************************
     * Configuration setters *
     *************************/

    function setWhitelistMerkleRoot(bytes32 newRoot)
        external
        onlyOwner
        freezesOn(whitelistParamsFrozen)
    {
        whitelistMerkleRoot = newRoot;
    }

    function setWhitelistStartBlock(uint256 targetBlock)
        external
        onlyOwner
        freezesOn(whitelistParamsFrozen)
    {
        whitelistStartBlock = targetBlock;
    }

    function setWhitelistTokenAmount(uint256 newAmount)
        external
        onlyOwner
        freezesOn(whitelistParamsFrozen)
    {
        whitelistTokenAmount = newAmount;
    }

    function setWhitelistTokenPrice(uint256 newPrice)
        external
        onlyOwner
        freezesOn(whitelistParamsFrozen)
    {
        whitelistTokenPrice = newPrice;
    }

    function setWhitelistParamsFrozen(bool frozen)
        external
        onlyOwner
        freezesOn(whitelistParamsFrozen)
    {
        whitelistParamsFrozen = true;
    }

    function setMintingStartBlock(uint256 targetBlock)
        external
        onlyOwner
        freezesOn(mintingParamsFrozen)
    {
        mintingStartBlock = targetBlock;
    }

    function setMintingTokenAmount(uint256 newAmount)
        external
        onlyOwner
        freezesOn(mintingParamsFrozen)
    {
        mintingTokenAmount = newAmount;
    }

    function setMintingTokenPrice(uint256 newPrice)
        external
        onlyOwner
        freezesOn(mintingParamsFrozen)
    {
        mintingTokenPrice = newPrice;
    }

    function setMintingParamsFrozen(bool frozen)
        external
        onlyOwner
        freezesOn(mintingParamsFrozen)
    {
        mintingParamsFrozen = true;
    }

    function setBaseURI(string calldata newURI)
        external
        onlyOwner
        freezesOn(metadataFrozen)
    {
        baseURI = newURI;
    }

    function setPrerevealURI(string calldata newURI)
        external
        onlyOwner
        freezesOn(metadataFrozen)
    {
        prerevealURI = newURI;
    }

    function setMetadataFrozen(bool frozen)
        external
        onlyOwner
        freezesOn(metadataFrozen)
    {
        metadataFrozen = true;
    }

    /*************
     * Internals *
     *************/

    /// @dev Mapping for wallets that have minted during presale
    mapping(address => bool) private _hasMinted;

    /// @dev Seed for reshuffling token IDs
    uint256 private _revealSeed;

    /**
     * @dev Internal function for performing mints
     */
    function _mintFrogs(address to, uint16 amount) internal {
        _safeMint(to, amount);

        if (availableSupply() == 0 && !tokensRevealed) {
            _revealTokens();
        }
    }

    /**
     * @dev Set the seed for shuffling tokens and mark metadata as revealed
     */
    function _revealTokens() internal {
        require(!tokensRevealed, "Already revealed");

        tokensRevealed = true;
        _revealSeed =
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 256),
                        blockhash(block.number - 255),
                        blockhash(block.number - 254),
                        blockhash(block.number - 253),
                        blockhash(block.number - 252),
                        blockhash(block.number - 251)
                    )
                )
            ) %
            type(uint128).max;

        emit TokenReveal();
    }

    /**
     * @dev Get a shuffled token ID by using an offset + a linear congruential generator
     */
    function _revealedID(uint256 mintedID, uint256 seed)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 a = seed * 20 + 1;
            uint256 c = 3;
            uint256 m = MAX_SUPPLY;
            uint256 x = (mintedID + seed) % MAX_SUPPLY;

            return (a * x + c) % m;
        }
    }

    /**
     * @dev Make sure that the specified block has been reached
     */
    modifier activeAfterBlock(uint256 startBlock) {
        require(block.number > startBlock, "Not active yet");
        _;
    }

    /**
     * @dev Make sure enough payment has been provided
     */
    modifier paymentProvided(uint256 amount) {
        require(msg.value >= amount, "Payment too small");
        _;
    }

    /**
     * @dev Make sure the function is called from an externally owned account
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Called from a contract");
        _;
    }

    /**
     * @dev Allow execution only if the flag is not set
     */
    modifier freezesOn(bool flag) {
        require(!flag, "Parameter frozen");
        _;
    }
}
