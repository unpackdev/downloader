// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract FeeSplitter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error CallFailed(address recipient);
    error NoBalance(IERC20 token);
    error InvalidLengths();

    address[] public recipients;
    uint16[] public shares;
    uint256 public totalShares;

    constructor(address _owner, address[] memory _recipients, uint16[] memory _shares) Ownable(_owner) {
        _setRecipients(_recipients, _shares);
    }

    function claim() public nonReentrant {
        uint256 length = shares.length;
        uint256 totalBalance = address(this).balance;

        bool success = false;

        for (uint256 i = 0; i < length;) {
            (success,) = recipients[i].call{value: (totalBalance * shares[i]) / totalShares}("");
            if (!success) {
                revert CallFailed(recipients[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function claimERC20(IERC20[] calldata _tokens) public nonReentrant {
        uint256 tokensLength = _tokens.length;
        uint256 sharesLength = shares.length;

        for (uint256 i = 0; i < tokensLength;) {
            uint256 totalBalance = _tokens[i].balanceOf(address(this));

            if (totalBalance == 0) {
                revert NoBalance(_tokens[i]);
            }

            for (uint256 j = 0; j < sharesLength;) {
                _tokens[i].safeTransfer(recipients[j], (totalBalance * shares[j]) / totalShares);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setRecipients(address[] calldata _recipients, uint16[] calldata _shares) external onlyOwner {
        _setRecipients(_recipients, _shares);
    }

    function _setRecipients(address[] memory _recipients, uint16[] memory _shares) internal {
        uint256 length = _shares.length;
        if (length != _recipients.length) {
            revert InvalidLengths();
        }

        recipients = _recipients;
        shares = _shares;

        totalShares = 0;
        for (uint256 i = 0; i < length;) {
            totalShares += _shares[i];
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}
}
