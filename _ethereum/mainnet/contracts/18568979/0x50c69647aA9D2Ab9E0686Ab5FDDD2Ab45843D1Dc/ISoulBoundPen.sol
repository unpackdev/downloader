//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISoulBoundPen {
    function mint(uint256 id_) external;
    function upgrade(uint256 next_) external;
    function getId(address account_) external view returns(uint256);
    function batchMint(address[] memory accounts, uint256 id_) external;


    event minted(address sender_, uint256 id_);
    

    event upgraded(address sender_, uint256 now_, uint256 next_);


    event batchMinted(address[] accounts, uint256 id_);
}
