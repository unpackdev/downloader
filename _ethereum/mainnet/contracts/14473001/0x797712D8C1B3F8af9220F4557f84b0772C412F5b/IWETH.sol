pragma solidity =0.6.6;

interface IWETH {
    function deposit() external payable;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function withdraw(uint256 amount) external;
}
