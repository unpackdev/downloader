// Pulled in from dYdX Solo package in order to control Solidity compiler version
// https://github.com/dydxprotocol/protocol_v1/blob/master/contracts/lib/TokenInteract.sol


pragma solidity >=0.6.0;

import "./IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {

    function balanceOf(
        address token,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return IERC20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    )
        internal
        view
        returns (uint256)
    {
        return IERC20(token).allowance(owner, spender);
    }

    function safeApprove(
        address token,
        address to,
        uint value
    )
        internal
    {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: APPROVE_FAILED'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint value
    )
        internal
    {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    )
        internal
    {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }

    function safeTransferETH(
        address to,
        uint value
    )
        internal
    {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
