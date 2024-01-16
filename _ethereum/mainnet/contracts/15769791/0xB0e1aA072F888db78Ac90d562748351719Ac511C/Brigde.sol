// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Bridge is Pausable, Ownable, ERC721Holder {
    address public botAddress;
    event BridgedBots(
        address indexed from,
        address indexed to,
        uint256[] botIds
    );

    constructor(address _addr) {
        botAddress = _addr;
    }

    function withdrawBots(address _to, uint256[] memory _botIds)
        external
        onlyOwner
        whenNotPaused
    {
        IERC721 botContract = IERC721(botAddress);
        for (uint256 i = 0; i < _botIds.length; i++) {
            botContract.transferFrom(address(this), _to, _botIds[i]);
        }
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function bridgeBots(address _to, uint256[] calldata _botIds)
        external
        whenNotPaused
    {
        IERC721 botContract = IERC721(botAddress);
        for (uint256 i = 0; i < _botIds.length; i++) {
            botContract.safeTransferFrom(msg.sender, address(this), _botIds[i]);
        }

        emit BridgedBots(msg.sender, _to, _botIds);
    }
}
