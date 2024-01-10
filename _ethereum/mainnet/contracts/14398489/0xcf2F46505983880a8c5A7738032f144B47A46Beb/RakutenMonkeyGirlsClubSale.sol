// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

enum SaleStage {
    None,
    WhiteList,
    PublicSale
}

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract RakutenMonkeyGirlsClubSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1647489600;
    uint256 public whiteListSaleEndTime = whiteListSaleStartTime + 1 days;
    uint256 public whiteListSaleMintPrice = 0.1 ether;

    uint256 public publicSaleStartTime = whiteListSaleEndTime;
    uint256 public publicSaleEndTime = publicSaleStartTime + 2 days;
    uint256 public publicSalePrice = 0.15 ether;
    uint256 public remainingCount = 309;

    uint256 public maxPurchaseQuantityPerTx = 2;
    address public rmgc;
    bytes32 public whiteListMerkleRoot;

    mapping(address => bool) public whiteListPurchased;

    constructor(address _rmgc) {
        rmgc = _rmgc;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: Whitelist Sale, 2: PublicSale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whiteListSaleIsActive = (block.timestamp >
            whiteListSaleStartTime) && (block.timestamp < whiteListSaleEndTime);
        if (whiteListSaleIsActive) {
            return SaleStage.WhiteList;
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
        require(tx.origin == msg.sender, "contract not allowed");
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.WhiteList) {
            _mintWhiteList(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.PublicSale) {
            _mintPublicSale(numberOfTokens);
        }
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _mintWhiteList(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(!whiteListPurchased[msg.sender], "whiteListPurchased already");
        require(
            proof.verify(
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify merkle proof"
        );
        require(numberOfTokens <= remainingCount, "sold out");
        require(
            msg.value == whiteListSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        whiteListPurchased[msg.sender] = true;
        remainingCount -= numberOfTokens;

        NFT(rmgc).mint(msg.sender, numberOfTokens);
    }

    function _mintPublicSale(uint256 numberOfTokens) internal {
        require(
            numberOfTokens <= remainingCount,
            "not enogugh left for this purchase"
        );
        require(
            numberOfTokens <= maxPurchaseQuantityPerTx,
            "numberOfTokens exceeds maxPurchaseQuantityPerTx"
        );

        require(
            msg.value == publicSalePrice * numberOfTokens,
            "sent ether value incorrect"
        );
        remainingCount -= numberOfTokens;
        NFT(rmgc).mint(msg.sender, numberOfTokens);
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
        uint256 _whiteListSaleMintPrice,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSalePrice,
        uint256 _remainingCount
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        whiteListSaleMintPrice = _whiteListSaleMintPrice;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSalePrice = _publicSalePrice;
        remainingCount = _remainingCount;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}
