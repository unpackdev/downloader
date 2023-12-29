// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IBridge.sol";
import "./ISynapse.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./LibData.sol";
import "./LibPlexusUtil.sol";
import "./console.sol";

contract SynapseFacet is IBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ISynapse private immutable synapseRouter;

    constructor(ISynapse _synapseRouter) {
        synapseRouter = _synapseRouter;
    }

    function bridgeToSynapse(BridgeData memory _bridgeData, SynapseData memory _synapseDesc) external payable nonReentrant {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _bridgeData.amount);
        _synapseStart(_bridgeData, _synapseDesc);
    }

    function swapAndBridgeToSynapse(
        SwapData calldata _swap,
        BridgeData memory _bridgeData,
        SynapseData memory _synapseDesc
    ) external payable nonReentrant {
        _bridgeData.amount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        _synapseStart(_bridgeData, _synapseDesc);
    }

    function _synapseStart(BridgeData memory _bridgeData, SynapseData memory _synapseDesc) internal {
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        if (isNotNative) {
            IERC20(_bridgeData.srcToken).safeApprove(address(synapseRouter), _bridgeData.amount);
            synapseRouter.bridge(
                _bridgeData.recipient,
                uint256(_bridgeData.dstChainId),
                _bridgeData.srcToken,
                _bridgeData.amount,
                _synapseDesc.originQuery,
                _synapseDesc.destQuery
            );
            IERC20(_bridgeData.srcToken).safeApprove(address(synapseRouter), 0);
        } else {
            synapseRouter.bridge{value: msg.value}(
                _bridgeData.recipient,
                uint256(_bridgeData.dstChainId),
                _bridgeData.srcToken,
                _bridgeData.amount,
                _synapseDesc.originQuery,
                _synapseDesc.destQuery
            );
        }
        emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
    }
}
