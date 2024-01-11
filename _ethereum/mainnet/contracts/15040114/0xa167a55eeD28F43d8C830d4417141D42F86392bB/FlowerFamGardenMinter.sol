// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./OwnableUpgradeable.sol";

import "./MerkleProof.sol";

interface IFlowerFamGarden {
    function mint(address sender, uint256 amount) external;

    function getLastMintedId() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function numberMinted(address owner) external view returns (uint256);
}

contract FlowerFamGardenMinter is OwnableUpgradeable {
    IFlowerFamGarden public flowerFamGarden;

    uint256 public maxSupply;
    uint256 public price;
    uint256 public minPrice;
    uint256 public priceStep;
    uint256 public claimMintSupply;
    uint256 public publicMintSupply;
    uint256 public maxMintPerWallet;

    bytes32 public claimMerkleRoot;

    uint256 public startTimePublic;
    uint256 public publicMintDuration;

    uint256 public startTimeClaim;
    uint256 public endTimeClaim;

    mapping(address => uint256) public addressToClaim;

    constructor(
        address _flowerFamGardenNFT
    ) {}

    function initialize(
        address _flowerFamGardenNFT
    ) public initializer {
        __Ownable_init();

        flowerFamGarden = IFlowerFamGarden(_flowerFamGardenNFT);

        maxSupply = 6420;
        price = 0.15 ether;
        minPrice = 0.05 ether;
        priceStep = 0.01 ether;
        claimMintSupply = 3420;
        maxMintPerWallet = 5;
        publicMintSupply = maxSupply - claimMintSupply;

        startTimePublic = 1656432000 - 1 minutes;
        publicMintDuration = 20 minutes;

        startTimeClaim = 1656604800;
        endTimeClaim = 1656604800 + 100 minutes;        
    }


    receive() external payable {}

    function _merkleProofMint(bytes32[] calldata proof, uint256 maxAmount, uint256 mintAmount) internal {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAmount));

        require(
            MerkleProof.verify(proof, claimMerkleRoot, leaf),
            "Sender not allowed to mint in this round"
        );
      
        require(mintAmount > 0, "Invalid mint amount");
        require(
            flowerFamGarden.totalSupply() + mintAmount <= maxSupply,
            "Flower Fam Garden NFT is sold out"
        );
        require(addressToClaim[msg.sender] + mintAmount <= maxAmount);

        addressToClaim[msg.sender] += mintAmount;

        flowerFamGarden.mint(msg.sender, mintAmount);
    }

    function claimMint(bytes32[] calldata proof, uint256 maxAmount, uint256 mintAmount) external {
        require(block.timestamp < endTimeClaim, "Claim mint closed");
        require(block.timestamp >= startTimeClaim, "Claim mint not started");
        _merkleProofMint(proof, maxAmount, mintAmount);
    }

    function publicMint(uint256 amount) external payable {
        uint256 publicMintPrice = getPublicMintPrice();
        require(amount > 0, "Cannot mint zero gardens");    
        require(
            flowerFamGarden.totalSupply() + amount <= publicMintSupply,
            "Flower Fam Garden NFT is sold out"
        );
        require(msg.value >= amount * publicMintPrice, "Not enough eth sent");
        require(flowerFamGarden.numberMinted(msg.sender) + amount <= maxMintPerWallet, "User minted more than allowed");
        require(block.timestamp >= startTimePublic || msg.sender == owner(), "Public mint not started");

        flowerFamGarden.mint(msg.sender, amount);       
    }

    function getPublicMintPrice() public view returns (uint256) {
        uint256 newPrice = price;
        uint256 currentTime = block.timestamp;

        if (currentTime > startTimePublic) {
            uint256 diffInMinutes = (block.timestamp - startTimePublic) /
                publicMintDuration;
            if (priceStep * diffInMinutes <= price) {
                newPrice = price - priceStep * diffInMinutes;
            }

            if (newPrice < minPrice || priceStep * diffInMinutes > price) {
                newPrice = minPrice;
            }
        }

        return newPrice;
    }

    function getActiveRound() public view returns (uint256) {
        uint256 activeRound = 0;

        if (
            block.timestamp >= startTimePublic &&
            getPublicMintPrice() >= minPrice &&
            flowerFamGarden.totalSupply() < publicMintSupply
        ) {
            activeRound = 1;
        }

        if (
            block.timestamp >= startTimeClaim && block.timestamp < endTimeClaim
        ) {
            activeRound = 2;
        }

        return activeRound;
    }

    function getSupplyLeft() external view returns (uint256) {
        uint256 currentRound = getActiveRound();
        uint256 totalSupply = flowerFamGarden.totalSupply();        

        if (totalSupply > maxSupply) return 0;

        if (currentRound == 1) {
            return publicMintSupply - totalSupply;
        } else if (currentRound == 2) {
            return maxSupply - totalSupply;
        }

        return 0;
    }

    function setClaimMintTimestamp(uint256 startTime, uint256 endTime)
        external
        onlyOwner
    {
        endTimeClaim = endTime;
        startTimeClaim = startTime;
    }

    function setPublicMintStart(uint256 startTime, uint256 mintDuration)
        external
        onlyOwner
    {
        startTimePublic = startTime;
        publicMintDuration = mintDuration;
    }

    function setClaimMerkleRoot(bytes32 root) external onlyOwner {
        claimMerkleRoot = root;
    }

    function setMaxSupply(uint256 newMaxSupply, uint256 newClaimMintMaxSupply)
        external
        onlyOwner
    {
        maxSupply = newMaxSupply;
        claimMintSupply = newClaimMintMaxSupply;
        publicMintSupply = newMaxSupply - newClaimMintMaxSupply;
    }

    function setPrice(
        uint256 newPrice,
        uint256 newMinPrice,
        uint256 newPriceStep
    ) external onlyOwner {
        price = newPrice;
        minPrice = newMinPrice;
        priceStep = newPriceStep;
    }

    function setMaxMintPerWallet(uint256 newMax) external onlyOwner {
        maxMintPerWallet = newMax;
    }

    function withdraw(address _to, uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance zero");
        require(balance >= amount, "Balance less than amount");
        require(_to != address(0), "Cannot transfer to null address");
        payable(_to).transfer(amount);
    }
}