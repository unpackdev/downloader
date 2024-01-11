//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./ICommand.sol";
import "./ManagerLike.sol";
import "./BotLike.sol";
import "./MPALike.sol";
import "./ServiceRegistry.sol";
import "./McdView.sol";

contract CloseCommand is ICommand {
    address public immutable serviceRegistry;
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant MCD_VIEW_KEY = "MCD_VIEW";
    string private constant MPA_KEY = "MULTIPLY_PROXY_ACTIONS";

    constructor(address _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
    }

    function isExecutionCorrect(uint256 cdpId, bytes memory) external view override returns (bool) {
        address viewAddress = ServiceRegistry(serviceRegistry).getRegisteredService(MCD_VIEW_KEY);
        McdView viewerContract = McdView(viewAddress);
        (uint256 collateral, uint256 debt) = viewerContract.getVaultInfo(cdpId);
        return !(collateral > 0 || debt > 0);
    }

    function isExecutionLegal(uint256 _cdpId, bytes memory triggerData)
        external
        view
        override
        returns (bool)
    {
        (, , uint256 slLevel) = abi.decode(triggerData, (uint256, uint16, uint256));

        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );
        ManagerLike manager = ManagerLike(managerAddress);
        if (manager.owns(_cdpId) == address(0)) {
            return false;
        }
        address viewAddress = ServiceRegistry(serviceRegistry).getRegisteredService(MCD_VIEW_KEY);
        uint256 collRatio = McdView(viewAddress).getRatio(_cdpId, true);
        bool vaultNotEmpty = collRatio != 0; // MCD_VIEW contract returns 0 (instead of infinity) as a collateralisation ratio of empty vault
        return vaultNotEmpty && collRatio <= slLevel * 10**16;
    }

    function execute(
        bytes calldata executionData,
        uint256,
        bytes memory triggerData
    ) external override {
        (, uint16 triggerType, ) = abi.decode(triggerData, (uint256, uint16, uint256));

        address mpaAddress = ServiceRegistry(serviceRegistry).getRegisteredService(MPA_KEY);

        bytes4 prefix = abi.decode(executionData, (bytes4));
        bytes4 expectedSelector;

        if (triggerType == 1) {
            expectedSelector = MPALike.closeVaultExitCollateral.selector;
        } else if (triggerType == 2) {
            expectedSelector = MPALike.closeVaultExitDai.selector;
        } else revert("unsupported-triggerType");

        require(prefix == expectedSelector, "wrong-payload");
        //since all global values in this contract are either const or immutable, this delegate call do not break any storage
        //this is simplest approach, most similar to way we currently call dsProxy
        // solhint-disable-next-line avoid-low-level-calls
        (bool status, ) = mpaAddress.delegatecall(executionData);

        require(status, "execution failed");
    }

    function isTriggerDataValid(uint256 _cdpId, bytes memory triggerData)
        external
        pure
        override
        returns (bool)
    {
        (uint256 cdpId, uint16 triggerType, uint256 slLevel) = abi.decode(
            triggerData,
            (uint256, uint16, uint256)
        );
        return slLevel > 100 && _cdpId == cdpId && (triggerType == 1 || triggerType == 2);
    }
}
