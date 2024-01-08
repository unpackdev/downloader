pragma solidity 0.5.17;


interface IProtectionStaking {
    function calculateCompensating(address _investor, uint256 _peakPriceInUsdc) external view returns (uint256);

    function claimCompensation() external;

    function requestProtection(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function protectShares(uint256 _amount) external;

    function withdrawShares(uint256 _amount) external;

    function setPeakMintCap(uint256 _amount) external;
}
