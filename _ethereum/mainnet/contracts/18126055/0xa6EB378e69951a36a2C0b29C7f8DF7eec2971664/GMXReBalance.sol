pragma solidity ^0.6.10;
pragma experimental "ABIEncoderV2";
import "./IGMXAdapter.sol";
import "./IGMXReBalance.sol";
import "./IController.sol";

import "./ReentrancyGuard.sol";
import "./ModuleBase.sol";
import "./IJasperVault.sol";

contract GMXReBalance is ModuleBase, ReentrancyGuard, IGMXReBalance {
    constructor(IController _controller) public ModuleBase(_controller) {}

    function _rebalanceGMX(
        IJasperVault jasperVault,
        GMXInfo memory gmxInfos
    ) external override nonReentrant onlyManagerAndValidSet(jasperVault) {
        IGMXAdapter gmxAdapter = IGMXAdapter(
            getAndValidateAdapter(gmxInfos._integrationName)
        );
        address _callContract;
        uint256 _callValue;
        bytes memory _callByteData;
        if (!gmxAdapter.IsApprovedPlugins(address(jasperVault))) {
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .approvePositionRouter();
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.increasePositionRequests.length; i++) {
            IGMXAdapter.SwapData memory request = gmxInfos.swapDatas[i];
            jasperVault.invokeApprove(
                request._path[0],
                gmxAdapter.GMXRouter(),
                request._amountIn
            );
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getSwapCallData(request);
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.increasePositionRequests.length; i++) {
            IGMXAdapter.IncreasePositionRequest memory request = gmxInfos
                .increasePositionRequests[i];
            jasperVault.invokeApprove(
                request._path[0],
                gmxAdapter.GMXRouter(),
                request._amountIn
            );
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getInCreasingPositionCallData(request);
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.decreasePositionRequest.length; i++) {
            IGMXAdapter.DecreasePositionRequest memory request = gmxInfos
                .decreasePositionRequest[i];
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getDeCreasingPositionCallData(request);
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.increaseOrderDatas.length; i++) {
            IGMXAdapter.IncreaseOrderData memory request = gmxInfos
                .increaseOrderDatas[i];
            jasperVault.invokeApprove(
                request._path[0],
                gmxAdapter.GMXRouter(),
                request._amountIn
            );
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getCreateIncreaseOrderCallData(request);
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.decreaseOrderDatas.length; i++) {
            IGMXAdapter.DecreaseOrderData memory request = gmxInfos
                .decreaseOrderDatas[i];
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getCreateDecreaseOrderCallData(request);
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.stakeGMXDatas.length; i++) {
            IGMXAdapter.StakeGMXData memory request = gmxInfos.stakeGMXDatas[i];

            if (request._isStake) {
                jasperVault.invokeApprove(
                    request._collateralToken,
                    gmxAdapter.StakedGmx(),
                    request._amount
                );
            }
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getStakeGMXCallData(
                    address(jasperVault),
                    request._amount,
                    request._isStake,
                    request._positionData
                );
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
        for (uint256 i = 0; i < gmxInfos.stakeGLPDatas.length; i++) {
            IGMXAdapter.StakeGLPData memory request = gmxInfos.stakeGLPDatas[i];

            if (request._isStake) {
                jasperVault.invokeApprove(
                    request._token,
                    gmxAdapter.GlpRewardRouter(),
                    request._amount
                );
            }
            (_callContract, _callValue, _callByteData) = gmxAdapter
                .getStakeGLPCallData(
                    address(jasperVault),
                    request._token,
                    request._amount,
                    request._minUsdg,
                    request._minGlp,
                    request._isStake,
                    request._data
                );
            jasperVault.invoke(_callContract, _callValue, _callByteData);
        }
    }

    function removeModule() external override {}
}
