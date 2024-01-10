// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

enum SaleStage {
    None,
    FirstWhiteList,
    SecondWhiteList,
    PublicSale
}

contract RakutenMonkeyNFTClub is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public firstWhiteListSaleStartTime = 1648461600; // 3/28 6pm
    uint256 public firstWhiteListSaleEndTime = 1648526400; // 3/29 12pm
    uint256 public firstWhiteListSaleRemainingCount = 10;

    uint256 public secondWhiteListSaleStartTime = 1648612800; // 3/30 12pm
    uint256 public secondWhiteListSaleEndTime =
        secondWhiteListSaleStartTime + 1 days; // 3/31 12pm
    uint256 public secondWhiteListSaleRemainingCount = 40;

    uint256 public publicSaleStartTime = secondWhiteListSaleEndTime + 1 days; // 4/1 12pm
    uint256 public publicSaleEndTime = publicSaleStartTime + 6 days; // 4/7 12pm
    uint256 public publicSalePurchasedCount = 0;
    uint256 public publicSaleAllocatedAmount = 50;
    uint256 public publicSaleMaxPurchaseAmount = 3;

    uint256 public maxTotalSupply = 150;

    uint256 public publicSaleMintPrice = 0.05 ether;
    uint256 public whitelistSaleMintPrice = 0.04 ether;

    bytes32 private firstWhiteListMerkleRoot;
    bytes32 private secondWhiteListMerkleRoot;

    mapping(address => bool) public firstWhiteListPurchased;
    mapping(address => bool) public secondWhiteListPurchased;

    constructor() ERC721A("Rakuten Monkey NFT Club", "RMNC") {
        _safeMint(msg.sender, 50);
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function publicSaleRemainingCount() public view returns (uint256) {
        uint256 totalRemainingCount = firstWhiteListSaleRemainingCount +
            secondWhiteListSaleRemainingCount +
            publicSaleAllocatedAmount;
        return
            publicSalePurchasedCount <= totalRemainingCount
                ? totalRemainingCount - publicSalePurchasedCount
                : 0;
    }

    function remainingCount() public view returns (uint256) {
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        if (currentActiveSaleStage == SaleStage.None) {
            return 0;
        } else if (currentActiveSaleStage == SaleStage.FirstWhiteList) {
            return firstWhiteListSaleRemainingCount;
        } else if (currentActiveSaleStage == SaleStage.SecondWhiteList) {
            return secondWhiteListSaleRemainingCount;
        } else {
            return publicSaleRemainingCount();
        }
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

    function mint(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(
            totalSupply() + numberOfTokens <= maxTotalSupply,
            "exceeds max total supply"
        );
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.FirstWhiteList) {
            _mintFirstWhiteList(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.SecondWhiteList) {
            _mintSecondWhiteList(proof, numberOfTokens);
        } else {
            _mintPublicSale(numberOfTokens);
        }
    }

    function _mintFirstWhiteList(
        bytes32[] calldata proof,
        uint256 numberOfTokens
    ) internal {
        // free, no need to check msg.value
        require(
            !firstWhiteListPurchased[msg.sender],
            "firstWhiteListPurchased already"
        );
        require(
            proof.verify(
                firstWhiteListMerkleRoot,
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
        _safeMint(msg.sender, numberOfTokens);
    }

    function _mintSecondWhiteList(
        bytes32[] calldata proof,
        uint256 numberOfTokens
    ) internal {
        require(
            msg.value == whitelistSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(
            !secondWhiteListPurchased[msg.sender],
            "secondWhiteListPurchased already"
        );
        require(
            proof.verify(
                secondWhiteListMerkleRoot,
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
        _safeMint(msg.sender, numberOfTokens);
    }

    function _mintPublicSale(uint256 numberOfTokens) internal {
        require(
            msg.value == publicSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(
            publicSaleRemainingCount() >= numberOfTokens,
            "public sale sold out"
        );
        require(
            numberOfTokens <= publicSaleMaxPurchaseAmount,
            "numberOfTokens exceeds publicSaleMaxPurchaseAmount"
        );

        publicSalePurchasedCount += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */
    function setMerkleRoots(bytes32 _firstMerkleRoot, bytes32 _secondMerkleRoot)
        external
        onlyOwner
    {
        firstWhiteListMerkleRoot = _firstMerkleRoot;
        secondWhiteListMerkleRoot = _secondMerkleRoot;
    }

    function setSaleData(
        uint256 _firstWhiteListSaleStartTime,
        uint256 _firstWhiteListSaleEndTime,
        uint256 _secondWhiteListSaleStartTime,
        uint256 _secondWhiteListSaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleMintPrice,
        uint256 _whitelistSaleMintPrice
    ) external onlyOwner {
        firstWhiteListSaleStartTime = _firstWhiteListSaleStartTime;
        firstWhiteListSaleEndTime = _firstWhiteListSaleEndTime;
        secondWhiteListSaleStartTime = _secondWhiteListSaleStartTime;
        secondWhiteListSaleEndTime = _secondWhiteListSaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleMintPrice = _publicSaleMintPrice;
        whitelistSaleMintPrice = _whitelistSaleMintPrice;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}
