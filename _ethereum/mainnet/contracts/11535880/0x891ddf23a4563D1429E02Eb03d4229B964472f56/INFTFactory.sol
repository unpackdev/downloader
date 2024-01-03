// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./NFT.sol";
import "./INFT.sol";

interface INFTFactory {
    function deployNFT(
        string memory name,
        string memory symbol,
        string memory tokenURI
    ) external returns (NFT newContract);

    function mint(
        INFT _nft,
        address recipient,
        uint256 _randomness
    ) external;

    function bondContract(address addr) external returns (bool);

    function balanceOf(INFT _nft, address _of) external returns (uint256);

    function burn(INFT _nft, uint256 _tokenId) external;
}
