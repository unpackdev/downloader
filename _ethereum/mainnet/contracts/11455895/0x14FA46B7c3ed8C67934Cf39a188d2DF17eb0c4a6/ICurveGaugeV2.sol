pragma solidity 0.5.16;

interface ICurveGaugeV2 {
    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function balanceOf(address _addr) external returns (uint256);

    function approve(address _addr, uint256 _amount) external returns (bool);

    function crv_token() external returns (address);
}
