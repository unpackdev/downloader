// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract DownBadDegen is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    enum SaleStates {
        CLOSED,
        WHITELIST,
        PUBLIC
    }

    /**
     * Private variables
     */
    SaleStates private saleState;
    address private immutable i_owner;
    string private baseURI = "";
    bool private teamClaimed = false;

    /**
     * Public variables
     */
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant TEAM_CLAIM_AMOUNT = 100;
    uint256 public maxPerWallet = 2;
    uint256 public maxPerWL = 1;
    mapping(address => uint256) public minted;
    mapping(address => uint256) public whitelistClaimed;
    bytes32 public merkleRoot;
    string public hiddenMetadataUri;
    bool public revealed = false;

    /**
     * Modifiers
     */
    modifier checkState(SaleStates _saleState) {
        require(msg.sender == tx.origin, "Non EOA");
        require(saleState == _saleState, "Phase has not started");
        _;
    }

    modifier checkSupply() {
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        _;
    }

    /**
     * Constructor
     * Assigns i_owner to sender
     */
    constructor(string memory _hiddenMetadaUri) ERC721A("Down Bad Degen", "DBD") {
        i_owner = msg.sender;
        saleState = SaleStates.CLOSED;
        setHiddenMetadataUri(_hiddenMetadaUri);
    }

    /**
     * Minting Functions
     */
    function mint(uint256 _numberOfTokens)
        external
        payable
        checkSupply
        checkState(SaleStates.PUBLIC)
        nonReentrant
    {
        require(_numberOfTokens > 0, "Number of tokens must be more than zero");
        require(_numberOfTokens <= MAX_SUPPLY - totalSupply(), "Not enough NFTs left");
        require(
            _numberOfTokens + minted[msg.sender] <= maxPerWallet,
            "Can't mint above maxPerWallet"
        );

        minted[msg.sender] = minted[msg.sender] + _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);
    }

    function teamClaim() external onlyOwner checkSupply {
        require(!teamClaimed, "Team already claimed");
        _safeMint(msg.sender, TEAM_CLAIM_AMOUNT);

        minted[msg.sender] = minted[msg.sender] + TEAM_CLAIM_AMOUNT;
        teamClaimed = true;
    }

    function whitelistMint(uint256 _numberOfTokens, bytes32[] calldata _merkleProof)
        external
        payable
        checkSupply
        checkState(SaleStates.WHITELIST)
        nonReentrant
    {
        require(_numberOfTokens > 0, "Number of tokens must be more than zero");
        require(
            _numberOfTokens + whitelistClaimed[msg.sender] <= maxPerWL,
            "Can't mint above whitelist allocation"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

        whitelistClaimed[msg.sender] = whitelistClaimed[msg.sender] + _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);
    }

    /**
     * ***************************************************************************************
     * ADMIN FUNCTIONS
     * Restricted to owner only
     */

    /**
     * Sales State
     * 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC
     */
    function setSaleState(uint256 _newState) external onlyOwner {
        require(_newState <= uint256(SaleStates.PUBLIC), "Invalid Sales State");

        saleState = SaleStates(_newState);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setMaxPerWallet(uint256 _count) external onlyOwner {
        maxPerWallet = _count;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /**
     * Withdraw funds
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    /**
     * ***************************************************************************************
     * Getter functions
     */

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        // Start tokenid at 1 instead of 0
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getSaleState() public view returns (uint256) {
        return uint256(saleState);
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getAmountMinted(address _addr) public view returns (uint256) {
        return minted[_addr];
    }

    function getAmountWLMinted(address _addr) public view returns (uint256) {
        return whitelistClaimed[_addr];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getTeamClaimed() public view returns (bool) {
        return teamClaimed;
    }

    receive() external payable {}
}
