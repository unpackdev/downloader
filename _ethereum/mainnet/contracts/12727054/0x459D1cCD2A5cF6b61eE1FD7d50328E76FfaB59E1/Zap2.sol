// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IOpeth.sol";
import "./OpethZap.sol";

contract Zap2 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable weth;
    IOpeth public immutable opeth;

    constructor(
        IERC20 _weth,
        IOpeth _opeth
    ) public {
        weth = _weth;
        opeth = _opeth;
        _weth.safeApprove(address(_opeth), uint(-1));
    }

    function mintWithOtoken(address oToken) external payable {
        uint _opeth = msg.value.div(1e10);
        IERC20(oToken).safeTransferFrom(msg.sender, address(this), _opeth);
        IERC20(oToken).safeApprove(address(opeth), _opeth);
        WETH9(address(weth)).deposit{value: msg.value}();
        opeth.mintFor(msg.sender, oToken, _opeth);
    }
}
