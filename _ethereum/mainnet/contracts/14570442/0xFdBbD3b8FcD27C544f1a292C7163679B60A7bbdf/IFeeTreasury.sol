// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./SafeERC20.sol";

interface IFeeTreasury {
    event AddAdmins(address[] managers);
    event RemoveAdmins(address[] managers);
    event AddRouters(address[] routers);
    event RemoveRouters(address[] routers);
    event UpdateFeeDistributor(address feeDistributor);
    event UpdateProtocolFeeBPS(uint16 protocolFeeBPS);
    event UpdateTwapDuration(uint32 twapDuration);
    event UpdateMaxTwapDelta(uint24 maxTwapDelta);
    event UpdateLPToken(address lpToken);
    event UpdateOperationsCollector(address operationsCollector);
    event CheckpointFees(
        uint256 protocolBalance0,
        uint256 operationsBalance0,
        uint256 protocolBalance1,
        uint256 operationsBalance1
    );
    event DisperseProtocolFees(uint256 token0, uint256 token1, uint256 lp);
    event FundManagerBalance(address manager, address vault, uint256 amount);

    // ====== PERMISSIONED OWNER FUNCTIONS ========
    function whitelistRouters(address[] memory whitelist) external;

    function blacklistRouters(address[] memory blacklist) external;

    function whitelistAdmins(address[] memory whitelist) external;

    function blacklistAdmins(address[] memory blacklist) external;

    function updateFeeDistributor(address newFeeDistributor) external;

    function updateProtocolFeeBPS(uint16 newProtocolFeeBPS) external;

    function updateMaxTwapDelta(uint24 newMaxTwapDelta) external;

    function updateTwapDuration(uint32 newTwapDuration) external;

    function updateLPToken(address newLPToken) external;

    function updateOperationsCollector(address newOperations) external;

    function multiSwapForWETH(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        address[] memory routers,
        bytes[] memory swapPayloads
    ) external;

    function swapForWETH(
        IERC20 token,
        uint256 amount,
        address router,
        bytes memory swapPayload
    ) external;

    function disperseProtocolFees(
        uint256 amount,
        address router,
        bytes memory swapPayload
    ) external;
}
