pragma solidity >=0.6.2 <0.8.0;

interface IERC1155Uried {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function uri(uint256) external returns (string memory);
}
