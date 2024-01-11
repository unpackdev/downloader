//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IGiftContract {
    event Gift(address indexed to, uint8 tierIndex, uint256 quantity);
    event UpdateGiftLimit(
        address indexed operator,
        uint8 tierIndex,
        uint256 limit
    );
    event UpdateGiftReserves(address operator, uint16[] reserves);

    event GiftToAll(address[] receivers, uint256[] tokenQuantities);
    event GiftEx(address receiver, uint256[] tokenQuantities);

    event Submit(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint8 tierIndex,
        uint256 amount,
        bytes data
    );
    event SubmitAndConfirm(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint8 tierIndex,
        uint256 amount,
        bytes data
    );
    event Confirm(address indexed owner, uint256 indexed txIndex);
    event ConfirmAndExecute(address indexed owner, uint256 indexed txIndex);

    event Revoke(address indexed owner, uint256 indexed txIndex);
    event Execute(address indexed owner, uint256 indexed txIndex);

    function totalSupply(uint8 tierIndex) external view returns (uint256);

    function getNftToken() external view returns (address);

    function getTokenPool() external view returns (address);

    function balanceOf(address user, uint8 tierIndex)
        external
        view
        returns (uint256);
}
