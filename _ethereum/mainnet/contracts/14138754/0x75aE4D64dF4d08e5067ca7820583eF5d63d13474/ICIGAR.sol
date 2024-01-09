// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICIGAR {
    function publicSaleMint(address to, uint256 amountInEther) external payable;

    function mint(address to, uint256 amount) external;

    function reserveToDAO(address dao) external;

    function reserveToLiquidity(address liquidityHandler) external;

    function reserveToTeam(address team) external;

    function burn(address from, uint256 amount) external;

    function addController(address controller) external;

    function removeController(address controller) external;

    function flipSaleState() external;

    function setMintPrice(uint256 _mintPrice) external;

    function setMaxMint(uint256 _maxMint) external;

    function lockControllers() external;

    function withdrawPublicSale() external;
}