/*
    Copyright 2021 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.4;

import "./InitializableOwnable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/**
 * @title DODOLimitOrderBot
 * @author DODO Breeder
 */

 contract DODOLimitOrderBot is InitializableOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //=============== Storage ===============
    address public _DODO_LIMIT_ORDER_;
    address public _TOKEN_RECEIVER_;
    address public _DODO_APPROVE_;
    mapping (address => bool) public isAdminListed;
    
    //=============== Event ===============
    event addAdmin(address admin);
    event removeAdmin(address admin);
    event changeReceiver(address newReceiver);
    event Fill();

    function init(
        address owner, 
        address dodoLimitOrder,
        address tokenReceiver,
        address dodoApprove
    ) external {
        initOwner(owner);
        _DODO_LIMIT_ORDER_ = dodoLimitOrder;
        _TOKEN_RECEIVER_ = tokenReceiver;
        _DODO_APPROVE_ = dodoApprove;
    }
     
     function fillDODOLimitOrder(
        bytes memory callExternalData, //call DODOLimitOrder
        address takerToken, 
        uint256 minTakerTokenAmount
     ) external {
        require(isAdminListed[msg.sender], "ACCESS_DENIED");
        uint256 originTakerBalance = IERC20(takerToken).balanceOf(address(this));

        (bool success, bytes memory data) = _DODO_LIMIT_ORDER_.call(callExternalData);
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }

        uint256 takerBalance = IERC20(takerToken).balanceOf(address(this));
        uint256 leftTakerAmount = takerBalance.sub(originTakerBalance);

        require(leftTakerAmount >= minTakerTokenAmount, "TAKER_AMOUNT_NOT_ENOUGH");
        
        IERC20(takerToken).safeTransfer(_TOKEN_RECEIVER_, leftTakerAmount);
        
        emit Fill();
     }

    //call by DODOLimitOrder
    function doLimitOrderSwap(
        uint256 curTakerFillAmount,
        uint256 curMakerFillAmount,
        address makerToken, //fromToken
        address takerToken, //toToken
        address dodoRouteProxy,
        bytes memory dodoApiData
    ) external {
        require(msg.sender == _DODO_LIMIT_ORDER_, "ACCESS_NENIED");
        uint256 originTakerBalance = IERC20(takerToken).balanceOf(address(this));
     
        _approveMax(IERC20(makerToken), _DODO_APPROVE_, curMakerFillAmount);
        
        (bool success, bytes memory data) = dodoRouteProxy.call(dodoApiData);
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }

        uint256 takerBalance = IERC20(takerToken).balanceOf(address(this));
        uint256 returnTakerAmount = takerBalance.sub(originTakerBalance);

        require(returnTakerAmount >= curTakerFillAmount, "SWAP_TAKER_AMOUNT_NOT_ENOUGH");
        
        _approveMax(IERC20(takerToken), _DODO_LIMIT_ORDER_, curTakerFillAmount);
    }


    //============  Ownable ============
    function addAdminList (address userAddr) external onlyOwner {
        isAdminListed[userAddr] = true;
        emit addAdmin(userAddr);
    }

    function removeAdminList (address userAddr) external onlyOwner {
        isAdminListed[userAddr] = false;
        emit removeAdmin(userAddr);
    }

    function changeTokenReceiver(address newTokenReceiver) external onlyOwner {
        _TOKEN_RECEIVER_ = newTokenReceiver;
        emit changeReceiver(newTokenReceiver);
    }


    //============  internal ============
    function _approveMax(IERC20 token,address to,uint256 amount) internal {
        uint256 allowance = token.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, type(uint256).max);
        }
    }

    //============ view ============
    function version() external pure returns (uint256) {
        return 101;
    }
 }