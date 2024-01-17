// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface ITokenikV1Rewards {

    function addReward(address _user, uint256 _amount) external;
    function addSwapReward(address _user, uint256 _amount, address _token) external;
    function removeReward(address _user, uint256 _amount) external returns(bool);
    function claimAirdrop(address _ref) external;
    function getRewards(address _address) external view returns(uint256);
    function getClaimedAirdrop(address _address) external view returns(bool);
    function getApprovedCaller(address _address) external view returns(bool);
    function setCallerSetter(address _callerSetter) external;
    function setApprovedCaller(address _caller, bool _approved) external;
    function setAddRewardPaused(bool  _paused) external;
    function setRemoveRewardPaused(bool  _paused) external;
    function setAirdropAmounts(uint256 _amount, uint256 _refAmount) external;
    function enableAirdrop(bool  _enabled) external;
    function addLiquidityReward(address _user, address _token0, address _token1, uint256 _amount0, uint256 _amount1) external;
    function removeSwapReward(address _user, uint256 _amount, address _token) external returns(bool);
    function getApprovedToken(address _address) external view returns(bool);
    function getApprovedTokens(address _token0, address _token1) external view returns(bool,bool);
    function setApprovedTokens(address _token, bool _approved) external;
}