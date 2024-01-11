// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

enum SaleStage {
    None,
    whitelist,
    publicSale
}

interface NFT {
    function mint(address to, uint256 quantity) external;

    function totalSupply() external view returns (uint256);
}

contract RichmanHeroesSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whitelistSaleStartTime = 1650963600; // 4/26 5pm
    uint256 public whitelistSaleEndTime = whitelistSaleStartTime + 3 hours; // 4/26 8pm
    uint256 public publicSaleStartTime = 1650978000; // 4/26 9pm
    uint256 public publicSaleEndTime = publicSaleStartTime + 1 days; // 4/27 9pm
    uint256 public publicSaleMaxPurchaseAmount = 10;
    uint256 public hardCap = 1111;
    uint256 public whitelistMintPrice = 0.3 ether;
    uint256 public publicSaleMintPrice = 0.36 ether;
    bytes32 private _whitelistMerkleRoot;
    address public richmanHeroesAddress;
    mapping(address => bool) public whitelistPurchased;

    constructor(address _richmanHeroesAddress) {
        richmanHeroesAddress = _richmanHeroesAddress;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    function remainingCount() public view returns (uint256) {
        uint256 currentTotalSupply = NFT(richmanHeroesAddress).totalSupply();
        return currentTotalSupply <= hardCap ? hardCap - currentTotalSupply : 0;
    }

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: First Whitelist Sale, 2: Public Sale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whitelistSaleIsActive = (block.timestamp >
            whitelistSaleStartTime) && (block.timestamp < whitelistSaleEndTime);
        if (whitelistSaleIsActive) {
            return SaleStage.whitelist;
        }
        bool publicSaleIsActive = (block.timestamp > publicSaleStartTime) &&
            (block.timestamp < publicSaleEndTime);
        if (publicSaleIsActive) {
            return SaleStage.publicSale;
        }
        return SaleStage.None;
    }

    function mint(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contracts not allowed to mint");
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.whitelist) {
            _mintwhitelist(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.publicSale) {
            _mintpublicSale(numberOfTokens);
        }
    }

    function _mintwhitelist(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(
            msg.value == whitelistMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(!whitelistPurchased[msg.sender], "whitelistPurchased already");
        require(
            proof.verify(
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(numberOfTokens <= remainingCount(), "whitelist sold out");
        whitelistPurchased[msg.sender] = true;
        NFT(richmanHeroesAddress).mint(msg.sender, numberOfTokens);
    }

    function _mintpublicSale(uint256 numberOfTokens) internal {
        require(
            msg.value == publicSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(numberOfTokens <= remainingCount(), "remaining quantity is not enough for your purchase");
        require(
            numberOfTokens <= publicSaleMaxPurchaseAmount,
            "numberOfTokens exceeds publicSaleMaxPurchaseAmount"
        );
        NFT(richmanHeroesAddress).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _whitelistMerkleRoot = _merkleRoot;
    }

    function setSaleData(
        uint256 _whitelistSaleStartTime,
        uint256 _whitelistSaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleMaxPurchaseAmount,
        uint256 _hardCap,
        uint256 _whitelistMintPrice,
        uint256 _publicSaleMintPrice
    ) external onlyOwner {
        whitelistSaleStartTime = _whitelistSaleStartTime;
        whitelistSaleEndTime = _whitelistSaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleMaxPurchaseAmount = _publicSaleMaxPurchaseAmount;
        hardCap = _hardCap;
        whitelistMintPrice = _whitelistMintPrice;
        publicSaleMintPrice = _publicSaleMintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address partyA = 0x68e7bCec3D5b90AA82351AFC5a3FA31239608423;
        address partyB = 0x72fAffaaD2A73643C126281f931cFc61ae8F89FE;
        uint256 partyAAmount = (balance * 7) / 10;
        uint256 partyBAmount = balance - partyAAmount;
        (bool sentA, ) = partyA.call{value: partyAAmount}("");
        require(sentA, "sent value failed for A");
        (bool sentB, ) = partyB.call{value: partyBAmount}("");
        require(sentB, "sent value failed for B");
    }
}
