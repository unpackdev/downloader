// SPDX-License-Identifier: MIT

import "./Ownable.sol";

pragma solidity ^0.8.0;

contract HyperwarpManager is Ownable {

    bool public isHyperwarpingPaused = false;

    uint256 public maxUtilityBattlerId = 1001;

    function flipHyperwarpingState() public onlyOwner {
        isHyperwarpingPaused = !isHyperwarpingPaused;
    }

    function setMaxUtilityBattlerId(uint256 _tokenId) public onlyOwner {
        maxUtilityBattlerId = _tokenId;
    }

    function battlerHasUtility(uint256 _tokenId) public view returns(bool) {
        return _tokenId <= maxUtilityBattlerId;
    }

    function tryHyperwarp(uint256 _jumpClone, uint256 _assist) external view returns(bool) {
        require(_jumpClone != _assist, "Jumpcloner and assist must be different");
        require(!isHyperwarpingPaused, "Hyperwarping is paused");
        require(battlerHasUtility(_jumpClone), "Not an alpha species");
        require(battlerHasUtility(_assist), "Not an alpha species");
        return true;
    }

    function tryManifest(uint256 _tokenId) external view returns(bool) {
        require(!isHyperwarpingPaused, "Hyperwarping is paused");
        return true;
    }
}