// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import "./IERC721.sol";

interface IEqzYieldNft is IERC721 {
    function mint(address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    event BaseURIEvent(string _baseURI);
}
