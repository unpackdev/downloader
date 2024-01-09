// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

enum SaleStage {
    None,
    FirstWhiteList,
    SecondWhiteList,
    PublicSale
}

interface NFT {
    function mint(address receiver) external;
}

contract SueiBianDispenser is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public firstWhiteListSaleStartTime = 1642683600; // Jan 20th 2022. 9:00PM UTC+8
    uint256 public firstWhiteListSaleEndTime = 1642685400; // Jan 20th 2022. 9:30PM UTC+8
    uint256 public firstWhiteListSaleRemainingCount = 120;

    uint256 public secondWhiteListSaleStartTime = 1642685400; // Jan 20th 2022. 9:30PM UTC+8
    uint256 public secondWhiteListSaleEndTime = 1642687200; // Jan 20th 2022. 10:00PM UTC+8
    uint256 public secondWhiteListSaleRemainingCount = 180;

    uint256 public publicSaleStartTime = 1642687200; // Jan 20th 2022. 10:00PM UTC+8
    uint256 public publicSaleEndTime = 1642689000; // Jan 20th 2022. 10:30PM UTC+8
    uint256 public publicSalePurchasedCount = 0;
    uint256 public publicSaleMaxPurchaseAmount = 3;

    uint256 public maxDispenseCount = 300;

    uint256 public mintPrice = 0.08 ether;

    bytes32 private _firstWhiteListMerkleRoot;
    bytes32 private _secondWhiteListMerkleRoot;

    address public sueiBianDAOAddress;
    mapping(address => bool) public firstWhiteListPurchased;
    mapping(address => bool) public secondWhiteListPurchased;

    constructor(address _sueiBianDAOAddress) {
        sueiBianDAOAddress = _sueiBianDAOAddress;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function publicSaleRemainingCount() public view returns (uint256) {
        uint256 totalWhiteListRemainingCount = firstWhiteListSaleRemainingCount +
                secondWhiteListSaleRemainingCount;
        return
            publicSalePurchasedCount <= totalWhiteListRemainingCount
                ? totalWhiteListRemainingCount - publicSalePurchasedCount
                : 0;
    }

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: First Whitelist Sale, 2: Second Whitelist Sale, 3: Public Sale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool firstWhiteListSaleIsActive = (block.timestamp >
            firstWhiteListSaleStartTime) &&
            (block.timestamp < firstWhiteListSaleEndTime);
        if (firstWhiteListSaleIsActive) {
            return SaleStage.FirstWhiteList;
        }
        bool secondWhiteListSaleIsActive = (block.timestamp >
            secondWhiteListSaleStartTime) &&
            (block.timestamp < secondWhiteListSaleEndTime);
        if (secondWhiteListSaleIsActive) {
            return SaleStage.SecondWhiteList;
        }
        bool publicSaleIsActive = (block.timestamp > publicSaleStartTime) &&
            (block.timestamp < publicSaleEndTime);
        if (publicSaleIsActive) {
            return SaleStage.PublicSale;
        }
        return SaleStage.None;
    }

    function sueiBianBuy(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(
            msg.value == mintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.FirstWhiteList) {
            _sueiBianBuyFirstWhiteList(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.SecondWhiteList) {
            _sueiBianBuySecondWhiteList(proof, numberOfTokens);
        } else {
            _sueiBianBuyPublicSale(numberOfTokens);
        }
    }

    function _sueiBianBuyFirstWhiteList(
        bytes32[] calldata proof,
        uint256 numberOfTokens
    ) internal {
        require(
            !firstWhiteListPurchased[msg.sender],
            "firstWhiteListPurchased already"
        );
        require(
            proof.verify(
                _firstWhiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(
            firstWhiteListSaleRemainingCount >= numberOfTokens,
            "first whitelist sold out"
        );
        firstWhiteListPurchased[msg.sender] = true;
        firstWhiteListSaleRemainingCount -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    function _sueiBianBuySecondWhiteList(
        bytes32[] calldata proof,
        uint256 numberOfTokens
    ) internal {
        require(
            !secondWhiteListPurchased[msg.sender],
            "secondWhiteListPurchased already"
        );
        require(
            proof.verify(
                _secondWhiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify second WL merkle root"
        );
        require(
            secondWhiteListSaleRemainingCount >= numberOfTokens,
            "second whitelist sold out"
        );
        secondWhiteListPurchased[msg.sender] = true;
        secondWhiteListSaleRemainingCount -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    function _sueiBianBuyPublicSale(uint256 numberOfTokens) internal {
        require(
            publicSaleRemainingCount() >= numberOfTokens,
            "public sale sold out"
        );
        require(
            numberOfTokens <= publicSaleMaxPurchaseAmount,
            "numberOfTokens exceeds publicSaleMaxPurchaseAmount"
        );

        publicSalePurchasedCount += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(sueiBianDAOAddress).mint(msg.sender);
        }
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoots(bytes32 _firstMerkleRoot, bytes32 _secondMerkleRoot)
        external
        onlyOwner
    {
        _firstWhiteListMerkleRoot = _firstMerkleRoot;
        _secondWhiteListMerkleRoot = _secondMerkleRoot;
    }

    function setSaleData(
        uint256 _firstWhiteListSaleStartTime,
        uint256 _firstWhiteListSaleEndTime,
        uint256 _firstWhiteListSaleRemainingCount,
        uint256 _secondWhiteListSaleStartTime,
        uint256 _secondWhiteListSaleEndTime,
        uint256 _secondWhiteListSaleRemainingCount,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSalePurchasedCount,
        uint256 _publicSaleMaxPurchaseAmount,
        uint256 _maxDispenseCount,
        uint256 _mintPrice
    ) external onlyOwner {
        firstWhiteListSaleStartTime = _firstWhiteListSaleStartTime;
        firstWhiteListSaleEndTime = _firstWhiteListSaleEndTime;
        firstWhiteListSaleRemainingCount = _firstWhiteListSaleRemainingCount;
        secondWhiteListSaleStartTime = _secondWhiteListSaleStartTime;
        secondWhiteListSaleEndTime = _secondWhiteListSaleEndTime;
        secondWhiteListSaleRemainingCount = _secondWhiteListSaleRemainingCount;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSalePurchasedCount = _publicSalePurchasedCount;
        publicSaleMaxPurchaseAmount = _publicSaleMaxPurchaseAmount;
        maxDispenseCount = _maxDispenseCount;
        mintPrice = _mintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
