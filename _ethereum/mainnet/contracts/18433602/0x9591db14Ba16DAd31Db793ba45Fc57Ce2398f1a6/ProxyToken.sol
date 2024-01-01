// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./IProxyToken.sol";
import "./IProxyableToken.sol";

contract ProxyToken is IProxyToken {
    using SafeERC20 for IERC20;

    error RebalanceFlagNotSet();
    error Forbidden();
    error InvalidToken();

    address public token;
    address public owner;
    bool public rebalanceFlag;

    constructor(address owner_) {
        owner = owner_;
    }

    function setRebalanceFlag(bool value) external {
        if (msg.sender != owner) {
            revert Forbidden();
        }
        rebalanceFlag = value;
    }

    function upgradeTo(address newToken) external {
        if (!rebalanceFlag && msg.sender != owner) {
            revert RebalanceFlagNotSet();
        }
        if (token == address(0)) {
            token = newToken;
        } else {
            try IProxyableToken(token).isSameKind(newToken) returns (bool isSameKind) {
                if (isSameKind) {
                    token = newToken;
                    return;
                }
            } catch {}
            revert InvalidToken();
        }
    }

    function transferOwnership(address newAdmin) external {
        if (msg.sender != owner) {
            revert Forbidden();
        }
        owner = newAdmin;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return type(IProxyToken).interfaceId == interfaceId;
    }

    function deposit(uint256[] memory tokenAmounts, uint256 minLpAmount) external returns (uint256) {
        return IProxyableToken(token).deposit(msg.sender, tokenAmounts, minLpAmount);
    }

    function withdraw(uint256 lpAmount, uint256[] memory minAmounts) external returns (uint256[] memory) {
        return IProxyableToken(token).withdraw(msg.sender, lpAmount, minAmounts);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return IProxyableToken(token).transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return IProxyableToken(token).approve(msg.sender, spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return IProxyableToken(token).transferFrom(msg.sender, from, to, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        return IProxyableToken(token).increaseAllowance(msg.sender, spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        return IProxyableToken(token).decreaseAllowance(msg.sender, spender, subtractedValue);
    }

    function _staticcall(address implementation) internal view {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := staticcall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _staticcall(token);
    }

    receive() external payable {
        _staticcall(token);
    }
}
