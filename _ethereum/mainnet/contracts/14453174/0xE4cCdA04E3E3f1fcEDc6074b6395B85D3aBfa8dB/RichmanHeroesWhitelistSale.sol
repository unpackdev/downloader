// SPDX-License-Identifier: MIT
// warrencheng.eth
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

enum SaleStage {
    None,
    WhiteList
}

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract RichmanHeroesWhitelistSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1648213200; // 3/25 9pm
    uint256 public whiteListSaleEndTime = whiteListSaleStartTime + 2 days;
    uint256 public whiteListSaleMintPrice = 0.27 ether;

    uint256 public maxPurchaseQuantityPerTx = 1;
    address public richmanHeroes;
    address public softstar = 0x68e7bCec3D5b90AA82351AFC5a3FA31239608423;
    address public operation = 0x72fAffaaD2A73643C126281f931cFc61ae8F89FE;
    bytes32 public whiteListMerkleRoot;

    mapping(address => bool) public whiteListPurchased;

    constructor(address _richmanHeroes) {
        richmanHeroes = _richmanHeroes;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: Whitelist Sale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whiteListSaleIsActive = (block.timestamp >
            whiteListSaleStartTime) && (block.timestamp < whiteListSaleEndTime);
        if (whiteListSaleIsActive) {
            return SaleStage.WhiteList;
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
            currentActiveSaleStage == SaleStage.WhiteList,
            "whitelist sale not active"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        _mintWhiteList(proof, numberOfTokens);
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
        require(
            msg.value == whiteListSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        whiteListPurchased[msg.sender] = true;

        NFT(richmanHeroes).mint(msg.sender, numberOfTokens);
        // redirect revenue
        uint256 softstarShare = (msg.value * 70) / 100;
        uint256 operationShare = msg.value - softstarShare;
        (bool softstarSent, ) = softstar.call{value: softstarShare}("");
        require(softstarSent, "sent value failed");
        (bool operationSent, ) = operation.call{value: operationShare}("");
        require(operationSent, "sent value failed");
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
        uint256 _whiteListSaleMintPrice
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        whiteListSaleMintPrice = _whiteListSaleMintPrice;
    }
}
