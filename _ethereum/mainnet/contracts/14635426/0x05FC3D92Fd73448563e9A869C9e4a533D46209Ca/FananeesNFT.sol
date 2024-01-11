// SPDX-License-Identifier: GPL-2.0-only
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC721Royalty.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

uint96 constant STARTING_ROYALTY = 10 * 100; // 10 * 100 bps = 1000 bps = 10%
uint256 constant TEAM_LOCKUP = 30 days;

contract FananeesNFT is AccessControl, ERC721Royalty, Ownable {
    // NFT supply handling
    uint256 public constant MAX_SUPPLY = 9999; // 9999 NFTs max
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDs;

    uint256 public teamAndVCLimit = 3000;
    uint256 public mintedForTeamAndVC = 0;

    uint256 public binanceSaleLimit = 3000;
    uint256 public mintedForBinanceSale = 0;

    string internal baseURI = "";


    // Life cycle
    enum LifecycleStage {
        PreLaunch,
        Whitelist,
        Public
    }
    bool internal publicStage = false;

    uint256 public immutable STARTING_DATE;
    uint256 internal constant WHITELIST_LENGTH = 1 hours;


    // Payment details
    uint256 public public_price = 15 * 1e16 wei; // 0.15 ETH <=> 0.15 * 1e18 wei <=> 15 * 1e16 wei


    // Whitelist handling
    bytes32 internal whitelistRoot;
    mapping(address => mapping (string => uint256)) public whitelistClaimsMade;
    uint256 public whitelistClaimsLimit = 2;


    // Team settings
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public teamAndVCLockupTimestamp;
    mapping(uint256 => bool) public tokenIsRestricted;


    // Events
    event NFTMintedIntoLockup(address indexed beneficiary, uint256 indexed tokenID);
    event NFTMintedForBinanceSale(address indexed beneficiary, uint256 indexed tokenID);
    event NFTsRevealed();

    event TeamAndVCUnlockDateUpdated(uint256 newTimestamp);
    event TeamAndVCLimitReduced(uint256 newLimit);

    event ProceedsWithdrawn(address indexed recipient, uint256 amount);
    event WhitelistClaimsLimitIncreased(uint256 limit);


    // MODIFIERS

    modifier stageEquals(LifecycleStage _stage) {
        require( getStage() == _stage, "The action is not available at this stage" );
        _;
    }


    // CONSTUCTOR

    constructor(
        address _teamAddress,
        address _minterAddress,
        uint256 _whitelistStart
    )
        ERC721("Fananees", "FNN")
    {
        require(_teamAddress != address(0));
        require(_minterAddress != address(0));
        require(_whitelistStart >= block.timestamp);

        STARTING_DATE = _whitelistStart;
        teamAndVCLockupTimestamp = _whitelistStart + TEAM_LOCKUP;

        _setDefaultRoyalty(_teamAddress, STARTING_ROYALTY);
        _setupRole(DEFAULT_ADMIN_ROLE, _teamAddress);
        _setupRole(MINTER_ROLE, _teamAddress);
        _setupRole(MINTER_ROLE, _minterAddress);
    }


    // MINTING AND CLAIMING

    function mintMultiple(uint256 amount)
        public
        payable
        stageEquals(LifecycleStage.Public)
        returns(
            uint256 firstID,
            uint256 lastID
        ) {
        require(amount > 0);
        uint256 remainingTeamAndVC = teamAndVCLimit - mintedForTeamAndVC;
        uint256 remainingBinanceSale = binanceSaleLimit - mintedForBinanceSale;
        uint256 tokensRemaining = MAX_SUPPLY - _tokenIDs.current();
        require(tokensRemaining - remainingTeamAndVC - remainingBinanceSale >= amount);
        require(msg.value == public_price * amount);

        for (uint256 i=0; i<amount; i++) {
            uint256 newID = _mintNFT(msg.sender);
            if (i==0) firstID = newID;
            if (i==amount-1) lastID = newID;
        }
    }

    function mint() public payable stageEquals(LifecycleStage.Public) returns (uint256) {
        (uint256 a, ) = mintMultiple(1);
        return a;
    }

    function mintWhitelistMultiple(
        bytes32[] calldata proof,
        string calldata source,
        uint256 amount
    )
        public
        payable
        stageEquals( LifecycleStage.Whitelist )
        returns(
            uint256 firstID,
            uint256 lastID
    ) {
        require(_verify(_leaf(msg.sender, source), proof), "Invalid merkle proof");
        uint256 remainingTeamAndVC = teamAndVCLimit - mintedForTeamAndVC;
        uint256 tokensRemaining = MAX_SUPPLY - _tokenIDs.current();
        require(tokensRemaining - remainingTeamAndVC >= amount);
        require(whitelistClaimsMade[msg.sender][source] + amount <= whitelistClaimsLimit);
        whitelistClaimsMade[msg.sender][source] += amount;

        require(msg.value == public_price * amount);

        for (uint i=0; i<amount; i++) {
            uint256 newID = _mintNFT(msg.sender);
            if (i==0) firstID = newID;
            if (i==amount-1) lastID = newID;
        }
    }

    function mintWhitelist(
        bytes32[] calldata proof,
        string calldata source
    )
        external
        payable
        stageEquals( LifecycleStage.Whitelist )
        returns (uint256)
    {
        (uint256 a, ) = mintWhitelistMultiple(proof, source, 1);
        return a;
    }

    function mintForTeamAndVC(address beneficiary) public onlyRole(MINTER_ROLE) returns(uint256) {
        require(beneficiary != address(0));
        require(mintedForTeamAndVC < teamAndVCLimit);

        mintedForTeamAndVC += 1;
        uint256 tokenID = _mintNFT(beneficiary);
        tokenIsRestricted[tokenID] = true;

        emit NFTMintedIntoLockup(beneficiary, tokenID);
        return tokenID;
    }

    function mintForTeamAndVCMultiple(
        address beneficiary,
        uint256 amount
    )
        external
        onlyRole(MINTER_ROLE)
        returns(
            uint256 firstID,
            uint256 lastID
    ) {
        require(amount != 0);
        require(beneficiary != address(0));
        require(mintedForTeamAndVC + amount <= teamAndVCLimit);

        for (uint256 i=0; i<amount; i++) {
            uint256 newID = mintForTeamAndVC(beneficiary);
            if (i==0) firstID = newID;
            if (i==amount-1) lastID = newID;
        }
    }

    function mintForBinanceSale(address beneficiary) public onlyRole(MINTER_ROLE) returns(uint256) {
        require(beneficiary != address(0));
        require(mintedForBinanceSale < binanceSaleLimit);

        mintedForBinanceSale += 1;
        uint256 tokenID = _mintNFT(beneficiary);

        emit NFTMintedForBinanceSale(beneficiary, tokenID);
        return tokenID;
    }

    function mintForBinanceSaleMultiple(
        address beneficiary,
        uint256 amount
    )
        external
        onlyRole(MINTER_ROLE)
        returns(
            uint256 firstID,
            uint256 lastID
    ) {
        require(amount != 0);
        require(beneficiary != address(0));
        require(mintedForBinanceSale + amount <= binanceSaleLimit);

        for (uint256 i=0; i<amount; i++) {
            uint256 newID = mintForBinanceSale(beneficiary);
            if (i==0) firstID = newID;
            if (i==amount-1) lastID = newID;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // WHITELIST UTILITIES

    function setWLRoot(bytes32 merkleroot) external onlyRole(MINTER_ROLE) {
        whitelistRoot = merkleroot;
    }


    // MINTER CONTROLS
    function changeTeamAndVCLimit(uint256 _teamAndVCLimit) external onlyRole(MINTER_ROLE) {
        require(_teamAndVCLimit >= mintedForTeamAndVC);
        teamAndVCLimit = _teamAndVCLimit;
    }

    function changeBinanceSaleLimit(uint256 _binanceSaleLimit) external onlyRole(MINTER_ROLE) {
        require(_binanceSaleLimit >= mintedForBinanceSale);
        binanceSaleLimit = _binanceSaleLimit;
    }

    function changePrice(uint256 _public_price) public onlyRole(MINTER_ROLE) {
        public_price = _public_price;
    }

    function setWhitelistClaimsLimit(uint256 _limit) external onlyRole(MINTER_ROLE) {
        require(_limit > whitelistClaimsLimit);
        whitelistClaimsLimit = _limit;

        emit WhitelistClaimsLimitIncreased(_limit);
    }

    function startPublicStage() external onlyRole(MINTER_ROLE) {
        require(block.timestamp >= STARTING_DATE + WHITELIST_LENGTH);
        publicStage = true;
    }


    // ADMIN CONTROLS
    function publishNFTs(string calldata newURI) external onlyRole(MINTER_ROLE) {
        baseURI = newURI;
    }

    function withdrawProceeds(address beneficiary, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beneficiary != address(0));
        require(amount > 0);

        payable(beneficiary).transfer(amount);

        emit ProceedsWithdrawn(beneficiary, amount);
    }

    function withdrawProceedsToSelf() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;
        withdrawProceeds(msg.sender, amount);
    }


    // ==================
    // INTERNAL FUNCTIONS
    // ==================

    // ERC721 Overrides

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (tokenIsRestricted[tokenId]) {
            require(block.timestamp >= teamAndVCLockupTimestamp);
            tokenIsRestricted[tokenId] = false;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Minting

    function _mintNFT(address recipient) internal returns (uint256) {
        require(_tokenIDs.current() < MAX_SUPPLY);
        _tokenIDs.increment();
        uint256 newItemID = _tokenIDs.current();
        _mint(recipient, newItemID);
        return(_tokenIDs.current());
    }


    // Stage definitions

    function getStage() public view returns (LifecycleStage) {
        if (publicStage) {
            return LifecycleStage.Public;
        } else if (block.timestamp > STARTING_DATE + WHITELIST_LENGTH) {
            return LifecycleStage.Whitelist;
        } else {
            return LifecycleStage.PreLaunch;
        }
    }


    // Whitelist utilities

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistRoot, leaf);
    }

    function _leaf(address account, string calldata source) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, source));
    }
}
