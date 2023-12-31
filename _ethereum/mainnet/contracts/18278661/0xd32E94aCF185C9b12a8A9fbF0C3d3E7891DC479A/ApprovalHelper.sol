// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./CallOptionalReturn.sol";

contract ApprovalHelper is CallOptionalReturn {

    bytes4 constant approveSelector = IERC20
        .approve
        .selector;

    /**
     * @dev
     * Allows to execute safe approve for a token
     */
    function _safeApprove(
        address _token,
        address _spender,
        uint256 _value
    )
        internal
    {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                approveSelector,
                _spender,
                _value
            )
        );
    }
}