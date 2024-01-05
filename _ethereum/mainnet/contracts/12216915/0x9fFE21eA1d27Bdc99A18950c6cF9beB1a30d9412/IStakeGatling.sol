pragma solidity 0.6.12;

interface IStakeGatling {

    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function presentRate() external view returns (uint256);
    function totalLPAmount() external view returns (uint256);
    function totalToken() external view returns (uint256 amount0, uint256 amount1);

    function burn(address _to, uint256 _amount) external returns (uint256 amount0, uint256 amount1);
    function lpStakeDst() external view returns (address);

}