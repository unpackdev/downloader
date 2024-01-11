// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// by: stormwalkerz ⭐️

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./VRFConsumerBase.sol";
import "./SafeMath.sol";

interface iYield {
    function updateReward(address from_, address to_, uint256 tokenId_) external;
}

contract Baboonverse is ERC721A, Ownable, VRFConsumerBase, ReentrancyGuard {
    using SafeMath for uint256;

    // Provenance Hash (5888 - Original)
    string public constant PROVENANCE_HASH = "ffff0ef17cb1bbd8c6a3de9f5de4590eed82f012acb995e5bf4fb8ba18e438e2";

    // Provenance Hash of Rank : Burning start from common (rank 5888) to rare (rank 1001)
    string public constant PROVENANCE_HASH_RANK = "63b3ac3d0dd86ffc4b5467eda8778b4d7b62aa93c5979fef365ae3afdd67ad2f"; 

    // Provenance Hash Final Reveal with New Supply (after burned)
    string public PROVENANCE_HASH_FINAL;

    // Price
    uint256 public constant MINT_PRICE = 0.0088 ether;
    uint256 public constant WHITELIST_MINT_PRICE = 0.0058 ether;

    // Supply
    uint256 public constant INITIAL_SUPPLY = 5888;
    uint256 public maxPerTxnPublic;
    uint256 public maxPerTxnWhitelist;
    uint256 public maxPerWalletPublic;
    uint256 public maxPerWalletWhitelist;
    uint256 public maxPerTeam;
    uint256 public maxPerBaboonfrens;

    // Project Variables
    uint256 public constant MINT_DURATION = 48 hours;
    bytes32 public merkleRoot;
    bytes32 public merkleRootBaboonfrens; 
    bytes32 public merkleRootDevTeam;
    string private baseTokenURI;

    // Chainlink VRF
    bytes32 internal linkKeyHash;
    uint256 internal linkFee;

    // Future Token Yield
    iYield public yieldToken;

    // Constructor
    constructor(address vrfCoordinator_,
                address link_,
                bytes32 linkKeyHash_,
                uint linkFee_,
                bytes32 merkleRoot_,
                uint256 saleStartTime_,
                uint256 maxPerTeam_,
                uint256 maxPerBaboonfrens_
    ) 
        ERC721A("Baboonverse", "BABOON") 
        VRFConsumerBase(vrfCoordinator_, link_)
    {

        // Project Variables
        merkleRoot = merkleRoot_;
        baseTokenURI = "https://baboonverse-main.s3.amazonaws.com/metadata/";
        maxPerWalletWhitelist = 5;
        maxPerTxnWhitelist = 5;
        maxPerWalletPublic = 3;
        maxPerTxnPublic = 3;
        maxPerTeam = maxPerTeam_;
        maxPerBaboonfrens = maxPerBaboonfrens_;

        // Chainlink
        linkKeyHash = linkKeyHash_;
        linkFee = linkFee_;

        // Preparation
        _safeMint(owner(), 1);
        saleStartTime.push(saleStartTime_);
        saleActive = true;
    }
    
    // Modifiers
    modifier isUser {
        require(msg.sender == tx.origin, "Disable from SC"); _;
    }
    
    // Validation of Minted Address (ERC721A)
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    
    // Mint
    function whitelistMint(uint256 quantity_, bytes32[] memory proof_) external payable isUser isWhitelistMint isSaleActive {
        uint256 maxSupply = currentMaxSupply();
        require(MerkleProof.verify(proof_, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You're not whitelisted");
        require(numberMinted(msg.sender) + quantity_ <= maxPerWalletWhitelist, "Max per wallet reached");
        require(quantity_ <= maxPerTxnWhitelist, "Max per txn exceeded");
        require(msg.value == WHITELIST_MINT_PRICE * quantity_, "Wrong value!");
        require(maxSupply >= totalSupply() + quantity_, "Max supply exceeded");
        
        _safeMint(msg.sender, quantity_);
    }
    function publicMint(uint256 quantity_) external payable nonReentrant isUser isPublicMint isSaleActive { 
        uint256 maxSupply = currentMaxSupply();
        require(numberMinted(msg.sender) + quantity_ <= maxPerWalletPublic, "Max per wallet reached.");
        require(quantity_ <= maxPerTxnPublic, "Max per txn exceeded");
        require(msg.value == MINT_PRICE * quantity_, "Wrong value!");
        require(maxSupply >= totalSupply() + quantity_, "Max supply exceeded");
        
        _safeMint(msg.sender, quantity_);
    }
    function devTeamMint(uint256 quantity_, bytes32[] memory proof_) external isUser isSaleActive {
        uint256 maxSupply = currentMaxSupply();
        require(whitelistMintEnabled && block.timestamp >= whitelistMintTime, "Team mint not started");
        require(MerkleProof.verify(proof_, merkleRootDevTeam, keccak256(abi.encodePacked(msg.sender))), "You're not whitelisted");
        require(numberMinted(msg.sender) <= maxPerTeam, "Max per wallet reached");
        require(quantity_ <= maxPerTeam, "Max per txn exceeded");
        require(maxSupply >= totalSupply() + quantity_, "Max supply exceeded");
        
        // Keep max chunks to 5 (to prevent high gas of future transfer)
        uint256 numChunks = quantity_ / 5;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, 5);
        }
        
        uint256 leftChunks = quantity_ % 5;
        if (leftChunks > 0) {
            _safeMint(msg.sender, leftChunks);
        }
    }
    function baboonfrensMint(uint256 quantity_, bytes32[] memory proof_) external isUser isSaleActive {
        uint256 maxSupply = currentMaxSupply();
        require(whitelistMintEnabled && block.timestamp >= whitelistMintTime, "Baboonfrens mint not started");
        require(MerkleProof.verify(proof_, merkleRootBaboonfrens, keccak256(abi.encodePacked(msg.sender))), "You're not Baboonfrens");
        require(numberMinted(msg.sender) <= maxPerBaboonfrens, "Max per wallet reached.");
        require(quantity_ <= maxPerBaboonfrens, "Max per txn exceeded");
        require(maxSupply >= totalSupply() + maxPerBaboonfrens, "Max supply exceeded");

        _safeMint(msg.sender, quantity_);
    }

    // Randomness
    uint256 public startingIndex;
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= linkFee, "Not enough LINK");
        require(startingIndex == 0, "Already generated random number");
        require(saleFinished == true, "Sale not finished yet");

        return requestRandomness(linkKeyHash, linkFee);
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Process random number
        uint256 newRandomStartingIndex = randomness % totalSupply();

        // Prevent default sequence
        if (newRandomStartingIndex == 0) {
            newRandomStartingIndex = newRandomStartingIndex.add(1);
        }

        // Assign starting index
        startingIndex = newRandomStartingIndex;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // Public Mint
    bool public publicMintEnabled;
    uint256 public publicMintTime;
    function setPublicMint(bool bool_, uint256 epochTime_) external onlyOwner {
        publicMintEnabled = bool_;
        publicMintTime = epochTime_;
    }
    modifier isPublicMint {
        require(publicMintEnabled && block.timestamp >= publicMintTime, "Public sale not started"); _; }
    function publicMintIsEnabled() external view returns (bool) {
        return(publicMintEnabled && block.timestamp >= publicMintTime);
    }
    // Whitelist Mint
    bool public whitelistMintEnabled;
    uint256 public whitelistMintTime;
    function setWhitelistMint(bool bool_, uint256 epochTime_) external onlyOwner {
        whitelistMintEnabled = bool_;
        whitelistMintTime = epochTime_;
    }
    modifier isWhitelistMint {
        require(whitelistMintEnabled && block.timestamp >= whitelistMintTime, "Whitelist sale not started"); _; }
    function whitelistMintIsEnabled() public view returns (bool) {
        return(whitelistMintEnabled && block.timestamp >= whitelistMintTime);
    }

    // Sale Status + Burn Mechanism
    bool public saleFinished;
    bool public saleActive;
    uint256[] public saleStartTime;
    uint256 public saleEndTime;
    uint256 public prevElapsedTime;
    uint256 public prevBurnedSupply;
    modifier isSaleActive {
        require(saleActive == true, "Sale not active"); _; }
    function startSale(uint256 saleStartTime_) external onlyOwner {
        require(saleActive == false, "Sale not started");
        require(block.timestamp <= saleStartTime_, "Start must be in the future");

        if (saleStartTime[0] == 0) {
            saleEndTime = saleStartTime_ + MINT_DURATION;
        }

        saleStartTime.push(saleStartTime_);
        saleActive = true;
    }
    function finishSale(uint256 saleEndTime_) external onlyOwner {
        require(block.timestamp >= saleEndTime_, "Sale not finished yet");

        saleActive = false;
        saleFinished = true;
        saleEndTime = saleEndTime_;
    }
    function emergencyPauseSale() external onlyOwner {
        require(saleActive == true, "Sale already paused");

        prevElapsedTime = block.timestamp - saleStartTime[0];
        prevBurnedSupply = INITIAL_SUPPLY - currentMaxSupply();

        saleActive = false;
    }
    function currentMaxSupply() public view returns (uint256) {
        // Initial
        if (saleStartTime[0] == 0) {
            return INITIAL_SUPPLY;
        }

        // If paused
        if (saleActive == false) {
            return INITIAL_SUPPLY - prevBurnedSupply;
        }

        // Initial after paused (saleStartTime already set to future time)
        if (saleStartTime.length > 0) {
            if (saleActive == true && block.timestamp <= saleStartTime[saleStartTime.length - 1]){
                return INITIAL_SUPPLY - prevBurnedSupply;
            }
        }

        uint256 timeElapsed = block.timestamp - saleStartTime[0];
        uint256 decreasedAmount = timeElapsed * 1e18 / 60;
        return ((INITIAL_SUPPLY * 1e18) - decreasedAmount) / 1e18;
    }
    
    // onlyOwner
    function setYieldToken(address address_) external onlyOwner {
        yieldToken = iYield(address_); 
    }
    function setProvenanceHashFinal(string memory finalHash_) external onlyOwner {
        PROVENANCE_HASH_FINAL = finalHash_;
    }
    function setMaxPerTxnPublic(uint256 maxPerTxnPublic_) external onlyOwner {
        maxPerTxnPublic = maxPerTxnPublic_;
    }
    function setMaxPerWalletPublic(uint256 maxPerWalletPublic_) external onlyOwner {
        maxPerWalletPublic = maxPerWalletPublic_;
    }
    function setMaxPerTxnWhitelist(uint256 maxPerTxnWhitelist_) external onlyOwner {
        maxPerTxnWhitelist = maxPerTxnWhitelist_;
    }
    function setMaxPerWalletWhitelist(uint256 maxPerWalletWhitelist_) external onlyOwner {
        maxPerWalletWhitelist = maxPerWalletWhitelist_;
    }
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }
    function setMerkleRootBaboonfrens(bytes32 merkleRootBaboonfrens_) external onlyOwner {
        merkleRootBaboonfrens = merkleRootBaboonfrens_;
    }
    function setMerkleRootDevTeam(bytes32 merkleRootDevTeam_) external onlyOwner {
        merkleRootDevTeam = merkleRootDevTeam_;
    }
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }
    function reserveTokens(uint256 quantity_) external onlyOwner {
        require(totalSupply() + quantity_ <= currentMaxSupply(), "Max supply exceeded");

        // Keep max chunks to 5 (to prevent high gas of future transfer)
        uint256 numChunks = quantity_ / 5;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, 5);
        }
        
        uint256 leftChunks = quantity_ % 5;
        if (leftChunks > 0) {
            _safeMint(msg.sender, leftChunks);
        }
    }

    // Withdraw
    function withdraw(address payable address_, uint256 amount_) private {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }
    function withdrawMoney() external onlyOwner {
        withdraw(payable(msg.sender), address(this).balance);
    }
    function withdrawLINK() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
    
    // Public Functions
    function remainingSupply() public view returns (uint256) {
        return currentMaxSupply() - totalSupply();
    }
    function transferFrom(address from_, address to_, uint256 tokenId_) public override nonReentrant {
        if (yieldToken != iYield(address(0x0))) {
            yieldToken.updateReward(from_, to_, tokenId_);
        }
        ERC721A.transferFrom(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override nonReentrant {
        if (yieldToken != iYield(address(0x0))) {
            yieldToken.updateReward(from_, to_, tokenId_);
        }
        ERC721A.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    // 0xInuarashi's Custom Functions
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) public {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            ERC721A.transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, uint256[] memory tokenIds_, bytes[] memory datas_) public {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            ERC721A.safeTransferFrom(from_, to_, tokenIds_[i], datas_[i]);
        }
    }
}