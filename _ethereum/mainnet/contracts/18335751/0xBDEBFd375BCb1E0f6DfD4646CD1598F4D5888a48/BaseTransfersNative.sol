// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./IBaseNativeWrapperV1.sol";
import "./BaseTransfers.sol";
import "./CoreTransfersNative.sol";

abstract contract BaseTransfersNative is IBaseNativeWrapperV1, CoreTransfersNative, BaseTransfers {
    function deposit(
        uint256[] calldata amounts,
        address[] calldata assetAddresses
    ) external payable override onlyClients nonReentrant stopGuarded {
        _depositNativeAndERC20(amounts, assetAddresses);
        emit Deposit(_msgSender(), assetAddresses, amounts);
    }

    function supportsNativeAssets() public pure override returns (bool) {
        return true;
    }
}
