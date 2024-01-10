// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract TaipeiBugMinter is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1645853400; // 2/26 1:30pm
    uint256 public whiteListSaleEndTime = 1646053200; // 2/28 9:00pm
    uint256 public whiteListSaleRemainingCount = 114;
    uint256 public whiteListSaleMintPrice = 0.1 ether;
    address public taipeiBug;
    bytes32 public whiteListMerkleRoot;

    mapping(address => bool) public whiteListPurchased;

    constructor(address _taigpeiBug) {
        taipeiBug = _taigpeiBug;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    function buyBug(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(block.timestamp >= whiteListSaleStartTime, "not started");
        require(block.timestamp <= whiteListSaleEndTime, "has ended");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
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

        NFT(taipeiBug).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _whiteListMerkleRoot) external onlyOwner {
        whiteListMerkleRoot = _whiteListMerkleRoot;
    }

    function setWhiteListData(
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
