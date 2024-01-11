// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

/// @author solipsis
contract testhack is Ownable, ERC721A, ReentrancyGuard {

    constructor(uint256 _collectionSize) ERC721A("testhack", "testhack") {
        collectionSize = _collectionSize;
        stage = Stage.INITIAL;
        metadataIsLocked = false;
        allowTransferWhileJackedIn = false;
        treasuryAddress = msg.sender;
        allowlistSignerAddress = msg.sender;
    }

    ////////////////////////////////////////////////////////////////////////
    // Contract State
    ////////////////////////////////////////////////////////////////////////

    /// @notice max number of hackers that will ever be minted
    uint256 public immutable collectionSize;

    /// @dev baseURI for all ERC721 Metadata interactions
    string private _baseTokenURI;

    /// @dev testhack foundation address, exempt from individual address minting cap
    address public treasuryAddress;

    /// @dev sensible batch size for treasury mints
    uint8 private treasuryMaxBatch = 20;

    /// @dev testhack controlled allowlist signer
    address public allowlistSignerAddress;

    /// @notice is token metadata permanently locked
    bool public metadataIsLocked;

    /// @notice is minting temporarily paused
    /// @dev for unexpected events such as DDOS against minting front-end
    bool public mintingIsPaused;

    /// @dev only mutable in transferWhileJackedIn(). Used to disable normal transfers while a token is jacked-in
    bool private allowTransferWhileJackedIn;


    // Tracking cumulative and most recent time periods a given hacker has been "jacked-in"
    struct JackInState {
        uint64 started;
        uint64 cumulative;
    }
    mapping(uint256 => JackInState) public jackerTracker;

    /// @dev Simple state machine: INITIAL -> ALLOWLIST_SALE -> PUBLIC_SALE
    enum Stage {
        INITIAL,
        ALLOWLIST_SALE,
        PUBLIC_SALE
    }
    Stage public stage;


    // All configuration for allowlist sale
    struct AllowlistSaleConfig {
        uint32 key;            // key that must be provided to mint during allowlist phase
        uint32 maxBatch;       // max purchasable at a time during allowlist phase
        uint32 maxPerAddress;  // limit per address across all mint calls
        uint32 mintingCap;     // temporarily limit total tokens that can be minted collectively
        uint64 price;          // price (in wei) of minting during the allowlist phase
    }
    AllowlistSaleConfig public allowlistSaleConfig;

    // All configuration for public sale
    struct PublicSaleConfig {
        uint32 key;           // key that must be provided to mint during public phase
        uint32 maxBatch;      // max purchasable at a time during public phase
        uint32 maxPerAddress; // limit per address across all mint calls
        uint32 mintingCap;     // temporarily limit total tokens that can be minted collectively
        uint64 price;         // price (in wei) of minting during the public phase

    }
    PublicSaleConfig public publicSaleConfig;


    ////////////////////////////////////////////////////////////////////////
    // Stage Transitions
    ////////////////////////////////////////////////////////////////////////
    error FunctionInvalidAtThisStage();
    error SaleKeyNotSet();
    error SaleMaxBatchNotSet();
    error SaleMaxPerAddressNotSet();
    error SaleTotalAllotmentNotSet();
    error SalePriceNotSet();

    /// @dev only allow function to proceed if in specified stage of state machine
    modifier onlyStage(Stage _stage) {
        if (stage != _stage) {
            revert FunctionInvalidAtThisStage();
        }
        _;
    }

    /// @notice advance to next stage of sale if all pre-requisites have been met
    /// @dev Stage transitions from INITIAL -> ALLOWLIST_SALE -> PUBLIC_SALE
    function advanceStage() external onlyOwner {

        // For each possible state, verify that all prereqs are met before transition to next state
        if (stage == Stage.INITIAL) {
            if (allowlistSaleConfig.key == 0) revert SaleKeyNotSet();
            if (allowlistSaleConfig.maxBatch == 0) revert SaleMaxBatchNotSet();
            if (allowlistSaleConfig.maxPerAddress == 0) revert SaleMaxPerAddressNotSet();
            if (allowlistSaleConfig.price == 0) revert SalePriceNotSet();
            stage = Stage.ALLOWLIST_SALE;

        } else if (stage == Stage.ALLOWLIST_SALE) {
            if (publicSaleConfig.key == 0) revert SaleKeyNotSet();
            if (publicSaleConfig.maxBatch == 0) revert SaleMaxBatchNotSet();
            if (publicSaleConfig.maxPerAddress == 0) revert SaleMaxPerAddressNotSet();
            if (publicSaleConfig.price == 0) revert SalePriceNotSet();
            stage = Stage.PUBLIC_SALE;
        }
    }


    ////////////////////////////////////////////////////////////////////////
    // Admin
    ////////////////////////////////////////////////////////////////////////
    error CallerIsContract();
    error WithdrawFailed();
    error CallerNotApprovedOrTokenOwner();
    error ExceededTreasuryMaxBatch();

    /// @notice withraw current contract balance to current treasuryAddress
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    /// @notice temporarily pause/unpause minting in case of an external issue
    function setMintingIsPaused(bool _paused) external onlyOwner {
        mintingIsPaused = _paused;
    }

    /// @notice sets the testhack treasury address
    function setTreasuryAddress(address _addr) external onlyOwner {
        treasuryAddress = _addr;
    }

    /// @notice sets the allowlist signer address
    function setAllowlistSignerAddress(address _addr) external onlyOwner {
        allowlistSignerAddress = _addr;
    }

    /// @notice mint directly to treasury wallet
    /// @param quantity how many tokens to mint
    function treasuryMint(uint8 quantity) external onlyOwner {
        if (quantity > treasuryMaxBatch) revert ExceededTreasuryMaxBatch();
        if (_totalMinted() + quantity > collectionSize) revert ExceededMaxSupply();

        _safeMint(treasuryAddress, quantity);
    }

    /// @dev prevent contracts from calling some functions
    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContract();
        _;
    }

    modifier onlyApprovedOrTokenOwner(uint256 tokenID) {
        TokenOwnership memory ownership = _ownershipOf(tokenID);
        bool isApprovedOrOwner = (_msgSender() == ownership.addr ||
            isApprovedForAll(ownership.addr, _msgSender()) ||
            getApproved(tokenID) == _msgSender());

        if (!isApprovedOrOwner) revert CallerNotApprovedOrTokenOwner();
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    // Allowlist Sale
    ////////////////////////////////////////////////////////////////////////
    error MintingPaused();
    error InvalidAllowlistSignature();
    error IncorrectAllowlistSaleKey();
    error ExceededAllowlistMaxBatch();
    error ExceededAllowlistMaxPerAddress();
    error ExceededAllowlistMintingCap();
    error ExceededAllowlistPersonalAllotment();


    /// @notice mint using earned mint-passes
    /// @param quantity how many tokens to mint
    /// @param userAllotment total mint passes the sender earned
    /// @param callerSaleKey allowlist sale key
    /// @param signature testhack provided signature over other parameters
    /// @dev signature over users address and allotted quantity
    function allowlistMint(uint8 quantity, uint8 userAllotment, uint32 callerSaleKey, bytes memory signature)
        external
        payable
        callerIsUser
        onlyStage(Stage.ALLOWLIST_SALE)
    {

        AllowlistSaleConfig memory config = allowlistSaleConfig;

        uint256 saleKey = uint256(config.key);
        uint256 maxBatch = uint256(config.maxBatch);
        uint256 maxPerAddress = uint256(config.maxPerAddress);
        uint256 mintingCap = uint256(config.mintingCap);
        uint256 price = uint256(config.price);

        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, ":", userAllotment)));

        if (mintingIsPaused) revert MintingPaused();
        if (quantity > maxBatch) revert ExceededAllowlistMaxBatch();
        if (saleKey != callerSaleKey) revert IncorrectAllowlistSaleKey();
        if (numberMinted(msg.sender) + quantity > userAllotment) revert ExceededAllowlistPersonalAllotment();
        if (numberMinted(msg.sender) + quantity > maxPerAddress) revert ExceededAllowlistMaxPerAddress();
        if (_totalMinted() + quantity > mintingCap) revert ExceededAllowlistMintingCap();
        if (_totalMinted() + quantity > collectionSize) revert ExceededMaxSupply();
        if (recoverSigner(message, signature) != allowlistSignerAddress) revert InvalidAllowlistSignature();

        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }


    // signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    ////////////////////////////////////////////////////////////////////////
    // Public Sale
    ////////////////////////////////////////////////////////////////////////
    error IncorrectPublicSaleKey();
    error ExceededPublicSaleMaxBatch();
    error ExceededPublicSaleMaxPerAddress();
    error ExceededPublicSaleMintingCap();
    error ExceededMaxSupply();
    error InsufficientEth();


    /// @notice open public mint
    /// @param quantity how many tokens to mint
    /// @param callerSaleKey public sale key
    function publicSaleMint(uint256 quantity, uint256 callerSaleKey)
        external
        payable
        callerIsUser
        onlyStage(Stage.PUBLIC_SALE)
    {
        PublicSaleConfig memory config = publicSaleConfig;
        uint256 publicSaleKey = uint256(config.key);
        uint256 publicSalePrice = uint256(config.price);
        uint256 publicSaleMaxBatch = uint256(config.maxBatch);
        uint256 publicSaleMintingCap = uint256(config.mintingCap);
        uint256 publicSaleMaxPerAddress = uint256(config.maxPerAddress);

        if (mintingIsPaused) revert MintingPaused();
        if (publicSaleKey != callerSaleKey) revert IncorrectPublicSaleKey();
        if (quantity > publicSaleMaxBatch) revert ExceededPublicSaleMaxBatch();
        if (_totalMinted() + quantity > collectionSize) revert ExceededMaxSupply();
        if (_totalMinted() + quantity > publicSaleMintingCap) revert ExceededPublicSaleMintingCap();
        if (numberMinted(msg.sender) + quantity > publicSaleMaxPerAddress) revert ExceededPublicSaleMaxPerAddress();

        _safeMint(msg.sender, quantity);
        refundIfOver(publicSalePrice * quantity);
    }

    function refundIfOver(uint256 totalCost) private {
        if (msg.value < totalCost) revert InsufficientEth();
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    ////////////////////////////////////////////////////////////////////////
    // Sale Configuration
    ////////////////////////////////////////////////////////////////////////
    error InvalidAllowlistConfiguration();
    error InvalidPublicSaleConfiguration();

    /// @notice configure the params for the allowlist stage of the sale
    /// @param key testhack provided sale key
    /// @param maxBatch maximum mint batch size per transaction
    /// @param maxPerAddress maximum cumulative mints for each unique address
    /// @param mintingCap temporarily limit total tokens that can be minted collectively
    /// @param price sale price in wei
    function configureAllowlistSale(uint32 key, uint32 maxBatch, uint32 maxPerAddress, uint32 mintingCap, uint64 price) 
        external
        onlyOwner
    {
        if (key == 0) revert InvalidAllowlistConfiguration();
        if (maxBatch == 0) revert InvalidAllowlistConfiguration();
        if (maxPerAddress == 0) revert InvalidAllowlistConfiguration();
        if (price == 0) revert InvalidAllowlistConfiguration();
        if (mintingCap == 0) revert InvalidAllowlistConfiguration();

        allowlistSaleConfig.key = key;
        allowlistSaleConfig.maxBatch = maxBatch;
        allowlistSaleConfig.maxPerAddress = maxPerAddress;
        allowlistSaleConfig.mintingCap = mintingCap;
        allowlistSaleConfig.price = price;
    }

    /// @notice configure the params for the public stage of the sale
    /// @param key testhack provided sale key
    /// @param maxBatch maximum mint batch size per transaction
    /// @param maxPerAddress maximum cumulative mints for each unique address
    /// @param mintingCap temporarily limit total tokens that can be minted collectively
    /// @param price sale price in wei
    function configurePublicSale(uint32 key, uint32 maxBatch, uint32 maxPerAddress, uint32 mintingCap, uint64 price) 
        external
        onlyOwner
    {
        if (key == 0) revert InvalidPublicSaleConfiguration();
        if (maxBatch == 0) revert InvalidPublicSaleConfiguration();
        if (maxPerAddress == 0) revert InvalidPublicSaleConfiguration();
        if (price == 0) revert InvalidPublicSaleConfiguration();
        if (mintingCap == 0) revert InvalidPublicSaleConfiguration();

        publicSaleConfig.key = key;
        publicSaleConfig.maxBatch = maxBatch;
        publicSaleConfig.maxPerAddress = maxPerAddress;
        publicSaleConfig.mintingCap = mintingCap;
        publicSaleConfig.price = price;
    }

    ////////////////////////////////////////////////////////////////////////
    // Jack In/Out
    ////////////////////////////////////////////////////////////////////////
    error InvalidTransferCurrentlyJackedIn();
    error OnlyTokenOwner();

    event JackedIn(uint256 indexed tokenID);
    event JackedOut(uint256 indexed tokenID);
    event Flatlined(uint256 indexed tokenID);

    /// @notice returns whether the provided token is currently jacked-in and current + cumulative hacking time
    function hackingStats(uint256 tokenID) external view returns (
        bool isJackedIn,
        uint64 current,
        uint64 total
    ) {
        JackInState memory state = jackerTracker[tokenID];
        if (state.started != 0) {
            isJackedIn = true;
            current = uint64(block.timestamp) - state.started;
        }
        total = state.cumulative + current;
    }


    /// @dev prevent normal transfers if the token is jacked in
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenID,
        uint256 quantity
    ) internal view override {
        uint256 tokenID = startTokenID;
        for (uint256 end = tokenID + quantity; tokenID < end; tokenID++) {
            if (jackerTracker[tokenID].started != 0 && !allowTransferWhileJackedIn) {
                revert InvalidTransferCurrentlyJackedIn();
            }
        }
    }

    /// @notice transfer a currently jacked-in hacker without interrupting hacking stats
    /// @dev not using safeTransferFrom() to avoid re-entrancy issues
    function transferWhileJackedIn(
        address from,
        address to,
        uint256 tokenID
    ) external {
        if (ownerOf(tokenID) != _msgSender()) revert OnlyTokenOwner();
        allowTransferWhileJackedIn = true;
        transferFrom(from, to, tokenID);
        allowTransferWhileJackedIn = false;
    }

    /// @notice jack-in all provided tokenIDs
    /// @dev no-op if already jacked in
    function jackIn(uint256[] calldata tokenIDs) external {
        uint256 length = tokenIDs.length;
        for (uint256 i = 0; i < length; i++) {
            _jackIn(tokenIDs[i]);
        }
    }

    function _jackIn(uint256 tokenID) internal onlyApprovedOrTokenOwner(tokenID) {
        JackInState storage state = jackerTracker[tokenID];
        if (state.started == 0) {
            state.started = uint64(block.timestamp);
            emit JackedIn(tokenID);
        }
    }

    /// @notice jack-out all provided tokenIDs
    /// @dev no-op if already jacked out
    function jackOut(uint256[] calldata tokenIDs) external {
        uint256 length = tokenIDs.length;
        for (uint256 i = 0; i < length; i++) {
            _jackOut(tokenIDs[i]);
        }
    }

    function _jackOut(uint256 tokenID) internal onlyApprovedOrTokenOwner(tokenID) {
        JackInState storage state = jackerTracker[tokenID];
        if (state.started != 0) {
            state.cumulative += uint64(block.timestamp) - state.started;
            state.started = 0;
            emit JackedOut(tokenID);
        }
    }

    /// @notice Forcibly jack-out a token engaging in malicious behavier
    /// @dev see Moonbirds.sol line 349 for additional discussion
    function flatline(uint256 tokenID) external onlyOwner {
	    JackInState storage state = jackerTracker[tokenID];
        if (state.started != 0) {
            state.cumulative += uint64(block.timestamp) - state.started;
            state.started = 0;
            emit JackedOut(tokenID);
            emit Flatlined(tokenID);
        }
    }

    ////////////////////////////////////////////////////////////////////////
    // Metadata
    ////////////////////////////////////////////////////////////////////////
    error MetadataLocked();

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set _baseTokenURI for ERC721 metadata functions
    function setBaseURI(string calldata baseURI) external onlyOwner {
        if (metadataIsLocked) revert MetadataLocked();
        _baseTokenURI = baseURI;
    }

    /// @notice permanently lock base metadataURI from being changed
    function lockMetadata() external onlyOwner {
        metadataIsLocked = true;
    }

    /// @notice returns number of tokens minted by provided address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
