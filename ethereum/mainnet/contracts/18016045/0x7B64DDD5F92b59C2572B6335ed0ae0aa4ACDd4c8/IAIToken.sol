// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC721A.sol";

interface IAIToken is IERC721A {
    function mint(address _account, uint256 _quantity) external;

    function burn(uint256[] memory _tokenIds) external;
}
