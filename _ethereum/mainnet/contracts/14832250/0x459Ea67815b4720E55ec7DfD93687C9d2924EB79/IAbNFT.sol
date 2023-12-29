// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

// OpenZeppelin
import "./IERC721Enumerable.sol";

/**************************************

    Minter interface

 **************************************/

interface IAbNFT is IERC721Enumerable {

    // external functions
    function mint(uint256[] calldata _nftIds, address _owner) external;
    function reveal(uint256 _range, string memory _revealedURI, uint256 _toClaim) external;
    function vestedClaim(uint256[] calldata _nftIds, address _owner) external;

}
