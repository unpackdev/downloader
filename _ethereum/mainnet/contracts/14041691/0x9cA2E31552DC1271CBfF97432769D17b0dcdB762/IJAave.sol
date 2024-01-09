// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IJAave {
    event TrancheAddedToProtocol(uint256 trancheNum, address trancheA, address trancheB);
    event TrancheATokenMinted(uint256 trancheNum, address buyer, uint256 amount, uint256 taAmount);
    event TrancheBTokenMinted(uint256 trancheNum, address buyer, uint256 amount, uint256 tbAmount);
    event TrancheATokenRedemption(uint256 trancheNum, address burner, uint256 amount, uint256 userAmount, uint256 feesAmount);
    event TrancheBTokenRedemption(uint256 trancheNum, address burner, uint256 amount, uint256 userAmount, uint256 feesAmount);

    function getSingleTrancheUserStakeCounterTrA(address _user, uint256 _trancheNum) external view returns (uint256);
    function getSingleTrancheUserStakeCounterTrB(address _user, uint256 _trancheNum) external view returns (uint256);
    function getSingleTrancheUserSingleStakeDetailsTrA(address _user, uint256 _trancheNum, uint256 _num) external view returns (uint256, uint256);
    function getSingleTrancheUserSingleStakeDetailsTrB(address _user, uint256 _trancheNum, uint256 _num) external view returns (uint256, uint256);
    function getIncentivesControllerAddress() external view returns (address);
    function setIncentivesControllerAddress(address _incentivesController) external;
    function setTrAStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external;
    function setTrBStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external;
}