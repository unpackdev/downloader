pragma solidity =0.6.6;

interface IERC223Recipient {
    function tokenReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external;
}
