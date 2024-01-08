pragma solidity >=0.8.4 <= 0.8.6;

interface ILockable {

    event SetLock(uint256 _tokenId, bool _isLock);

    function lock(uint256 _tokenId) external;

    function unlock(uint256 _tokenId) external;

    function isLock(uint256 _tokenId) external view returns(bool);
}