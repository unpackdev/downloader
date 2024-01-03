pragma solidity ^0.6.0;
import "./IERC165.sol";

interface IStakeForVnfts is IERC165 {
    function stake(uint256 _amount) external;

    function redeem() external;

    function earned(address account) external view returns (uint256 _earned);

    function exit() external;
}
