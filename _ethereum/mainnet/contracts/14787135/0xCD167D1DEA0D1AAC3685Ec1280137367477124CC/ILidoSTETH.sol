// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

interface ILidoSTETH {
    /**
     * @notice Adds eth to the pool
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function getSharesByPooledEth(uint256 _amount) external view returns (uint256);
}
