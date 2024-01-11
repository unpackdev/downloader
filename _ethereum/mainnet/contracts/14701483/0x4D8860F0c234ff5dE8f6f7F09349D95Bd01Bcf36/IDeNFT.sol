// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721Upgradeable.sol";
import "./IERC4494.sol";

interface IDeNFT is IERC721Upgradeable, IERC4494 {
    /// @dev Issues a new object
    /// @param _to new Token's owner
    /// @param _tokenId new Token's id
    /// @param _tokenUri new Token's id
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenUri
    ) external;

    /// @dev Destroys the existing object
    /// @param _tokenId Id of token
    function burn(uint256 _tokenId) external;
}
