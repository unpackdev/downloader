// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./IBridgeAdapter.sol";
import "./IHyphenLiquidityPool.sol";
import "./IWETH.sol";
import "./NativeWrap.sol";

contract TestAdapter {
    using SafeERC20 for IERC20;

    address public pool;

    constructor(address _pool) {
        require(_pool != address(0), "zero address");
        pool = _pool;
    }

    function bridge(
        uint64 _dstChainId,
        address _receiver,
        uint256 _amount,
        address _token
    ) external payable {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(pool, _amount);
        IHyphenLiquidityPool(pool).depositErc20(_dstChainId, _token, _receiver, _amount, "chainhop");
    }

    function bridge(
        uint64 _dstChainId,
        address _receiver,
        uint256 _amount,
        address _token,
        string calldata _tag
    ) external payable {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeApprove(pool, _amount);
        IHyphenLiquidityPool(pool).depositErc20(_dstChainId, _token, _receiver, _amount, _tag);
    }
}
