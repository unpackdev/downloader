library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

contract MultiSend {
    constructor() {}

    function multiSendERC20(address _token, address[] calldata _accounts, uint256[] calldata _amounts) public {
        require (_accounts.length == _amounts.length, 'Invalid lengths');
        for (uint256 i = 0; i < _accounts.length; i++) {
            TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            _accounts[i],
            _amounts[i]
        );
        }
    }

    function multiSendETH(address[] calldata _accounts, uint256[] calldata _amounts) public payable {
        require (_accounts.length == _amounts.length, 'Invalid lengths');
        for (uint256 i = 0; i < _accounts.length; i++) {
            payable(_accounts[i]).transfer(_amounts[i]);
        }
    }
}