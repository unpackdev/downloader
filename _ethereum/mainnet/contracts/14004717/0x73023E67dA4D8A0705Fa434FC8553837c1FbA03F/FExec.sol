// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FUtils.sol";
import "./GelatoBytes.sol";

function _execServiceCall(
    address _gelato,
    address _service,
    bytes calldata _data,
    address _creditToken
) returns (uint256 credit) {
    uint256 preCreditTokenBalance = _getBalance(_creditToken, _gelato);

    _prepaidExecServiceCall(_service, _data);

    uint256 postCreditTokenBalance = _getBalance(_creditToken, _gelato);

    credit = postCreditTokenBalance - preCreditTokenBalance;
}

function _prepaidExecServiceCall(address _service, bytes calldata _data) {
    (bool success, bytes memory returndata) = _service.call(_data);
    if (!success)
        GelatoBytes.revertWithError(
            returndata,
            "LibExecAccess.execContractCall:"
        );
}
