// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721Enumerable.sol";

interface IAnftifyNFT is IERC721Enumerable {
    function mint(uint256 amount, address account) external;
    function setContractURI(string memory _contractURI) external;
    function setBaseURI(string memory _baseTokenURI) external;
    function setPause(bool _pause) external;
}