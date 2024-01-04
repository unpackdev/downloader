// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConnectGelatoDataMakerToMaker.sol";

function _encodeGetDataAndCastMakerToMaker(
    uint256 _vaultAId,
    uint256 _vaultBId,
    string memory _colType,
    address _colToken
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectGelatoDataMakerToMaker.getDataAndCastMakerToMaker.selector,
            _vaultAId,
            _vaultBId,
            _colType,
            _colToken
        );
}
