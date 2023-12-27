// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";

interface IFancyBears is IERC721, IERC721Enumerable {

    function tokensInWallet(address _owner) external view returns(uint256[] memory);

}