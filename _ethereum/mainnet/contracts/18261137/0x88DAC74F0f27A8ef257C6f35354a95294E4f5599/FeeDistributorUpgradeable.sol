// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./RolesUpgradeable.sol";
import "./IFeeDistributorUpgradeable.sol";
import "./Constants.sol";

contract FeeDistributorUpgradeable is IFeeDistributorUpgradeable, RolesUpgradeable {
    FeeInfo internal _clientInfo;

    function __FeeCollector_init(FeeInfo calldata clientInfo_) internal onlyInitializing {
        __FeeCollector_init_unchained(clientInfo_);
    }

    function __FeeCollector_init_unchained(FeeInfo calldata clientInfo_) internal onlyInitializing {
        _updateFee(clientInfo_);
    }

    function configFeeRecipient(FeeInfo calldata feeInfo_) external onlyRole(OPERATOR_ROLE) {
        _updateFee(feeInfo_);
    }

    function _updateFee(FeeInfo memory feeInfo_) internal {
        if (feeInfo_.recipient == address(0) || feeInfo_.percentageInBps == 0) revert InvalidRecipient();
        _clientInfo = feeInfo_;
    }

    function clientInfo() public view returns (address recipient, uint96 percentage) {
        return (_clientInfo.recipient, _clientInfo.percentageInBps);
    }

    uint256[49] private __gap;
}
