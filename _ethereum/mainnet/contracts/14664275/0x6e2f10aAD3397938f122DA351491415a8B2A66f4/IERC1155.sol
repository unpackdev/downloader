// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC1155 is IERC165 {
    function initializeToken(
        address _creator,
        uint256 _maxIssuance,
        string memory _tokenURI
    ) external returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external returns (bool);

    function maxIssuance(uint256 tokenId) external view returns (uint256);

    function totalSupply(uint256 id) external view returns (uint256);
}
