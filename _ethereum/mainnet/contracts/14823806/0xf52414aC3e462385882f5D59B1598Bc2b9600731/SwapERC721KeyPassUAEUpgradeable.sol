// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC721KeyPassUAEUpgradeable.sol";

contract SwapERC721KeyPassUAEUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // Swap key pass contract address
    address private _erc721KeyPassAddress;
    // Swap trusted signer address
    address private _trustedSignerAddress;

    // Swap plan parameters
    struct PlanData {
        uint256 tokenAmount;
        uint256 tokenAmountLimit;
        uint256 tokenPrice;
        uint256 tokenPerClaimLimit;
        uint256 ethAmount;
    }
    PlanData private _freePlan;
    PlanData private _paidPlan;

    // Swap stage parameters
    struct StageData {
        bool mintingEnabled;
        bool whitelistRequired;
        bool firstClaimFree;
        uint256 ethAmount;
        uint256 totalClaimedFreeTokens;
        uint256 totalClaimedPaidTokens;
    }
    mapping(uint256 => StageData) private _stages;
    uint256 private _currentStageId;

    // Mapping from recipient address to claimed free tokens
    mapping(address => uint256) private _claimedFreeTokens;
    // Mapping from recipient address to claimed paid tokens
    mapping(address => uint256) private _claimedPaidTokens;

    // Emitted when `trustedSignerAddress` updated.
    event TrustedSignerAddressUpdated(address trustedSignerAddress);

    // Emitted when new Stage updated.
    event StageUpdated(uint256 stageId, bool mintingEnabled, bool whitelistRequired, bool firstMintFree);
    // Emitted when current stageId updated.
    event CurrentStageUpdated(uint256 stageId);
    // Emitted when plan config updated
    event PlanConfigUpdated(uint256 freeTokenAmountLimit, uint256 paidTokenAmountLimit, uint256 paidTokenPrice);

    // Emitted when `account` receive key pass tokens
    event TokenClaimed(uint256 stageId, address indexed account, uint256 tokenAmount, uint256 ethAmount);

    // Emitted when `ethAmount` ETH withdrawal to `account`
    event EthWithdrawal(address account, uint256 ethAmount);

    function initialize(
        address erc721KeyPassAddress_,
        address trustedSignerAddress_,
        uint256 freeTokenAmountLimit_,
        uint256 paidTokenAmountLimit_,
        uint256 paidTokenPrice_
    ) public virtual initializer {
        __SwapERC721KeyPassUAE_init(
            erc721KeyPassAddress_,
            trustedSignerAddress_,
            freeTokenAmountLimit_,
            paidTokenAmountLimit_,
            paidTokenPrice_
        );
    }

    function __SwapERC721KeyPassUAE_init(
        address erc721KeyPassAddress_,
        address trustedSignerAddress_,
        uint256 freeTokenAmountLimit_,
        uint256 paidTokenAmountLimit_,
        uint256 paidTokenPrice_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC721KeyPassUAE_init_unchained(
            erc721KeyPassAddress_,
            trustedSignerAddress_,
            freeTokenAmountLimit_,
            paidTokenAmountLimit_,
            paidTokenPrice_
        );
    }

    function __SwapERC721KeyPassUAE_init_unchained(
        address erc721KeyPassAddress_,
        address trustedSignerAddress_,
        uint256 freeTokenAmountLimit_,
        uint256 paidTokenAmountLimit_,
        uint256 paidTokenPrice_
    ) internal initializer {
        require(erc721KeyPassAddress_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        require(trustedSignerAddress_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        require(freeTokenAmountLimit_ != 0, "SwapERC721KeyPassUAE: invalid token amount limit");
        require(paidTokenAmountLimit_ != 0, "SwapERC721KeyPassUAE: invalid token amount limit");
        require(paidTokenPrice_ != 0, "SwapERC721KeyPassUAE: invalid token price");

        _erc721KeyPassAddress = erc721KeyPassAddress_;
        _trustedSignerAddress = trustedSignerAddress_;

        _freePlan = PlanData(0, freeTokenAmountLimit_, 0, 0, 0);
        _paidPlan = PlanData(0, paidTokenAmountLimit_, paidTokenPrice_, 1, 0);
    }

    function erc721KeyPassAddress() external view virtual returns (address) {
        return _erc721KeyPassAddress;
    }

    function trustedSignerAddress() external view virtual returns (address) {
        return _trustedSignerAddress;
    }

    function freePlanInfo() external view virtual returns (
        uint256 tokenAmount,
        uint256 tokenAmountLimit,
        uint256 tokenPrice,
        uint256 tokenPerClaimLimit,
        uint256 ethAmount
    ) {
        return (
            _freePlan.tokenAmount,
            _freePlan.tokenAmountLimit,
            _freePlan.tokenPrice,
            _freePlan.tokenPerClaimLimit,
            _freePlan.ethAmount
        );
    }

    function paidPlanInfo() external view virtual returns (
        uint256 tokenAmount,
        uint256 tokenAmountLimit,
        uint256 tokenPrice,
        uint256 tokenPerClaimLimit,
        uint256 ethAmount
    ) {
        return (
            _paidPlan.tokenAmount,
            _paidPlan.tokenAmountLimit,
            _paidPlan.tokenPrice,
            _paidPlan.tokenPerClaimLimit,
            _paidPlan.ethAmount
        );
    }

    function currentStageId() external view virtual returns (uint256) {
        return _currentStageId;
    }

    function getStageInfo(uint256 stageId_)
        external
        view
        virtual
        returns (
            bool mintingEnabled,
            bool whitelistRequired,
            bool firstClaimFree,
            uint256 ethAmount,
            uint256 totalClaimedFreeTokens,
            uint256 totalClaimedPaidTokens
        )
    {
        StageData storage stage = _stages[stageId_];
        return (
            stage.mintingEnabled,
            stage.whitelistRequired,
            stage.firstClaimFree,
            stage.ethAmount,
            stage.totalClaimedFreeTokens,
            stage.totalClaimedPaidTokens
        );
    }

    function getAddressClaimInfo(address address_) external view virtual returns (uint256 freeTokens, uint256 paidTokens) {
        return (
            _claimedFreeTokens[address_],
            _claimedPaidTokens[address_]
        );
    }

    function checkBeforeClaim(address address_, bool isWhitelisted_) public view virtual returns (bool shouldBeFreeClaim, uint256 tokenPerClaimLimit, uint256 tokenPrice) {
        require(address_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        require(!paused(), "SwapERC721KeyPassUAE: contract is paused");
        require(!IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).paused(), "SwapERC721KeyPassUAE: erc721 is paused");
        require(IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).isTrustedMinter(address(this)), "SwapERC721KeyPassUAE: erc721 wrong trusted minter");
        StageData storage stage = _stages[_currentStageId];
        require(stage.mintingEnabled, "SwapERC721KeyPassUAE: stage minting disabled");
        require(!stage.whitelistRequired || (stage.whitelistRequired && isWhitelisted_), "SwapERC721KeyPassUAE: address is not whitelisted");
        shouldBeFreeClaim = stage.firstClaimFree && _claimedFreeTokens[address_] == 0;
        if (shouldBeFreeClaim) {
            tokenPerClaimLimit = _freePlan.tokenPerClaimLimit;
            tokenPrice = _freePlan.tokenPrice;
        } else {
            tokenPerClaimLimit = _paidPlan.tokenPerClaimLimit;
            tokenPrice = _paidPlan.tokenPrice;
        }
        return (
            shouldBeFreeClaim,
            tokenPerClaimLimit,
            tokenPrice
        );
    }

    function claimToken(
        bool isWhitelisted_,
        bool isFreeClaim_,
        uint256 ethAmount_,
        uint256 tokenAmount_,
        uint256 nonce_,
        uint256 salt_,
        uint256 maxBlockNumber_,
        bytes memory signature_
    ) external virtual payable nonReentrant whenNotPaused {
        // check signature
        bytes32 hash = keccak256(abi.encodePacked(_msgSender(), isWhitelisted_, isFreeClaim_, ethAmount_, tokenAmount_, nonce_, salt_, maxBlockNumber_));
        address signer = hash.toEthSignedMessageHash().recover(signature_);
        require(signer == _trustedSignerAddress, "SwapERC721KeyPassUAE: invalid signature");
        // check max block limit
        require(block.number <= maxBlockNumber_, "SwapERC721KeyPassUAE: failed max block check");
        (bool shouldBeFreeClaim, uint256 tokenPerClaimLimit, uint256 tokenPrice) = checkBeforeClaim(_msgSender(), isWhitelisted_);
        // check
        require(shouldBeFreeClaim == isFreeClaim_, "SwapERC721KeyPassUAE: invalid isFreeClaim flag");
        require((tokenPerClaimLimit == 0) || (tokenPerClaimLimit == tokenAmount_), "SwapERC721KeyPassUAE: invalid token amount");
        require(ethAmount_ == tokenAmount_ * tokenPrice, "SwapERC721KeyPassUAE: invalid ETH amount");
        // claim tokens
        if (isFreeClaim_) {
            _freePlanClaim(_msgSender(), tokenAmount_, ethAmount_);
        } else {
            _paidPlanClaim(_msgSender(), tokenAmount_, ethAmount_);
        }
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateTrustedSignerAddress(address trustedSignerAddress_) external virtual onlyOwner {
        require(trustedSignerAddress_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        _trustedSignerAddress = trustedSignerAddress_;
        emit TrustedSignerAddressUpdated(trustedSignerAddress_);
    }

    function updateCurrentStageId(uint256 stageId_) external virtual onlyOwner {
        _currentStageId = stageId_;
        emit CurrentStageUpdated(stageId_);
    }

    function updatePlanConfig(
        uint256 freeTokenAmountLimit_,
        uint256 paidTokenAmountLimit_,
        uint256 paidTokenPrice_
    ) external virtual onlyOwner {
        require(freeTokenAmountLimit_ != 0 && _freePlan.tokenAmount <= freeTokenAmountLimit_, "SwapERC721KeyPassUAE: invalid token amount limit");
        require(paidTokenAmountLimit_ != 0 && _paidPlan.tokenAmount <= paidTokenAmountLimit_, "SwapERC721KeyPassUAE: invalid token amount limit");
        require(paidTokenPrice_ != 0, "SwapERC721KeyPassUAE: invalid token price");
        _freePlan.tokenAmountLimit = freeTokenAmountLimit_;
        _paidPlan.tokenAmountLimit = paidTokenAmountLimit_;
        _paidPlan.tokenPrice = paidTokenPrice_;
        emit PlanConfigUpdated(freeTokenAmountLimit_, paidTokenAmountLimit_, paidTokenPrice_);
    }

    function updateStage(uint256 stageId_, bool mintingEnabled_, bool whitelistRequired_, bool firstMintFree_) external virtual onlyOwner {
        require(stageId_ != 0, "SwapERC721KeyPassUAE: invalid stageId");
        StageData storage stage = _stages[stageId_];
        stage.mintingEnabled = mintingEnabled_;
        stage.whitelistRequired = whitelistRequired_;
        stage.firstClaimFree = firstMintFree_;
        emit StageUpdated(stageId_, mintingEnabled_, whitelistRequired_, firstMintFree_);
    }

    function ethWithdrawal(address payable recipient_) external virtual onlyOwner {
        require(recipient_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        uint256 ethAmount = address(this).balance;
        AddressUpgradeable.sendValue(recipient_, ethAmount);
        emit EthWithdrawal(recipient_, ethAmount);
    }

    function _freePlanClaim(address recipient_, uint256 tokenAmount_, uint256 ethAmount_) internal virtual {
        // pre claim check
        require(recipient_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        require(tokenAmount_ != 0, "SwapERC721KeyPassUAE: invalid token amount");
        require((ethAmount_ == 0) && (ethAmount_ == msg.value), "SwapERC721KeyPassUAE: invalid ETH amount");
        require((_freePlan.tokenAmount + tokenAmount_) <= _freePlan.tokenAmountLimit, "SwapERC721KeyPassUAE: total amount limit reached");
        StageData storage stage = _stages[_currentStageId];
        require(stage.mintingEnabled, "SwapERC721KeyPassUAE: stage minting disabled");
        // update claimedFreeTokens for recipient
        _claimedFreeTokens[recipient_] += tokenAmount_;
        // update freePlan params
        _freePlan.tokenAmount += tokenAmount_;
        // update stage params
        stage.totalClaimedFreeTokens += tokenAmount_;
        // mint token batch
        IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).mintTokenBatch(recipient_, tokenAmount_);
        // emit event
        emit TokenClaimed(_currentStageId, recipient_, tokenAmount_, ethAmount_);
    }

    function _paidPlanClaim(address recipient_, uint256 tokenAmount_, uint256 ethAmount_) internal virtual {
        // pre claim check
        require(recipient_ != address(0), "SwapERC721KeyPassUAE: invalid address");
        require(tokenAmount_ != 0, "SwapERC721KeyPassUAE: invalid token amount");
        require((ethAmount_ > 0) && (ethAmount_ == msg.value), "SwapERC721KeyPassUAE: invalid ETH amount");
        require((_paidPlan.tokenAmount + tokenAmount_) <= _paidPlan.tokenAmountLimit, "SwapERC721KeyPassUAE: total amount limit reached");
        StageData storage stage = _stages[_currentStageId];
        require(stage.mintingEnabled, "SwapERC721KeyPassUAE: stage minting disabled");
        // update _claimedPaidTokens for recipient
        _claimedPaidTokens[recipient_] += tokenAmount_;
        // update paidPlan params
        _paidPlan.ethAmount += ethAmount_;
        _paidPlan.tokenAmount += tokenAmount_;
        // update stage params
        stage.ethAmount += ethAmount_;
        stage.totalClaimedPaidTokens += tokenAmount_;
        // mint token batch
        IERC721KeyPassUAEUpgradeable(_erc721KeyPassAddress).mintTokenBatch(recipient_, tokenAmount_);
        // emit event
        emit TokenClaimed(_currentStageId, recipient_, tokenAmount_, ethAmount_);
    }
}
