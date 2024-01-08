// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Tradable.sol";

contract CuddleeCrew is ERC1155Tradable  {
    constructor(address _proxyRegistryAddress)
    public
    ERC1155Tradable("Cuddlee Crew", "CC","https://cdn.ecuras.com/img/nft/cats/metadata/",_proxyRegistryAddress)
    {}

    function contractURI() public view returns (string memory) {
        return
        "https://cdn.ecuras.com/img/nft/cats/info.json";
    }
}
