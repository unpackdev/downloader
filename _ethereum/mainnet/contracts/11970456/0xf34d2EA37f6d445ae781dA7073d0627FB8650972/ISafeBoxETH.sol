pragma solidity ^0.7.0;

interface SafeBoxETH {
    function uToken() external view returns (address);

    function cToken() external view returns (address);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256) external;
}
