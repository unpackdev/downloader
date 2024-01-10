pragma solidity =0.6.6;

interface IERC1363Receiver {
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}
