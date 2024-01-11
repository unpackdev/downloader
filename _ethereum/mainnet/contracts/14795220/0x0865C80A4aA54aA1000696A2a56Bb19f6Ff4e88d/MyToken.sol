// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./VRFConsumerBase.sol";

contract MyToken is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBase {

    string public PROVENANCE_HASH;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public startingIndex;
    bool public randomStartingIndexRequested;

    // Amounts
    uint256 public airdropAmount;
    uint256 public currentNumMinted;
    uint256 public totalAmount;

    // Claim
    bool public claimActive;
    uint256 public claimMaxMintAmount;
    mapping(address => bool) public claimed;

    // Events

    event ClaimStart(
        uint256 indexed _claimStartTime
    );
    event ClaimStop(
        uint256 indexed _timestamp
    );

    // Modifiers
    modifier whenClaimActive() {
        require(claimActive, "Claim is not active");
        _;
    }

    // Struct
    struct Amounts {
        uint256 airdropAmount;
        uint256 totalAmount;
        uint256 claimMaxMintAmount;
    }

    struct VrfValues {
        address vrfCoordinator;
        address linkTokenAddress;
        bytes32 keyHash;
        uint256 fee;
    }

    // Base URI
    string public baseURI;
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    constructor(
        string memory name,
        string memory symbol,
        VrfValues memory vrfValues,
        Amounts memory amounts,
        string memory _PROVENANCE_HASH,
        string memory baseURIInput
    )   VRFConsumerBase(vrfValues.vrfCoordinator, vrfValues.linkTokenAddress)
        ERC721A(name, symbol)
    {
        keyHash = vrfValues.keyHash;
        fee = vrfValues.fee;

        airdropAmount = amounts.airdropAmount;
        totalAmount = amounts.totalAmount;

        claimMaxMintAmount = amounts.claimMaxMintAmount;

        PROVENANCE_HASH = _PROVENANCE_HASH;

        baseURI = baseURIInput;
    }

    // Airdrop
    function airdrop(address recipient, uint256 numMinted) external onlyOwner {
        require(recipient != address(0), "The recipient address can't be 0.");
        require(numMinted > 0, "Mint at least one NFT.");
        require(currentNumMinted + numMinted <= airdropAmount, "Cannot exceed limit allocated for airdrop.");

        currentNumMinted += numMinted;
        _safeMint(recipient, numMinted);
    }

    // Claim
    function startClaim() external onlyOwner {
        require(!claimActive, "Claim is already active.");
        claimActive = true;

        emit ClaimStart(block.timestamp);
    }

    function stopClaim() external whenClaimActive onlyOwner {
        claimActive = false;
        emit ClaimStop(block.timestamp);
    }

    function claim(uint256 numMinted) external nonReentrant whenClaimActive {
        require(numMinted > 0, "Claim at least one NFT.");
        require(numMinted <= claimMaxMintAmount, "Cannot claim more than claimMaxMintAmount.");
        require(!claimed[msg.sender], "Cannot claim again.");
        require(currentNumMinted + numMinted <= totalAmount, "Cannot claim more. Limit exceeded.");
        require(msg.sender == tx.origin, "Transaction origin address is not same as caller address");

        claimed[msg.sender] = true;

        currentNumMinted += numMinted;
        _safeMint(msg.sender, numMinted);
    }


    // Randomization
    function requestRandomStartingIndex() external onlyOwner returns (bytes32 requestId) {
        require(!randomStartingIndexRequested, "Random Starting Index already requested");
        randomStartingIndexRequested = true;

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        startingIndex = randomness % totalSupply();
    }
}