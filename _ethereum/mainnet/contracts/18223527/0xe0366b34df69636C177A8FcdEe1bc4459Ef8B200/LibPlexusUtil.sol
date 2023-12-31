// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./GenericErrors.sol";
import "./SafeERC20.sol";
import "./Structs.sol";
import "./LibDiamond.sol";
import "./LibData.sol";
import "./console.sol";

library LibPlexusUtil {
    using SafeERC20 for IERC20;
    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes32 internal constant NAMESPACE = keccak256("com.plexus.facets.swap");

    function getSwapStorage() internal pure returns (Dex storage s) {
        bytes32 namespace = NAMESPACE;
        assembly {
            s.slot := namespace
        }
    }

    function dexCheck(address dex) internal view returns (bool result) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        return s.allowedDex[dex];
    }

    function dexProxyCheck(address dex) internal view returns (address proxy) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        return s.proxy[dex];
    }

    function odosRouter() internal view returns (address) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        return s.oDosRouter;
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }

    function getBalance(address token) internal view returns (uint256) {
        return token == address(NATIVE_ADDRESS) ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function userBalance(address user, address token) internal view returns (uint256) {
        return token == address(NATIVE_ADDRESS) ? user.balance : IERC20(token).balanceOf(user);
    }

    function _isNative(address _token) internal pure returns (bool) {
        return (IERC20(_token) == NATIVE_ADDRESS);
    }

    function _isTokenDeposit(address _token, uint256 _amount) internal returns (bool isNotNative) {
        isNotNative = !_isNative(_token);

        if (isNotNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    function _isMultiTokenDeposit(InputToken[] calldata input) internal {
        for (uint i; i < input.length; i++) {
            _isTokenDeposit(input[i].srcToken, input[i].amount);
        }
    }

    function _tokenDepositAndSwap(SwapData calldata swap) internal returns (uint256) {
        _isTokenDeposit(swap.srcToken, swap.amount);
        Dex storage s = LibPlexusUtil.getSwapStorage();
        require(s.allowedDex[swap.swapRouter]);
        uint256 dstAmount = _swapStart((swap));
        return dstAmount;
    }

    function _tokenDepositAndMultiSwap(SwapData[] calldata swap) internal returns (uint256) {
        for (uint i; i < swap.length; i++) {
            for (uint j; j < i; j++) {
                require(swap[i].srcToken != swap[j].srcToken, "Duplicate source tokens");
                require(swap[i].dstToken == swap[j].dstToken, "The dstToken address is different.");
            }
            require(dexCheck(swap[i].swapRouter), "This address is not allowed.");
            _isTokenDeposit(swap[i].srcToken, swap[i].amount);
        }
        uint256 dstAmount = _multiTokenSwapStart(swap);
        return dstAmount;
    }

    function _swapStart(SwapData calldata swap) internal returns (uint256 dstAmount) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        require(s.allowedDex[swap.swapRouter]);
        bool isNotNative = !_isNative(swap.srcToken);
        if (isNotNative) {
            if (s.proxy[swap.swapRouter] != address(0)) {
                IERC20(swap.srcToken).safeApprove(s.proxy[swap.swapRouter], swap.amount);
            } else {
                IERC20(swap.srcToken).safeApprove(swap.swapRouter, swap.amount);
            }
        }
        uint256 initDstTokenBalance = getBalance(swap.dstToken);
        (bool succ, ) = swap.swapRouter.call{value: isNotNative ? 0 : swap.amount}(swap.callData);
        if (succ) {
            uint256 dstTokenBalance = getBalance(swap.dstToken);
            dstAmount = dstTokenBalance - initDstTokenBalance;
        } else {
            revert SwapFailed();
        }
    }

    function _multiTokenSwapStart(SwapData[] calldata swap) internal returns (uint256 dstAmount) {
        uint256 dstBeforeBalance = getBalance(swap[0].dstToken);
        for (uint256 i; i < swap.length; i++) {
            bool isNotNative = !_isNative(swap[i].srcToken);
            if (isNotNative) {
                address proxy = dexProxyCheck(swap[i].swapRouter);
                if (proxy != address(0)) {
                    IERC20(swap[i].srcToken).safeApprove(proxy, swap[i].amount);
                } else {
                    IERC20(swap[i].srcToken).safeApprove(swap[i].swapRouter, swap[i].amount);
                }
            }
            (bool succ, ) = swap[i].swapRouter.call{value: isNotNative ? 0 : swap[i].amount}(swap[i].callData);
            if (succ) {
                return getBalance(swap[0].dstToken) - dstBeforeBalance;
            } else {
                revert SwapFailed();
            }
        }
    }

    function _oDosSwapStart(OdosData calldata _oDos) internal returns (uint256[] memory) {
        address oDos = odosRouter();
        for (uint i; i < _oDos.inputToken.length; i++) {
            bool isNotNative = !_isNative(_oDos.inputToken[i].srcToken);
            if (isNotNative) {
                IERC20(_oDos.inputToken[i].srcToken).safeApprove(oDos, 0);
                IERC20(_oDos.inputToken[i].srcToken).safeApprove(oDos, _oDos.inputToken[i].amount);
            }
        }
        uint256 length = _oDos.outputToken.length;
        uint256[] memory initDstTokenBalance = new uint256[](length);
        uint256[] memory dstTokenBalance = new uint256[](length);
        for (uint i; i < length; i++) {
            initDstTokenBalance[i] = getBalance(_oDos.outputToken[i].dstToken);
        }
        (bool succ, ) = oDos.call{value: msg.value}(_oDos.data);
        if (succ) {
            for (uint i; i < length; i++) {
                dstTokenBalance[i] = getBalance(_oDos.outputToken[i].dstToken) - initDstTokenBalance[i];
            }
            return dstTokenBalance;
        } else {
            revert("oDos failed");
        }
    }

    function _oDosSwapStartOnly(OdosData calldata _oDos) internal returns (uint256) {
        address oDos = odosRouter();
        for (uint i; i < _oDos.inputToken.length; i++) {
            bool isNotNative = !_isNative(_oDos.inputToken[i].srcToken);
            if (isNotNative) {
                IERC20(_oDos.inputToken[i].srcToken).safeApprove(oDos, 0);
                IERC20(_oDos.inputToken[i].srcToken).safeApprove(oDos, _oDos.inputToken[i].amount);
            }
        }
        uint256 initDstTokenBalance = getBalance(_oDos.outputToken[0].dstToken);

        (bool succ, ) = oDos.call{value: msg.value}(_oDos.data);
        if (succ) {
            uint256 dstTokenBalance = getBalance(_oDos.outputToken[0].dstToken) - initDstTokenBalance;

            return dstTokenBalance;
        } else {
            revert("oDos Only failed");
        }
    }

    function _safeNativeTransfer(address to_, uint256 amount_) internal {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe safeTransfer fail");
    }

    function _fee(address dstToken, uint256 dstAmount) internal returns (uint256 returnAmount) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 getFee = (dstAmount * ds.fee) / 10000;
        returnAmount = dstAmount - getFee;

        if (getFee > 0) {
            if (!_isNative(dstToken)) {
                IERC20(dstToken).safeTransfer(ds.feeReceiver, getFee);
            } else {
                _safeNativeTransfer(ds.feeReceiver, getFee);
            }
        }
    }
}
