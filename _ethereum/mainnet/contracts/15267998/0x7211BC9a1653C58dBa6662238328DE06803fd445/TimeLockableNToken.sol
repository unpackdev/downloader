pragma solidity 0.8.11;

import "./NToken.sol";
import "./DataTypes.sol";

contract TimeLockableNToken is NToken {
  mapping(uint256 => DataTypes.TimeLock) internal _locks;

  function lock(uint256 tokenId, uint16 lockType) public virtual override onlyLendingPool
  {
    uint40[6] memory lock_days = [uint40(0), 60, 90, 120, 240, 360];
    require(lockType < lock_days.length, "NToken: Unknown lockType.");
    require(_exists(tokenId), "NToken: lock for nonexistent token.");
    uint40 expirationTime = 0;
    if(lockType != 0){
      expirationTime = uint40(block.timestamp) + uint40(lock_days[lockType]) * 24 * 3600;
      _locks[tokenId] = DataTypes.TimeLock(expirationTime, lockType);
    }
    emit TimeLocked(tokenId, lockType, expirationTime);
  }

  function _getUnlockTime(uint256 tokenId) internal view virtual override returns(uint40 unlockTime)
  {
    return _locks[tokenId].expiration;
  }

  function _getLockData(uint256 tokenId) internal view virtual override returns(DataTypes.TimeLock memory lockData)
  {
    lockData.lockType = _locks[tokenId].lockType;
    lockData.expiration = _locks[tokenId].expiration;
  }

  function unlockedBalanceOfBatch(address user, uint256[] calldata tokenIds) public view virtual override returns(uint256[] memory amounts)
  {
    require(user != address(0), "NToken: balance query for the zero address");
    uint256[] memory amounts = new uint256[](tokenIds.length);
    uint256 now = block.timestamp;
    for(uint256 i = 0; i < tokenIds.length; ++i){
        if(now > _locks[tokenIds[i]].expiration){
            amounts[i] = 1;
        } else {
            amounts[i] = 0;
        }
    }
    return amounts;
  }

  function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (to == address(0)) {
            if (_locks[tokenId].lockType != 0){
                delete _locks[tokenId];
            }
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}