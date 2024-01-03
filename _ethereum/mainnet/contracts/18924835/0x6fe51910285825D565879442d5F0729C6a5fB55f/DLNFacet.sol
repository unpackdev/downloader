// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./GenericErrors.sol";

import "./IBridge.sol";
import "./IDLN.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./LibData.sol";
import "./LibPlexusUtil.sol";
import "./console.sol";

contract DLNFacet is IBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IDLN private immutable dln;

    constructor(IDLN _dln) {
        dln = _dln;
    }

    function bridgeToDln(BridgeData memory _bridgeData, DLNData memory _dlnDesc) external payable nonReentrant {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _dlnDesc.actualInputAmount);
        _dlnStart(_bridgeData, _dlnDesc);
    }

    function swapAndBridgeToDln(SwapData calldata _swap, BridgeData memory _bridgeData, DLNData memory _dlnDesc) external payable nonReentrant {
        LibPlexusUtil._isSwapTokenDeposit(_swap.input);
        _dlnDesc.actualInputAmount = LibPlexusUtil._bridgeSwapStart(_swap);
        if (_swap.dup[0].token == _swap.output[0].dstToken) {
            LibPlexusUtil._isTokenDeposit(_swap.dup[0].token, _swap.dup[0].amount);
            _dlnDesc.actualInputAmount = _dlnDesc.actualInputAmount + _swap.dup[0].amount;
        }
        _dlnStart(_bridgeData, _dlnDesc);
    }

    function _dlnStart(BridgeData memory _bridgeData, DLNData memory _dlnDesc) internal {
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        if (isNotNative) {
            IERC20(_bridgeData.srcToken).safeApprove(address(dln), _dlnDesc.actualInputAmount);
            OrderCreation memory order = OrderCreation({
                giveTokenAddress: _bridgeData.srcToken,
                giveAmount: _dlnDesc.actualInputAmount,
                takeTokenAddress: abi.encodePacked(_dlnDesc.takeTokenAddress),
                takeAmount: _dlnDesc.takeAmount,
                takeChainId: uint256(_bridgeData.dstChainId),
                receiverDst: abi.encodePacked(_bridgeData.recipient),
                givePatchAuthoritySrc: _bridgeData.recipient,
                orderAuthorityAddressDst: abi.encodePacked(_bridgeData.recipient),
                allowedTakerDst: "",
                externalCall: "",
                allowedCancelBeneficiarySrc: ""
            });
            dln.createOrder{value: _dlnDesc.nativeFee}(order, "", 0, "");
            IERC20(_bridgeData.srcToken).safeApprove(address(dln), 0);
        } else {
            require(_bridgeData.srcToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), "not native");
            _bridgeData.srcToken = address(0);
            if (address(_dlnDesc.takeTokenAddress) == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) _dlnDesc.takeTokenAddress = address(0);

            OrderCreation memory order = OrderCreation({
                giveTokenAddress: _bridgeData.srcToken,
                giveAmount: _dlnDesc.actualInputAmount,
                takeTokenAddress: abi.encodePacked(_dlnDesc.takeTokenAddress),
                takeAmount: _dlnDesc.takeAmount,
                takeChainId: uint256(_bridgeData.dstChainId),
                receiverDst: abi.encodePacked(_bridgeData.recipient),
                givePatchAuthoritySrc: _bridgeData.recipient,
                orderAuthorityAddressDst: abi.encodePacked(_bridgeData.recipient),
                allowedTakerDst: "",
                externalCall: "",
                allowedCancelBeneficiarySrc: ""
            });
            dln.createOrder{value: _dlnDesc.actualInputAmount + _dlnDesc.nativeFee}(order, "", 0, "");
        }
        emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _dlnDesc.actualInputAmount, _bridgeData.plexusData, "DLN");
    }
}
