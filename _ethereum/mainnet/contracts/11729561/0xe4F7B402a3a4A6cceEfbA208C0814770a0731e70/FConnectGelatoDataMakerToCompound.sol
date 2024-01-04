// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConnectGelatoDataMakerToCompound.sol";

function _encodeGetDataAndCastMakerToCompound(
    uint256 _vaultId,
    address _colToken
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectGelatoDataMakerToCompound
                .getDataAndCastMakerToCompound
                .selector,
            _vaultId,
            _colToken
        );
}
