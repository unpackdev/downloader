// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SimpleFactory.sol";
import "./VibeERC721.sol";
import "./IDistributor.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./BoringERC20.sol";

contract Airdrop is Ownable {
    using BoringERC20 for IERC20;
    SimpleFactory public immutable vibeFactory;
    VibeERC721 public bonusNFT;
    VibeERC721 public originalNFT;
    uint256 public NON_WHITELISTED_MAX_PER_USER;

    uint32 public beginTime;
    uint32 public endTime;
    bytes32 public merkleRoot;
    string public externalURI;
    uint256 public maxRedemption;
    uint256 public totalRedemptions;
    bool public isPhysicalRedemption;
    bool public isSpecifyId;

    struct VibeFees {
        address vibeTreasury;
        uint96 feeTake;
        uint64 mintingFee;
    }
    VibeFees public fees;
    IERC20 public paymentToken;
    uint96 public redemptionFee;
    uint256 public constant BPS = 100_000;

    struct RedemptionStatus {
        uint256 quantity;
        bool submit;
        bytes data;
        bool feedback;
        bytes feedbackData;
    }
    mapping(uint256 => RedemptionStatus) redeemed;

    event Created(bytes data);
    event LogNFTMint(address indexed recipient, uint256 tokenId);
    event LogSetVibeFees(address indexed vibeTreasury_, uint96 feeTake_);
    event LogSetMerkleRoot(bytes32 indexed merkleRoot, string externalURI);
    event TokensClaimed(uint256 total, uint256 fee, address proceedRecipient);
    event LogNFTRedemption(address indexed recipient, uint256 originalId, uint256 bonusId);
    event LogPhysicalRedemption(address indexed sender, uint256 originalId);

    constructor(SimpleFactory vibeFactory_) {
        vibeFactory = vibeFactory_;
    }

    modifier onlyMasterContractOwner() {
        address master = vibeFactory.masterContractOf(address(this));
        if (master != address(0)) {
            require(Ownable(master).owner() == msg.sender, "Airdrop: Not master contract owner.");
        } else {
            require(owner() == msg.sender, "Airdrop: Not owner.");
        }
        _;
    }

    function init(bytes calldata data) external {
        (
            address bonus,
            address original,
            uint32 beginTime_,
            uint32 endTime_,
            IERC20 paymentToken_,
            uint96 redemptionFee_,
            address owner_,
            bool physical,
            bool specifyId
        ) = abi.decode(data, (address, address, uint32, uint32, IERC20, uint96, address, bool, bool));
        require((beginTime_ == 0 && endTime_ == 0) || beginTime_ < endTime_, "Airdrop: Invalid time range.");
        require(original != address(0), "Airdrop: Invalid original nft address.");
        if (!physical) {
            require(bonus != address(0), "Airdrop: Invalid bonus nft address.");
            bonusNFT = VibeERC721(bonus);
        }

        _transferOwnership(owner_);

        {
            (address treasury, uint96 feeTake, uint64 mintingFee) = Airdrop(vibeFactory.masterContractOf(address(this))).fees();
            fees = VibeFees(treasury, feeTake, mintingFee);
        }

        originalNFT = VibeERC721(original);
        beginTime = beginTime_;
        endTime = endTime_;
        isPhysicalRedemption = physical;
        isSpecifyId = specifyId;
        paymentToken = paymentToken_;
        redemptionFee = redemptionFee_;

        emit Created(data);
    }

    function setVibeFees(address vibeTreasury_, uint96 feeTake_, uint64 mintingFee_) external onlyMasterContractOwner {
        require(vibeTreasury_ != address(0), "Airdrop: Vibe treasury cannot be 0.");
        require(feeTake_ <= BPS, "Airdrop: Fee cannot be greater than 100%.");
        fees = VibeFees(vibeTreasury_, feeTake_, mintingFee_);
        emit LogSetVibeFees(vibeTreasury_, feeTake_);
    }

    function setMerkleRoot(bytes32 merkleRoot_, string memory externalURI_, uint256 maxNonWhitelistedPerUser) external onlyOwner {
        merkleRoot = merkleRoot_;
        externalURI = externalURI_;
        NON_WHITELISTED_MAX_PER_USER = maxNonWhitelistedPerUser;
        emit LogSetMerkleRoot(merkleRoot_, externalURI_);
    }

    function nftRedemption(address recipient, bytes32[] calldata proof, uint256 originalTokenId, uint256 quantity) external payable {
        bytes memory data;
        _redemptionPreCheck(data, originalTokenId);
        require(!isPhysicalRedemption, "Airdrop: Non-NFT redemption.");
        _merkleProofVerify(proof, originalTokenId, quantity);
        uint256 id = _mintNFT(recipient, originalTokenId);
        getPayment(redemptionFee, fees.mintingFee);
        emit LogNFTRedemption(recipient, originalTokenId, id);
    }

    function physicalRedemption(bytes32[] calldata proof, bytes calldata data, uint256 originalTokenId, uint256 quantity) external payable {
        _redemptionPreCheck(data, originalTokenId);
        require(isPhysicalRedemption, "Airdrop: Non-Physical redemption.");
        _merkleProofVerify(proof, originalTokenId, quantity);
        getPayment(redemptionFee, fees.mintingFee);
        emit LogPhysicalRedemption(msg.sender, originalTokenId);
    }

    function sendFeedback(uint256 tokenId, bool result, bytes calldata data) external onlyOwner {
        require(redeemed[tokenId].submit, "Airdrop: This token id has not been submitted for redemption.");
        redeemed[tokenId].feedback = result;
        redeemed[tokenId].feedbackData = data;
    }

    function _redemptionPreCheck(bytes memory data, uint256 tokenId) internal {
        require(beginTime == 0 || block.timestamp >= beginTime, "Airdrop: Redemption not active.");
        require(endTime == 0 || block.timestamp <= endTime, "Airdrop: Redemption not active.");
        require(originalNFT.ownerOf(tokenId) == msg.sender, "Airdrop: Not original nft owner.");
        require(!redeemed[tokenId].submit, "Airdrop: This token id has been submitted for redemption.");
        redeemed[tokenId].submit = true;
        redeemed[tokenId].data = data;
        redeemed[tokenId].quantity += 1;
    }

    function _merkleProofVerify(bytes32[] calldata proof, uint256 originalTokenId, uint256 quantity) internal view {
        if (merkleRoot != bytes32(0)) {
            require(
                MerkleProof.verify(
                    proof,
                    merkleRoot,
                    keccak256(abi.encodePacked(address(originalNFT), originalTokenId, quantity))
                ),
                "Airdrop: Invalid merkle proof."
            );
            require(redeemed[originalTokenId].quantity <= quantity, "no allowance left");
        } else {
            require(redeemed[originalTokenId].quantity <= NON_WHITELISTED_MAX_PER_USER, "no allowance left");
        }
    }

    function _mintNFT(address recipient, uint256 _tokenId) internal returns (uint256 tokenId) {
        require(maxRedemption == 0 || maxRedemption > totalRedemptions, "Airdrop: No allowance left.");
        if (isSpecifyId) {
            tokenId = _tokenId;
            bonusNFT.mintWithId(recipient, _tokenId);
        } else {
            tokenId = bonusNFT.mint(recipient);
        }
        totalRedemptions += 1;
        emit LogNFTMint(recipient, tokenId);
    }

    function getPayment(uint256 amount, uint256 mintingFee) internal {
        if (address(paymentToken) == address(0)) { // ethereum
            require(msg.value == amount + mintingFee, "Airdrop: Not enough value.");
        } else {
            require(msg.value == mintingFee, "Airdrop: Not enough value.");
            paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        if (mintingFee > 0) {
            (bool success, ) = fees.vibeTreasury.call{value: mintingFee}(
                ""
            );
            require(success, "Airdrop: Revert treasury call.");
        }
    }

    function claimEarnings(address recipient) external onlyOwner {
        require(recipient != address(0), "Airdrop: Recipient cannot be 0.");
        uint256 total = paymentToken.balanceOf(address(this));
        uint256 fee = (total * uint256(fees.feeTake)) / BPS;
        paymentToken.safeTransfer(recipient, total - fee);
        paymentToken.safeTransfer(fees.vibeTreasury, fee);

        if (recipient.code.length > 0) {
            (bool success, bytes memory result) = recipient.call(
                abi.encodeWithSignature("supportsInterface(bytes4)", type(IDistributor).interfaceId)
            );

            if (success) {
                bool distribute = abi.decode(result, (bool));
                if (distribute) {
                    IDistributor(recipient).distribute(paymentToken, total - fee);
                }
            }
        }

        emit TokensClaimed(total, fee, recipient);
    }
}
