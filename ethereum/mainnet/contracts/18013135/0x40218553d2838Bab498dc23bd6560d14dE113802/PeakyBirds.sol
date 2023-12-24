// ██████╗ ███████╗ █████╗ ██╗  ██╗██╗   ██╗    ██████╗ ██╗██████╗ ██████╗ ███████╗
// ██╔══██╗██╔════╝██╔══██╗██║ ██╔╝╚██╗ ██╔╝    ██╔══██╗██║██╔══██╗██╔══██╗██╔════╝
// ██████╔╝█████╗  ███████║█████╔╝  ╚████╔╝     ██████╔╝██║██████╔╝██║  ██║███████╗
// ██╔═══╝ ██╔══╝  ██╔══██║██╔═██╗   ╚██╔╝      ██╔══██╗██║██╔══██╗██║  ██║╚════██║
// ██║     ███████╗██║  ██║██║  ██╗   ██║       ██████╔╝██║██║  ██║██████╔╝███████║
// ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       ╚═════╝ ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
                                                                                
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

contract PeakyBirds is ERC721URIStorage, Ownable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;

    enum MintStage { HoldersOnly, OpenToAll }
    MintStage public currentStage;

    string public baseURI = "ipfs://bafybeigausqbtbko3c4uiza4zkgazlvkitgaz4k2zoheocoozqaj5ycwxi/";
    uint256 public maxSupply = 6174;
    uint256 public currentSupply = 0;
    uint256 public maxMintedByOwner = 149;
    uint256 public mintedCountByOwner = 0;
    mapping(uint256 => address payable) public currentHolders;
    uint256[] public allTokenIds;
    mapping(address => bool) public hasMinted;
    address public otherNFTContract; 
    uint256 public auctionReserve = 1826;
    address public auctionHouse;
    bool public paused = false;
    uint256 public currentAuctionMintCount = 0;

    struct Round {
        uint256 totalTokens;
        uint256 mintedTokens;
        uint256 costForFirstToken;
        uint256 costForSubsequentTokens;
    }

    mapping(uint256 => Round) public rounds;
    uint256 public currentRound;

// Modifier to prevent execution when paused
modifier whenNotPaused() {
    require(!paused, "Contract is paused");
    _;
}
// getters for frontend
function getCostForFirstToken() public view returns (uint256) {
    return rounds[currentRound].costForFirstToken;
}

function getCostForSubsequentTokens() public view returns (uint256) {
    return rounds[currentRound].costForSubsequentTokens;
}
// Function to pause the contract, only callable by the owner
function pause() public onlyOwner {
    paused = true;
}

// Function to unpause the contract, only callable by the owner
function unpause() public onlyOwner {
    paused = false;
}

function createRound(uint256 roundNumber, uint256 totalTokens, uint256 costForFirstToken, uint256 costForSubsequentTokens) public onlyOwner {
    rounds[roundNumber] = Round(totalTokens, 0, costForFirstToken, costForSubsequentTokens);
}

function startRound(uint256 roundNumber) public onlyOwner {
    require(rounds[roundNumber].totalTokens > 0, "Round not defined");
    currentRound = roundNumber;
}

    // Royalty percentage
    uint256 public constant royaltyPercentage = 750; // Represented in basis points (7.5%)

    // Mapping to store the creator's address for each token ID
    mapping(uint256 => address payable) public creators;

    event Minted(address indexed user, uint256 tokenId);

    constructor(address _otherNFTContract) ERC721("PeakyBirds", "PB") {
        otherNFTContract = _otherNFTContract;
        currentStage = MintStage.HoldersOnly; // Start with the HoldersOnly stage
    }

    function setMintStage(MintStage stage) public onlyOwner {
        currentStage = stage;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURIForToken = _baseURI();
        return bytes(baseURIForToken).length > 0
            ? string(abi.encodePacked(baseURIForToken, tokenId.toString(), ".json"))
            : '';
    }

    function setAuctionHouse(address _auctionHouse) public onlyOwner {
        auctionHouse = _auctionHouse;
    }
    
function safeMint(uint256 numberOfTokens) public payable nonReentrant whenNotPaused {
    require(currentStage == MintStage.OpenToAll || IERC721(otherNFTContract).balanceOf(msg.sender) > 0, "Minting is only open to holders of the other NFT");
    require(numberOfTokens > 0 && numberOfTokens <= 3, "You can mint between 1 and 3 tokens at a time.");
    require(currentSupply + numberOfTokens <= maxSupply, "Exceeds max supply");

    Round storage round = rounds[currentRound];
    require(round.mintedTokens + numberOfTokens <= round.totalTokens, "Exceeds tokens for this round");

    uint256 requiredPayment = 0;
    if (hasMinted[msg.sender]) {
        requiredPayment = round.costForSubsequentTokens * numberOfTokens;
    } else {
        if (numberOfTokens > 1) {
            requiredPayment = round.costForFirstToken + round.costForSubsequentTokens * (numberOfTokens - 1);
        } else {
            requiredPayment = round.costForFirstToken;
        }
        hasMinted[msg.sender] = true;
    }

    require(msg.value >= requiredPayment, "Insufficient Ether sent");

    for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = randomTokenId();
        _safeMint(msg.sender, tokenId);
        currentSupply++;
        creators[tokenId] = payable(msg.sender); // Store the creator's address when minting
        emit Minted(msg.sender, tokenId);
    }

    // Refund excess ether
    uint256 excessAmount = msg.value - requiredPayment;
    if (excessAmount > 0) {
        payable(msg.sender).transfer(excessAmount);
    }

    round.mintedTokens += numberOfTokens; // Increment the number of tokens minted in this round
}



function randomTokenId() internal view returns (uint256) {
    uint256 tokenId;
    uint256 attempts = 0;
    do {
        tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, attempts, block.prevrandao))) % maxSupply;
        attempts++;
    } while (tokenExists(tokenId) && attempts < maxSupply - currentSupply);
    require(attempts < maxSupply - currentSupply, "Failed to generate a unique token ID");
    return tokenId;
}

function auctionMint(address to, uint256 tokenId) external {
    require(msg.sender == auctionHouse, "Only the auction house can call this function");
    require(currentAuctionMintCount < auctionReserve, "Auction reserve limit reached"); // Check against the reserve limit
    _safeMint(to, tokenId);
    currentSupply = currentSupply + 1;
    allTokenIds.push(tokenId); // Add the token ID to the array
    currentAuctionMintCount += 1; // Increment the count of times auctionMint has been called

}

    
    function updateCurrentHolder(uint256 tokenId, address payable newHolder) external {
        require(msg.sender == auctionHouse, "Only the auction house can call this function");
        currentHolders[tokenId] = newHolder;
}


function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // Update the current holder's address when transferring
    currentHolders[tokenId] = payable(to);
}    
    // EIP-2981 compliant function to retrieve the royalty information for a token
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        uint256 royaltyBasisPoints = royaltyPercentage;
        return (currentHolders[tokenId], salePrice * royaltyBasisPoints / 10000);
    }

function setAuctionReserve(uint256 _auctionReserve) public onlyOwner {
    require(_auctionReserve <= maxSupply, "Auction reserve cannot exceed max supply");
    auctionReserve = _auctionReserve;
    currentAuctionMintCount = 0; // Reset the current auction mint count
}



function batchDevMint(address to, uint256[] memory tokenIds) public onlyOwner {
    require(mintedCountByOwner + tokenIds.length <= maxMintedByOwner, "Max minted by owner reached");
    require(currentSupply + tokenIds.length <= maxSupply, "Max total supply reached");

    for (uint256 i = 0; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        _mint(to, tokenId);
        allTokenIds.push(tokenId); // Add the token ID to the array
        currentHolders[tokenId] = payable(to); // Update the current holder's address for the newly minted token
    }

    mintedCountByOwner = mintedCountByOwner + tokenIds.length;
    currentSupply = currentSupply + tokenIds.length; // Increment the total supply by the number of tokens minted
}


    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    // Function to get all token holders
    function getAllTokenHolders() public view returns (address[] memory) {
        address[] memory holders = new address[](allTokenIds.length);
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            holders[i] = currentHolders[allTokenIds[i]];
        }
        return holders;
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
}