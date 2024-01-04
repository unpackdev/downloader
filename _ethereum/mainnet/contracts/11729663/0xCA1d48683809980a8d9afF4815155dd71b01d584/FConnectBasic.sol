// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConnectBasic.sol";

function _encodeBasicWithdraw(
    address _erc20,
    uint256 _tokenAmt,
    address payable _to,
    uint256 _getId,
    uint256 _setId
) pure returns (bytes memory) {
    return
        abi.encodeWithSelector(
            IConnectBasic.withdraw.selector,
            _erc20,
            _tokenAmt,
            _to,
            _getId,
            _setId
        );
}
