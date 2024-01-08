// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface iRoyaltyDistributor {

    function updateRoyalties(
        address payable[] memory _recipients,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external;

    function withdrawETH() external;

    function withdrawERC20(address token) external;
    
    function withdrawableETH() external view returns(uint256[] memory amounts);

    function withdrawableERC20(address token) external view returns(uint256[] memory amounts);
}
