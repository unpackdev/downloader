pragma solidity ^0.8.0;

interface IDuckHouse {
    struct StakeStatus{
        bool staked;
        uint88 since;
        address user;
    }
    function killCallback() external;
    function _setStakeForGen2Token(uint256 id, address _owner) external;
    function stakedDuckCountByOwner(address _owner) view external returns(uint256);
    function getStakedDuckCountByOwner(address _owner) external returns(uint256);
    function getStakedDuckOfOwnerByIndex(address _owner, uint256 index) external returns(uint256);
    function getGen2StakeStatus(uint256 id) external returns(StakeStatus memory);
}