pragma solidity =0.6.8;

interface ICoupons {
    function poolSize() external returns (uint256);
    function fillPool(uint256 _amount, address _token) external;
    function mint(address minter, uint256 _amount) external;
}