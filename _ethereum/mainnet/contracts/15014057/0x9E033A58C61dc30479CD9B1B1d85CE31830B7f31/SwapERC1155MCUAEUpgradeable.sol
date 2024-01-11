// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC1155PaymentSplitterMCUAEUpgradeable.sol";

contract SwapERC1155MCUAEUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    // Swap trusted signer address
    address private _trustedSignerAddress;

    // Swap whitelisted tokens
    struct TokenData {
        bool enable;
        uint256 ethPrice;
        uint256 ethAmount;
        uint256 totalSupply;
        uint256 totalSupplyLimit;
        uint256 perClaimLimit;
        address royaltyAddress;
    }
    mapping(address => mapping(uint256 => TokenData)) private _whitelistedTokens;

    // Claimed free tokens
    mapping(address => bool) private _claimedFreeTokens;

    // Emitted when `trustedSignerAddress` updated.
    event TrustedSignerAddressUpdated(address trustedSignerAddress);

    // Emitted when whitelisted token updated
    event WhitelistedTokenUpdated(address indexed tokenAddress, uint256 tokenId, bool enable, uint256 ethPrice, uint256 totalSupplyLimit, uint256 perClaimLimit, address royaltyAddress);

    // Emitted when tokens minted to an `account`
    event TokenMinted(address indexed account, address[] tokenAddresses, uint256[] tokenIds, uint256[] tokenAmounts, uint256 ethAmount);

    function initialize(address trustedSignerAddress_) public virtual initializer {
        __SwapERC1155MCUAE_init(trustedSignerAddress_);
    }

    function __SwapERC1155MCUAE_init(address trustedSignerAddress_) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __SwapERC1155MCUAE_init_init_unchained(trustedSignerAddress_);
    }

    function __SwapERC1155MCUAE_init_init_unchained(address trustedSignerAddress_) internal initializer {
        require(trustedSignerAddress_ != address(0), "SwapERC1155MCUAE: invalid trustedSignerAddress");
        _trustedSignerAddress = trustedSignerAddress_;
    }

    function trustedSignerAddress() external view virtual returns (address) {
        return _trustedSignerAddress;
    }

    function getWhitelistedTokenData(address tokenAddress_, uint256 tokenId_) external view virtual returns (
        bool enable,
        uint256 ethPrice,
        uint256 ethAmount,
        uint256 totalSupply,
        uint256 totalSupplyLimit,
        uint256 perClaimLimit,
        address royaltyAddress
    ) {
        TokenData storage tokenData = _whitelistedTokens[tokenAddress_][tokenId_];
        return (
            tokenData.enable,
            tokenData.ethPrice,
            tokenData.ethAmount,
            tokenData.totalSupply,
            tokenData.totalSupplyLimit,
            tokenData.perClaimLimit,
            tokenData.royaltyAddress
        );
    }

    function getWhitelistedTokenBatchData(address[] memory tokenAddresses_, uint256[] memory tokenIds_) external view virtual returns (
        bool[] memory enableList,
        uint256[] memory ethPriceList,
        uint256[] memory ethAmountList,
        uint256[] memory totalSupplyList,
        uint256[] memory totalSupplyLimitList,
        uint256[] memory perClaimLimitList,
        address[] memory royaltyAddressList
    ) {
        require(tokenAddresses_.length == tokenIds_.length, "SwapERC1155MCUAE: arrays length mismatch");
        enableList = new bool[](tokenAddresses_.length);
        ethPriceList = new uint256[](tokenAddresses_.length);
        ethAmountList = new uint256[](tokenAddresses_.length);
        totalSupplyList = new uint256[](tokenAddresses_.length);
        totalSupplyLimitList = new uint256[](tokenAddresses_.length);
        perClaimLimitList = new uint256[](tokenAddresses_.length);
        royaltyAddressList = new address[](tokenAddresses_.length);
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            TokenData storage tokenData = _whitelistedTokens[tokenAddresses_[i]][tokenIds_[i]];
            enableList[i] = tokenData.enable;
            ethPriceList[i] = tokenData.ethPrice;
            ethAmountList[i] = tokenData.ethAmount;
            totalSupplyList[i] = tokenData.totalSupply;
            totalSupplyLimitList[i] = tokenData.totalSupplyLimit;
            perClaimLimitList[i] = tokenData.perClaimLimit;
            royaltyAddressList[i] = tokenData.royaltyAddress;
        }
        return (
            enableList,
            ethPriceList,
            ethAmountList,
            totalSupplyList,
            totalSupplyLimitList,
            perClaimLimitList,
            royaltyAddressList
        );
    }

    function addressClaimFreeToken(address address_) external view virtual returns (bool) {
        return _claimedFreeTokens[address_];
    }

    function checkBeforeClaimBatch(
        address[] memory tokenAddresses_,
        uint256[] memory tokenIds_,
        uint256[] memory tokenAmounts_
    ) external view virtual returns (bool[] memory batchCheckResult) {
        require(tokenAddresses_.length == tokenIds_.length && tokenAddresses_.length == tokenAmounts_.length, "SwapERC1155MCUAE: arrays length mismatch");
        require(!paused(), "SwapERC1155MCUAE: contract is paused");
        batchCheckResult = new bool[](tokenAddresses_.length);
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            batchCheckResult[i] = _checkBeforeMint(tokenAddresses_[i], tokenIds_[i], tokenAmounts_[i]);
        }
        return batchCheckResult;
    }

    function claimBatch(
        address[] memory tokenAddresses_,
        uint256[] memory tokenIds_,
        uint256[] memory tokenAmounts_,
        uint256 ethAmount_,
        bool isFreeClaim_,
        uint256 nonce_,
        uint256 salt_,
        uint256 maxBlockNumber_,
        bytes memory signature_
    ) external virtual payable nonReentrant whenNotPaused {
        // basic checks
        require(tokenAddresses_.length == tokenIds_.length && tokenAddresses_.length == tokenAmounts_.length, "SwapERC1155MCUAE: arrays length mismatch");
        require(block.number <= maxBlockNumber_, "SwapERC1155MCUAE: failed max block check");
        // check signature
        bytes32 hash = keccak256(abi.encodePacked(_msgSender(), tokenAddresses_, tokenIds_, tokenAmounts_, ethAmount_, isFreeClaim_, nonce_, salt_, maxBlockNumber_));
        address signer = hash.toEthSignedMessageHash().recover(signature_);
        require(signer == _trustedSignerAddress, "SwapERC1155MCUAE: invalid signature");
        if (isFreeClaim_) {
            require(!_claimedFreeTokens[_msgSender()], "SwapERC1155MCUAE: free tokens already received");
            _claimedFreeTokens[_msgSender()] = true;
        }
        // mint tokens
        uint256 checkEthAmount;
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            checkEthAmount += _mint(_msgSender(), tokenAddresses_[i], tokenIds_[i], tokenAmounts_[i], isFreeClaim_);
        }
        // check eth amount
        require(checkEthAmount == msg.value && checkEthAmount == ethAmount_, "SwapERC1155MCUAE: invalid ETH amount");
        // emit event
        emit TokenMinted(_msgSender(), tokenAddresses_, tokenIds_, tokenAmounts_, checkEthAmount);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateTrustedSignerAddress(address trustedSignerAddress_) external virtual onlyOwner {
        require(trustedSignerAddress_ != address(0), "SwapERC1155MCUAE: invalid trustedSignerAddress");
        _trustedSignerAddress = trustedSignerAddress_;
        emit TrustedSignerAddressUpdated(trustedSignerAddress_);
    }

    function updateWhitelistedTokenData(
        address tokenAddress_,
        uint256 tokenId_,
        bool enable_,
        uint256 ethPrice_,
        uint256 totalSupplyLimit_,
        uint256 perClaimLimit_,
        address royaltyAddress_
    ) external virtual onlyOwner {
        require(tokenAddress_ != address(0), "SwapERC1155MCUAE: invalid tokenAddress");
        require(tokenId_ != 0, "SwapERC1155MCUAE: invalid tokenId");
        require(perClaimLimit_ != 0, "SwapERC1155MCUAE: invalid perClaimLimit");
        require(royaltyAddress_ != address(0), "SwapERC1155MCUAE: invalid royaltyAddress");
        TokenData storage tokenData = _whitelistedTokens[tokenAddress_][tokenId_];
        require(totalSupplyLimit_ == 0 || tokenData.totalSupply <= totalSupplyLimit_, "SwapERC1155MCUAE: invalid totalSupplyLimit");
        tokenData.enable = enable_;
        tokenData.ethPrice = ethPrice_;
        tokenData.totalSupplyLimit = totalSupplyLimit_;
        tokenData.perClaimLimit = perClaimLimit_;
        tokenData.royaltyAddress = royaltyAddress_;
        emit WhitelistedTokenUpdated(tokenAddress_, tokenId_, enable_, ethPrice_, totalSupplyLimit_, perClaimLimit_, royaltyAddress_);
    }

    function mintBatch(
        address recipient_,
        address[] memory tokenAddresses_,
        uint256[] memory tokenIds_,
        uint256[] memory tokenAmounts_
    ) external virtual whenNotPaused onlyOwner {
        // basic checks
        require(recipient_ != address(0), "SwapERC1155MCUAE: invalid recipient");
        require(tokenAddresses_.length == tokenIds_.length && tokenAddresses_.length == tokenAmounts_.length, "SwapERC1155MCUAE: arrays length mismatch");
        // mint tokens
        uint256 checkEthAmount;
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            checkEthAmount += _mint(recipient_, tokenAddresses_[i], tokenIds_[i], tokenAmounts_[i], true);
        }
        // check eth amount
        require(checkEthAmount == 0, "SwapERC1155MCUAE: invalid ETH amount");
        // emit event
        emit TokenMinted(recipient_, tokenAddresses_, tokenIds_, tokenAmounts_, checkEthAmount);
    }

    function _checkBeforeMint(
        address tokenAddress_,
        uint256 tokenId_,
        uint256 tokenAmount_
    ) internal view virtual returns (bool checkResult) {
        TokenData storage tokenData = _whitelistedTokens[tokenAddress_][tokenId_];
        checkResult = !IERC1155PaymentSplitterMCUAEUpgradeable(tokenAddress_).paused()
            && IERC1155PaymentSplitterMCUAEUpgradeable(tokenAddress_).isTrustedMinter(address(this))
            && tokenData.enable
            && tokenAmount_ > 0 && tokenAmount_ <= tokenData.perClaimLimit
            && (tokenData.totalSupplyLimit == 0 || (tokenData.totalSupply + tokenAmount_) <= tokenData.totalSupplyLimit);
        return checkResult;
    }

    function _mint(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_,
        uint256 tokenAmount_,
        bool isFreeClaim_
    ) internal virtual returns (uint256 ethAmount) {
        require(_checkBeforeMint(tokenAddress_, tokenId_, tokenAmount_), "SwapERC1155MCUAE: failed before mint check");
        TokenData storage tokenData = _whitelistedTokens[tokenAddress_][tokenId_];
        ethAmount = isFreeClaim_ ? 0 : tokenData.ethPrice * tokenAmount_;
        tokenData.totalSupply += tokenAmount_;
        tokenData.ethAmount += ethAmount;
        require(tokenData.totalSupplyLimit == 0 || tokenData.totalSupply <= tokenData.totalSupplyLimit, "SwapERC1155MCUAE: total supply limit reached");
        IERC1155PaymentSplitterMCUAEUpgradeable(tokenAddress_).mint(recipient_, tokenId_, tokenAmount_, "");
        if (ethAmount != 0 && tokenData.royaltyAddress != address(0)) {
            AddressUpgradeable.sendValue(payable(tokenData.royaltyAddress), ethAmount);
        }
        return ethAmount;
    }
}
