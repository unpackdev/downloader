// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "./IERC20.sol";

interface IstETH is IERC20 {
    // TODO: Check these functions
    //    function getPooledEthByShares(uint256 _sharesAmount)
    //        external
    //        view
    //        returns (uint256);
    //
    //    function getSharesByPooledEth(uint256 _pooledEthAmount)
    //        external
    //        view
    //        returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}
