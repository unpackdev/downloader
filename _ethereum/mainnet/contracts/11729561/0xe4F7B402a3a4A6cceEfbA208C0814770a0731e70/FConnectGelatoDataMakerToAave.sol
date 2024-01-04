// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConnectGelatoDataMakerToAave.sol";

function _encodeGetDataAndCastMakerToAave(uint256 _vaultId, address _colToken)
    pure
    returns (bytes memory)
{
    return
        abi.encodeWithSelector(
            IConnectGelatoDataMakerToAave.getDataAndCastMakerToAave.selector,
            _vaultId,
            _colToken
        );
}
