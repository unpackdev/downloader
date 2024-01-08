// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";

contract SwapERC1155UAE is Ownable, Pausable, ReentrancyGuard, ERC1155Holder {
    // Swap params
    uint256 private constant _TOKENS_PER_RECIPIENT = 1;
    bool private _batchReception;
    bool private _unlimitedReception;
    uint256 private _releaseTime;

    // Mapping for accounting white token contract addresses
    mapping(address => bool) private _whitelistedTokens;

    // Mapping from recipient address to received tokens from contract address
    mapping(address => mapping(address => uint256)) private _receivedTokens;

    // Emitted when `tokenAddress` added to whitelist.
    event AddToTokenWhitelist(address tokenAddress);
    // Emitted when `tokenAddress` removed from whitelist.
    event RemoveFromTokenWhitelist(address tokenAddress);

    // Emitted when batch reception updated
    event BatchReceptionUpdated(bool batchReception);

    // Emitted when unlimited reception updated
    event UnlimitedReceptionUpdated(bool unlimitedReception);

    // Emitted when `account` receive `amount` of type `tokenId` from contract `tokenAddress`.
    event TokenReceived(address indexed account, address tokenAddress, uint256 tokenId, uint256 amount);
    // Emitted when owner `account` withdraw `amount` of type `tokenId` from contract `tokenAddress`.
    event TokenWithdrawn(address indexed account, address tokenAddress, uint256 tokenId, uint256 amount);

    constructor(uint256 releaseTime_) {
        _batchReception = false;
        _unlimitedReception = false;
        _releaseTime = releaseTime_;
    }

    function isWhiteListedToken(address tokenAddress_) external view virtual returns (bool) {
        return _whitelistedTokens[tokenAddress_];
    }

    function isWhiteListedTokenBatch(address[] memory tokenAddresses_) external view virtual returns (bool[] memory) {
        bool[] memory batchWhiteListedTokens = new bool[](tokenAddresses_.length);
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            batchWhiteListedTokens[i] = _whitelistedTokens[tokenAddresses_[i]];
        }
        return batchWhiteListedTokens;
    }

    function batchReceptionAllowed() external view virtual returns (bool) {
        return _batchReception;
    }

    function unlimitedReceptionAllowed() external view virtual returns (bool) {
        return _unlimitedReception;
    }

    function tokenBalance(address tokenAddress_, uint256 tokenId_) public view virtual returns (uint256 balance) {
        if (tokenAddress_ != address(0)) {
            balance = IERC1155(tokenAddress_).balanceOf(address(this), tokenId_);
        }
        return balance;
    }

    function tokenBalanceBatch(address[] memory tokenAddresses_, uint256[] memory tokenIds_)
        public
        view
        virtual
        returns (uint256[] memory batchBalances)
    {
        require(tokenAddresses_.length == tokenIds_.length, "SwapERC1155UAE: arrays length mismatch");
        batchBalances = new uint256[](tokenAddresses_.length);
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            if (tokenAddresses_[i] != address(0)) {
                batchBalances[i] = IERC1155(tokenAddresses_[i]).balanceOf(address(this), tokenIds_[i]);
            }
        }
        return batchBalances;
    }

    function releaseTime() external view virtual returns (uint256) {
        return _releaseTime;
    }

    function checkBeforeClaimToken(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_
    ) external view virtual returns (bool)
    {
        bool releaseCheck = _releaseTime <= block.timestamp;
        bool balanceCheck = tokenBalance(tokenAddress_, tokenId_) > 0;
        bool recipientCheck = _unlimitedReception || _receivedTokens[recipient_][tokenAddress_] == 0;
        return !paused() && releaseCheck && _whitelistedTokens[tokenAddress_] && balanceCheck && recipientCheck;
    }

    function checkBeforeClaimTokenBatch(
        address recipient_,
        address[] memory tokenAddresses_,
        uint256[] memory tokenIds_
    ) external view virtual returns (bool[] memory)
    {
        require(tokenAddresses_.length == tokenIds_.length, "SwapERC1155UAE: arrays length mismatch");
        bool releaseCheck = _releaseTime <= block.timestamp;
        bool[] memory batchCheckBeforeClaim = new bool[](tokenAddresses_.length);
        uint256[] memory batchBalances = tokenBalanceBatch(tokenAddresses_, tokenIds_);
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            bool balanceCheck = batchBalances[i] > 0;
            bool recipientCheck = _unlimitedReception || _receivedTokens[recipient_][tokenAddresses_[i]] == 0;
            batchCheckBeforeClaim[i] = !paused() && releaseCheck && _batchReception && _whitelistedTokens[tokenAddresses_[i]] && balanceCheck && recipientCheck;
        }
        return batchCheckBeforeClaim;
    }

    function claimToken(
        address tokenAddress_,
        uint256 tokenId_,
        bytes calldata data_
    )
        external
        virtual
        nonReentrant
        whenNotPaused
    {
        require(_releaseTime <= block.timestamp, "SwapERC1155UAE: release time has not come");
        _claim(_msgSender(), tokenAddress_, tokenId_, data_);
    }

    function claimTokenBatch(
        address[] memory tokenAddresses_,
        uint256[] memory tokenIds_,
        bytes calldata data_
    )
        external
        virtual
        nonReentrant
        whenNotPaused
    {
        require(_batchReception, "SwapERC1155UAE: batch reception is not allowed");
        require(tokenAddresses_.length == tokenIds_.length, "SwapERC1155UAE: arrays length mismatch");
        require(_releaseTime <= block.timestamp, "SwapERC1155UAE: release time has not come");
        for (uint256 i = 0; i < tokenAddresses_.length; ++i) {
            _claim(_msgSender(), tokenAddresses_[i], tokenIds_[i], data_);
        }
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function addToTokenWhitelist(address tokenAddress_) external virtual onlyOwner {
        require(tokenAddress_ != address(0), "SwapERC1155UAE: invalid tokenAddress");
        _whitelistedTokens[tokenAddress_] = true;
        emit AddToTokenWhitelist(tokenAddress_);
    }

    function removeFromTokenWhitelist(address tokenAddress_) external virtual onlyOwner {
        require(tokenAddress_ != address(0), "SwapERC1155UAE: invalid tokenAddress");
        _whitelistedTokens[tokenAddress_] = false;
        emit RemoveFromTokenWhitelist(tokenAddress_);
    }

    function updateBatchReception(bool batchReception_) external virtual onlyOwner {
        _batchReception = batchReception_;
        emit BatchReceptionUpdated(batchReception_);
    }

    function updateUnlimitedReception(bool unlimitedReception_) external virtual onlyOwner {
        _unlimitedReception = unlimitedReception_;
        emit UnlimitedReceptionUpdated(unlimitedReception_);
    }

    function withdrawToken(
        address tokenAddress_,
        uint256 tokenId_,
        uint256 amount_,
        bytes calldata data_
    )
        external
        virtual
        onlyOwner
        nonReentrant
    {
        _withdraw(_msgSender(), tokenAddress_, tokenId_, amount_, data_);
    }

    function _claim(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_,
        bytes calldata data_
    ) internal virtual {
        require(_whitelistedTokens[tokenAddress_], "SwapERC1155UAE: tokenAddress is not whitelisted");
        require(_unlimitedReception || _receivedTokens[recipient_][tokenAddress_] == 0, "SwapERC1155UAE: recipient has already received token");

        _receivedTokens[recipient_][tokenAddress_] += _TOKENS_PER_RECIPIENT;
        IERC1155(tokenAddress_).safeTransferFrom(address(this), recipient_, tokenId_, _TOKENS_PER_RECIPIENT, data_);

        emit TokenReceived(recipient_, tokenAddress_, tokenId_, _TOKENS_PER_RECIPIENT);
    }

    function _withdraw(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_,
        uint256 amount_,
        bytes calldata data_
    ) internal virtual {
        require(tokenAddress_ != address(0), "SwapERC1155UAE: invalid tokenAddress");

        IERC1155(tokenAddress_).safeTransferFrom(address(this), recipient_, tokenId_, amount_, data_);

        emit TokenWithdrawn(recipient_, tokenAddress_, tokenId_, amount_);
    }
}
