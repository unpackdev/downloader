// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

interface iRoyaltyDistributor {

    function updateRecipients(address payable[3] memory _recpinents) external;

    // For specific addresses
    function withdrawETH() external;

    function withdrawERC20(address token) external;
    
    function withdrawableETH() external view returns(uint256[] memory amounts);

    function withdrawableERC20(address token) external view returns(uint256[] memory amounts);
    
    // For community
    function withdrawCommunityRoyalty(uint256 allowance) external;

    function withdrawableCommunityRoyalty(uint256 allowance) external view returns(uint256 amount);
}
