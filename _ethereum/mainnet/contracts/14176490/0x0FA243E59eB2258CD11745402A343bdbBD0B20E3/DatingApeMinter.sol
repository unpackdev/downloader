// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

enum SaleStage {
    None,
    WhiteList,
    Auction
}

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract DatingApeMinter is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1644494400; // Feb 10th 2022. 8:00PM UTC+8
    uint256 public whiteListSaleEndTime = whiteListSaleStartTime + 1 days;
    uint256 public whiteListSaleRemainingCount = 77;
    uint256 public whiteListSaleMintPrice = 0.2 ether;
    uint256 public whiteListSalePurchased;

    uint256 public auctionStartTime = 1644667200; // Feb 12 2022. 8:00PM UTC+8
    uint256 public auctionEndTime = auctionStartTime + 1 days; // Feb 13 2022. 8:00PM UTC+8
    uint256 public auctionTimeStep = 5 minutes;
    uint256 public totalAuctionTimeSteps = 5;

    uint256 public auctionStartPrice = 0.69 ether;
    uint256 public auctionEndPrice = 0.369 ether;
    uint256 public auctionPriceStep = 0.0642 ether;
    uint256 public auctionPurchased;
    uint256 public auctionMaxPurchasedQuantityPerTx = 3;
    uint256 public maxCountToBeDispensed = 234 + 77;
    address public datingApeTaiwanClub;
    bytes32 public whiteListMerkleRoot;

    mapping(address => bool) public whiteListPurchased;

    constructor(address _datingApeTaiwanClub) {
        datingApeTaiwanClub = _datingApeTaiwanClub;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    function getAuctionPrice() public view returns (uint256) {
        require(auctionStartTime != 0, "auctionStartTime not set");
        require(auctionEndTime != 0, "auctionEndTime not set");
        if (block.timestamp < auctionStartTime) {
            return auctionStartPrice;
        }
        uint256 timeSteps = (block.timestamp - auctionStartTime) /
            auctionTimeStep;
        if (timeSteps > totalAuctionTimeSteps) {
            timeSteps = totalAuctionTimeSteps;
        }
        uint256 discount = timeSteps * auctionPriceStep;
        return
            auctionStartPrice > discount
                ? auctionStartPrice - discount
                : auctionEndPrice;
    }

    function auctionRemainingCount() public view returns (uint256) {
        require(block.timestamp > auctionStartTime, "auction has not started");
        require(block.timestamp < auctionEndTime, "auction has ended");
        uint256 totalSold = whiteListSalePurchased + auctionPurchased;
        return
            totalSold <= maxCountToBeDispensed
                ? maxCountToBeDispensed - totalSold
                : 0;
    }

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: Whitelist Sale, 2: Auction
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whiteListSaleIsActive = (block.timestamp >
            whiteListSaleStartTime) && (block.timestamp < whiteListSaleEndTime);
        if (whiteListSaleIsActive) {
            return SaleStage.WhiteList;
        }
        bool auctionIsActive = (block.timestamp > auctionStartTime) &&
            (block.timestamp < auctionEndTime);
        if (auctionIsActive) {
            return SaleStage.Auction;
        }
        return SaleStage.None;
    }

    function buyApe(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.WhiteList) {
            _buyApeWhiteList(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.Auction) {
            _buyApeAuction(numberOfTokens);
        }
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _buyApeWhiteList(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(!whiteListPurchased[msg.sender], "whiteListPurchased already");
        require(
            proof.verify(
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(
            whiteListSaleRemainingCount >= numberOfTokens,
            "first whitelist sold out"
        );
        require(
            msg.value == whiteListSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        whiteListPurchased[msg.sender] = true;
        whiteListSaleRemainingCount -= numberOfTokens;
        whiteListSalePurchased += numberOfTokens;

        NFT(datingApeTaiwanClub).mint(msg.sender, numberOfTokens);
    }

    function _buyApeAuction(uint256 numberOfTokens) internal {
        require(
            auctionRemainingCount() >= numberOfTokens,
            "not enogugh left for this purchase"
        );
        require(
            numberOfTokens <= auctionMaxPurchasedQuantityPerTx,
            "numberOfTokens exceeds auctionMaxPurchasedQuantityPerTx"
        );
        uint256 price = getAuctionPrice();
        require(
            msg.value >= price * numberOfTokens,
            "sent ether value incorrect"
        );
        auctionPurchased += numberOfTokens;

        NFT(datingApeTaiwanClub).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _whiteListMerkleRoot) external onlyOwner {
        whiteListMerkleRoot = _whiteListMerkleRoot;
    }

    function setSaleData(
        uint256 _whiteListSaleStartTime,
        uint256 _whiteListSaleEndTime,
        uint256 _whiteListSaleRemainingCount,
        uint256 _whiteListSaleMintPrice,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _auctionTimeStep,
        uint256 _totalAuctionTimeSteps,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionPriceStep
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        whiteListSaleRemainingCount = _whiteListSaleRemainingCount;
        whiteListSaleMintPrice = _whiteListSaleMintPrice;
        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;
        auctionTimeStep = _auctionTimeStep;
        totalAuctionTimeSteps = _totalAuctionTimeSteps;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionPriceStep = _auctionPriceStep;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
