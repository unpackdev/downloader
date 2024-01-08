// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./LibPart.sol";

interface IPaceArtStore {
    function singleTransfer(
        address _from,
        address _to,
        uint256 _tokenId

    ) external returns(uint);
    function mintTo(address _to, LibPart.Part memory _royalty) external returns(uint);
    function owner() external view returns (address);
}
