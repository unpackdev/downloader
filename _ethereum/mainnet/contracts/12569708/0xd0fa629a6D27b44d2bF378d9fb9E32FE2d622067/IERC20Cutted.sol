pragma solidity ^0.6.2;


interface IERC20Cutted {

    // Some old tokens are implemented without a retrun parameter (this was prior to the ERC20 standart change)
    function transfer(address to, uint256 value) external;

    function balanceOf(address who) external view returns (uint256);

}
