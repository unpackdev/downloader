// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./KeepersERC721Storage.sol";

abstract contract KeepersMintWindowModifiers {
    /**
     * @notice Thrown if the mint window is closed
     */
    error MintWindowClosed(uint256);
    /**
     * @notice Thrown if the mint window is still open
     */
    error MintWindowOpen(uint256);

    function _isMintingWindowOpen() internal view returns (bool) {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        return block.timestamp >= l.saleStartTimestamp && block.timestamp <= l.saleCompleteTimestamp;
    }

    modifier whenMintWindowOpen() {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        if (!_isMintingWindowOpen()) {
            revert MintWindowClosed(l.saleCompleteTimestamp);
        }
        _;
    }

    modifier whenMintWindowClosed() {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        if (_isMintingWindowOpen()) {
            revert MintWindowOpen(l.saleStartTimestamp);
        }
        _;
    }
}
