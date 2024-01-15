//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";

abstract contract BaseSupport {
    using SafeMath for uint256;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 internal constant _ETH_ADDRESS = IERC20(ETH);
    IERC20 internal constant _ZERO_ADDRESS = IERC20(address(0));

    uint256 private constant BASE_DECIMALS = 18;

    uint8 internal constant UNI3_TYPE = 1;
    uint8 internal constant CURVE_TYPE = 2;
    uint8 internal constant DODO_TYPE = 3;
    uint8 internal constant UNI2_TYPE = 4;
    uint8 internal constant VELODROME_TYPE = 5;
    uint8 internal constant LSR_TYPE = 6;

    function _isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    function _safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        require(!_isETH(token), "BaseSupport: Approve called on ETH");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.approve.selector, to, amount));

        if (!success || (returndata.length > 0 && !abi.decode(returndata, (bool)))) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, to, 0));
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, to, amount));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        (bool success, bytes memory result) = address(token).call(data);
        require(success, "BaseSupport: Low-level call failed");

        if (result.length > 0) {
            require(abi.decode(result, (bool)), "BaseSupport: ERC20 operation did not succeed");
        }
    }

    function _handleDecimals(address _token, uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) return 0;
        uint8 _decimals = IERC20Metadata(_token).decimals();
        return _amount.mul(10**BASE_DECIMALS).div(10**_decimals);
    }
}
