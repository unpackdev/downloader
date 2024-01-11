// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IYieldsterVault {
    function tokenValueInUSD() external view returns (uint256);

    function getVaultNAV() external view returns (uint256);

    function getAssetList() external view returns (address[] memory);

    function protocolInteraction(
        address,
        bytes memory,
        uint256[] memory,
        address[] memory,
        address[] memory
    ) external;

    function exchangeToken(
        address,
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function exchangeTokenUsing0x(
        address,
        address,
        uint256,
        bytes memory
    ) external;

    function getTokenBalance(address _token) external view returns (uint256);
}
