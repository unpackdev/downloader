// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155LockerProxy {
    /**
     * @dev Raised when called by invalid caller
     */
    error InvalidCaller();

    event RouterSet(address indexed _router);
    event AssetsLocked(
        address indexed from,
        address indexed to,
        uint16 srcChainId,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event AssetsUnlocked(
        address indexed to,
        uint16 srcChainId,
        uint256[] tokenIds,
        uint256[] amounts
    );

    function unlock(
        address _to,
        uint16 _srcChainId,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
}
