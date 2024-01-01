// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Mock {

    address public router;
    address public approve;
    address public owner;

    constructor(address dexRouter, address tokenApprove) {
        router = dexRouter;
        approve = tokenApprove;
        owner = msg.sender;
    }

    function mockfunc(address from, address to, uint amountIn, bytes memory data1, bytes memory data2) public payable returns (uint256) {
        if (data1.length > 0) {
            (bool res1, bytes memory returnAmount1) = payable(router).call{value : msg.value}(data1);
            require(res1, string(returnAmount1));
            require(uint256(bytes32(returnAmount1)) > amountIn, "returnAmount1 less than amountIn");
            safeApprove(IERC20(from), approve, amountIn);
            (bool res2, bytes memory returnAmount2) = payable(router).call(data2);
            require(res2, string(returnAmount2));
            uint256 returnAmount = uint256(bytes32(returnAmount2));
            safeTransfer(IERC20(to), msg.sender, returnAmount);
            return returnAmount;
        } else {
            (bool res2, bytes memory returnAmount2) = payable(router).call{value : msg.value}(data2);
            require(res2, string(returnAmount2));
            uint256 returnAmount = uint256(bytes32(returnAmount2));
            safeTransfer(IERC20(to), msg.sender, returnAmount);
            return returnAmount;
        }
    }

    function setRouter(address newRouter) public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        router = newRouter;
    }

    function setApprove(address newApprove) public {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        approve = newApprove;
    }

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        forceApprove(token, spender, value);
    }

    function _makeCall(IERC20 token, bytes4 selector, address to, uint256 amount) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {// solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {success := gt(extcodesize(token), 0)}
                default {success := and(gt(returndatasize(), 31), eq(mload(0), 1))}
            }
        }
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (!_makeCall(token, token.approve.selector, spender, 0) ||
            !_makeCall(token, token.approve.selector, spender, value))
            {
                revert ForceApproveFailed();
            }
        }
    }

    error SafeTransferFailed();
    error ForceApproveFailed();

}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}