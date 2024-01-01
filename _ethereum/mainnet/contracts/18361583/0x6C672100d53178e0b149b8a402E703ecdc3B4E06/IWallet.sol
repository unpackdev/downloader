// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./ISeaport.sol";

interface IWallet {
    function executeModule(bytes memory) external returns (bytes memory);

    function transferNonLockedERC721(
        address,
        uint256,
        address
    ) external;

    function transferNonLockedERC1155(
        address,
        uint256,
        uint256,
        address
    ) external;

    function transferNonLockedCryptoPunk(uint256, address) external;

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

    function earlyUnwind(
        uint256,
        address,
        uint256,
        ISeaport.OfferData memory
    ) external;

    function isLockedNFT(address, uint256) external view returns (bool);
}
