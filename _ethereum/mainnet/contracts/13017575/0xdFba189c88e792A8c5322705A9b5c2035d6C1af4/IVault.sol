// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVault {
    function token() external view returns (address);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    // Part of ERC20 interface

    //function name() external view returns (string memory);
    //function symbol() external view returns (string memory);
    //function decimals() external view returns (uint8);
}
