// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}
enum SaleStage {
    None,
    WhiteList,
    Auction
}

contract AlphaKidsSale is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1649988000; // 4/15 10am
    uint256 public whiteListSaleEndTime = 1650078000; // 4/16 11am
    uint256 public whiteListSaleMintPrice = 0.26 ether;
    uint256 public auctionStartTime = 1650087000; // 4/16 1.30pm
    uint256 public auctionEndTime = 1650094200; // 4/16 3.30pm
    uint256 public auctionTimeStep = 10 minutes;
    uint256 public totalAuctionTimeSteps = 2;
    uint256 public auctionStartPrice = 0.36 ether;
    uint256 public auctionEndPrice = 0.30 ether;
    uint256 public auctionPriceStep = 0.03 ether;
    uint256 public auctionMaxPurchaseQuantityPerTx = 1;
    uint256 public remainingCount = 369;

    address public alphaKids;
    bytes32 public whiteListMerkleRoot;
    mapping(address => bool) public whiteListPurchased;

    constructor(address _alphaKids) {
        alphaKids = _alphaKids;
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

    function mint(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contract not allowed");
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.WhiteList) {
            _mintWhiteList(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.Auction) {
            _mintAuction(numberOfTokens);
        }
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _mintWhiteList(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(
            msg.value == whiteListSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(!whiteListPurchased[msg.sender], "whiteListPurchased already");
        require(
            proof.verify(
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(numberOfTokens <= remainingCount, "whiteList sold out");
        whiteListPurchased[msg.sender] = true;
        remainingCount -= 1;
        NFT(alphaKids).mint(msg.sender, numberOfTokens);
    }

    function _mintAuction(uint256 numberOfTokens) internal {
        require(
            msg.value >= getAuctionPrice() * numberOfTokens,
            "sent ether value incorrect"
        );
        require(numberOfTokens <= remainingCount, "auction sold out");
        require(
            numberOfTokens <= auctionMaxPurchaseQuantityPerTx,
            "numberOfTokens exceeds auctionMaxPurchaseQuantityPerTx"
        );

        remainingCount -= 1;
        NFT(alphaKids).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function setSaleData(
        uint256 _whiteListSaleStartTime,
        uint256 _whiteListSaleEndTime,
        uint256 _whiteListSaleMintPrice,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _auctionTimeStep,
        uint256 _totalAuctionTimeSteps,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionPriceStep,
        uint256 _auctionMaxPurchaseQuantityPerTx,
        uint256 _remainingCount
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        whiteListSaleMintPrice = _whiteListSaleMintPrice;
        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;
        auctionTimeStep = _auctionTimeStep;
        totalAuctionTimeSteps = _totalAuctionTimeSteps;
        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;
        auctionPriceStep = _auctionPriceStep;
        auctionMaxPurchaseQuantityPerTx = _auctionMaxPurchaseQuantityPerTx;
        remainingCount = _remainingCount;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}
