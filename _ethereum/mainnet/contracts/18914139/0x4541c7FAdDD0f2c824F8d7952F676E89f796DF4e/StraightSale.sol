// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "Ownable.sol";
import {SafeERC20, IERC20} from "SafeERC20.sol";
import "Upgradeable.sol";

error PleaseSendETH();
error Unauthorized();
error CountMismatch();
error BelowZero();
error InsufficientTokens();
error EthTransferFailed();
error SaleAlreadyOpened();
error SaleAlreadyClosed();
error InvalidPrice();
error PurchaseTooMuch();

contract StraightSale is Upgradeable {

    event WhitelistOpened(uint256 timestamp);
    event WhitelistClosed(uint256 timestamp);
    event PurchaseToken(address indexed who, uint256 ethAmount, uint256 tokenAmount);
    event WalletCapUpdated(uint256 ethAmount);

    bool private _initialized;

    IERC20 public immutable fungToken;

    uint256 public ethPricePerFung;

    address public beneficiary;

    uint256 public totalCommitments;

    bool public whitelistEnabled;
    mapping(address user => uint256 allocationWhitelist) public whitelist;

    uint256 public perWalletCap;

    mapping(address user => uint256 amountCommitted) public commitments;

    constructor(IERC20 _fungToken) {
        fungToken = _fungToken;
    }

    // takes into account whitelist allocation, max cap during public sale, and available inventory
    function maxPurchasePossible(address user) external view returns (uint256) {
        uint256 maxAllowed = maxPurchaseAllowed(user);

        uint256 tokenAmountAllowed = maxAllowed * 1e18 / ethPricePerFung;
        if (fungToken.balanceOf(address(this)) < tokenAmountAllowed) {
            maxAllowed = maxAllowed * fungToken.balanceOf(address(this)) / tokenAmountAllowed;
        }

        return maxAllowed;
    }

    // takes into account whitelist allocation and max cap during public sale
    function maxPurchaseAllowed(address user) public view returns (uint256 maxAllowed) {
        
        // can always purchase at least up to whitelisted amount from available inventory
        uint256 whitelistAllo = whitelist[user];

        if (whitelistEnabled) {
            maxAllowed = whitelistAllo;
        } else {
            uint256 walletCap = perWalletCap;
            uint256 committed  = commitments[user];

            if (committed < walletCap) {
                walletCap = walletCap - committed;
            } else {
                walletCap = 0;
            }

            if (whitelistAllo >= walletCap) {
                maxAllowed = whitelistAllo;
            } else {
                maxAllowed = walletCap;
            }
        }
    }
        
    function purchaseToken() external payable {
        if (msg.value == 0) {
            revert PleaseSendETH();
        }

        if (maxPurchaseAllowed(msg.sender) < msg.value) {
            revert PurchaseTooMuch();
        }

        if (whitelist[msg.sender] > msg.value) {
            whitelist[msg.sender] = whitelist[msg.sender] - msg.value;
        } else {
            whitelist[msg.sender] = 0;
        }
        commitments[msg.sender] = commitments[msg.sender] + msg.value;
        totalCommitments = totalCommitments + msg.value;

        uint256 tokenAmount = msg.value * 1e18 / ethPricePerFung;
        if (fungToken.balanceOf(address(this)) < tokenAmount) {
            revert InsufficientTokens();
        }

        fungToken.transfer(msg.sender, tokenAmount);

        _sendETH(beneficiary, msg.value);

        emit PurchaseToken(msg.sender, msg.value, tokenAmount);
    }

    function initialize(address _beneficiary, uint256 _ethPricePerFung) external onlyOwner {
        if (_initialized == true) {
            revert Unauthorized();
        }

        whitelistEnabled = true;

        _updateSettings(_beneficiary, _ethPricePerFung);

        _initialized = true;
    }

    function _updateSettings(address _beneficiary, uint256 _ethPricePerFung) public onlyOwner {
        if (_ethPricePerFung == 0) {
            revert InvalidPrice();
        }
        
        if (_beneficiary == address(0)) {
            beneficiary = address(this);
        } else {
            beneficiary = _beneficiary;
        }
        ethPricePerFung = _ethPricePerFung;
    }

    function setPerWalletCap(uint256 _value) external onlyOwner {
        perWalletCap = _value;
        emit WalletCapUpdated(_value);
    }

    // whitelistEnabled == true -> public sale is closed
    // whitelistEnabled == false -> public sale is open
    function toggleWhitelistEnabled(bool isEnabled) external onlyOwner {
        bool _enabled = whitelistEnabled;
        if (isEnabled == true && _enabled == true) {
            revert SaleAlreadyClosed();
        }
        if (isEnabled == false && _enabled == false) {
            revert SaleAlreadyOpened();
        }
        
        whitelistEnabled = isEnabled;
        if (isEnabled) {
            emit WhitelistOpened(block.timestamp);
        } else {
            emit WhitelistClosed(block.timestamp);
        }
    }
    function increaseWhitelist(address[] memory users, uint256[] memory addedAmounts) external onlyOwner {
        if (users.length != addedAmounts.length) {
            revert CountMismatch();
        }
        for(uint i; i < users.length;) {
            whitelist[users[i]] = whitelist[users[i]] + addedAmounts[i];
            unchecked { i++; }
        }
    }
    function decreaseWhitelist(address[] memory users, uint256[] memory subtractedAmounts) external onlyOwner {
        if (users.length != subtractedAmounts.length) {
            revert CountMismatch();
        }
        for(uint i; i < users.length;) {
            uint256 whitelistRemaining = whitelist[users[i]];
            if (whitelistRemaining < subtractedAmounts[i]) {
                revert BelowZero();
            }
            unchecked {
                whitelist[users[i]] = whitelistRemaining - subtractedAmounts[i];
                i++;
            }
        }
    }

    function rescue(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }
    function rescueETH() external onlyOwner {
        _sendETH(msg.sender, address(this).balance);
    }
    function _sendETH(address _to, uint256 _amount) private {
        if (_to == address(this))
            return;

        (bool success, ) = _to.call{ value: _amount }("");
        if (success == false) {
            revert EthTransferFailed();
        }
    }
}
