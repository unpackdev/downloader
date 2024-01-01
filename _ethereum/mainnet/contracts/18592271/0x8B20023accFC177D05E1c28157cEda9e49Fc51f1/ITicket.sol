// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITicket {
    function mint(address to, uint256 tokenId, uint256 amount) external;

    function burn(uint256 tokenId) external;

    function use(address user, uint256 tokenId, uint256 expires) external;

    function recover(address user, uint256 tokenId) external;

    function frozeOf(uint256 id) external view returns (bool);

    function ticketCount(address user) external view returns (uint256);

    function freeze(uint256 tokenId, address from) external;

    function unfreeze(uint256 tokenId) external;

    function setVault(address _cds) external;

    function setMiner(address _miner) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}
