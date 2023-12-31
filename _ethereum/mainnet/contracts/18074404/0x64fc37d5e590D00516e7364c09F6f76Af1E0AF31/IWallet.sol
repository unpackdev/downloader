// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWallet {
    function executeModule(bytes memory) external returns (bytes memory);

    function transferDefaultedERC721(
        address,
        uint256,
        address
    ) external;

    function transferDefaultedERC1155(
        address,
        uint256,
        uint256,
        address
    ) external;

    function transferDefaultedCryptoPunk(uint256, address) external;

    function setLockedERC721Token(
        address,
        uint256,
        bool
    ) external;

    function increaseLockedERC1155Token(
        address,
        uint256,
        uint256
    ) external;

    function decreaseLockedERC1155Token(
        address,
        uint256,
        uint256
    ) external;

    function setLockedCryptoPunk(uint256, bool) external;

    function autoPay(uint256, uint256) external;
}
