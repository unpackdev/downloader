//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./IEnoji.sol";

interface IEnojiSVG {
    function tokenSVG(IEnoji enoji, uint256 tokenId)
        external
        view
        returns (string memory);
}
