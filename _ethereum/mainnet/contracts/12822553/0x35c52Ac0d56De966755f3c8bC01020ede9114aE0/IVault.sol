// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external returns (uint256);

    function withdrawAll() external;
}
