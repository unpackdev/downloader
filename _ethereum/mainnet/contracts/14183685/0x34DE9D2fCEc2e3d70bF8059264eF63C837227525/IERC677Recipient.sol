pragma solidity =0.6.6;

interface IERC677Recipient {
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}
