// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./IERC721.sol";
import "./IERC721Core.sol";

interface IMintableERC721 is IERC721Core {

    function mint(address _to, uint _num) external;

}

