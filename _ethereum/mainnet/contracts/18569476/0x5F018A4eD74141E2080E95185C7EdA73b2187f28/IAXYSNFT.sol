// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAXYSNFT {
     function lazyMint(
        address _to,
        bytes32 _randomString,
        string memory _uri,
        uint256 _price
    ) external;

    function preMintNft(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) external;

    function mintNftByAdmins(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) external;

}
