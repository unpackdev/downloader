// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

// 88b           d88              88888888ba                             88
// 888b         d888              88      "8b                            88
// 88`8b       d8'88              88      ,8P                            88
// 88 `8b     d8' 88   ,adPPYba,  88aaaaaa8P'  88       88  8b,dPPYba,   88   ,d8
// 88  `8b   d8'  88  a8P_____88  88""""""'    88       88  88P'   `"8a  88 ,a8"
// 88   `8b d8'   88  8PP"""""""  88           88       88  88       88  8888[
// 88    `888'    88  "8b,   ,aa  88           "8a,   ,a88  88       88  88`"Yba,
// 88     `8'     88   `"Ybbd8"'  88            `"YbbdP'Y8  88       88  88   `Y8a

interface NFT {
    function mint(address receiver) external;
}

contract MePunkWhiteListSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1644840000; // Feb 14th 2022. 8:00PM UTC+8
    uint256 public whiteListSaleEndTime = whiteListSaleStartTime + 1 days;
    uint256 public whiteListSaleRemainingCount = 108;
    uint256 public whiteListSaleMintPrice = 0.15 ether;
    address public mePunk;
    bytes32 public whiteListMerkleRoot;

    mapping(address => bool) public whiteListPurchased;

    constructor(address _mePunk) {
        mePunk = _mePunk;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    function buyMePunk(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(block.timestamp > whiteListSaleStartTime, "not started");
        require(block.timestamp < whiteListSaleEndTime, "has ended");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(!whiteListPurchased[msg.sender], "whiteListPurchased already");
        require(
            proof.verify(
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify WL merkle root"
        );
        require(
            whiteListSaleRemainingCount >= numberOfTokens,
            "whitelist sold out"
        );
        require(
            msg.value == whiteListSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        whiteListPurchased[msg.sender] = true;
        whiteListSaleRemainingCount -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(mePunk).mint(msg.sender);
        }
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
        uint256 _whiteListSaleMintPrice
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        whiteListSaleRemainingCount = _whiteListSaleRemainingCount;
        whiteListSaleMintPrice = _whiteListSaleMintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
