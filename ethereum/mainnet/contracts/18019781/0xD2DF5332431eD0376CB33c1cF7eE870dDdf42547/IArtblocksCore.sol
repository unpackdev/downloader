// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract IArtblocksCore {
    address public minterContract;

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view virtual returns (address payable);

    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) public virtual returns (bool);

    // solhint-disable-next-line
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external virtual returns (uint256 _tokenId);
}
