// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IWeedWarsERC721 {
    function mint(uint256 _claimQty, address _reciever) external;
    function setLock(uint256 _tokenId, address _owner, bool _isLocked) external;
    function getMergeCount(uint256 _tokenId) external view returns (uint);
}
