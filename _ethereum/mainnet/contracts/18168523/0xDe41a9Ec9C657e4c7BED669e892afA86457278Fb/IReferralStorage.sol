// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferralStorage {
    function getMyRefererInfo(address _account) external view returns (bytes32, address);
    function codeOwners(bytes32 _code) external view returns (address);
    function setReferrerTier(address _referrer, uint256 _tierId) external;    
    function setTier(uint256 _tierId, uint256 _totalRebate) external; 
    function setSharePercent(uint256 _sharePercent) external;
    function forceSetCodeOwner(bytes32 _code, address _newAccount) external;
    function trigger(address _referee, uint256 _amount) external;
    function updateTotalFactor(address _account) external;
}
