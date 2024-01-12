// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IConvex {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    //function to get the pool info array's length
    function poolLength() external view returns (uint256);

    function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
    function minter() external view returns(address);
    function get_virtual_price()
        external
        view
        returns (uint256);
}
