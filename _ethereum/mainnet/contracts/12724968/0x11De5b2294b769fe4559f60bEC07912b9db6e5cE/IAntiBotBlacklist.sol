pragma solidity ^0.8.5;

interface IAntiBotBlacklist {
    function blacklistCheck(address suspect) external view returns(bool);
    function blacklistCheckExpirationTime(address suspect) external view returns(uint256);
    function addSuspect(address suspect,uint256 _expirationTime) external;
    function removeSuspect(address suspect) external;
    function addSuspectBatch(address[] memory _addresses,uint256 _expirationTime) external;
    function removeSuspectBatch(address[] memory _addresses) external;
    event AddSuspect(address indexed suspect);
    event RemoveSuspect(address indexed suspect);
}