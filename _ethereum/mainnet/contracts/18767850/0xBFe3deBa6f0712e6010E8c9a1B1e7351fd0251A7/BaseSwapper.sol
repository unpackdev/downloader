// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./BytesLib.sol";

contract BaseSwapper {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /// @dev Reset approval and approve exact amount
    function _safeApproveHelper(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(recipient, 0);
        IERC20(token).safeApprove(recipient, amount);
    }

    function _bytesToAddress(bytes memory _data) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_data, 20))
        }
    }

}
