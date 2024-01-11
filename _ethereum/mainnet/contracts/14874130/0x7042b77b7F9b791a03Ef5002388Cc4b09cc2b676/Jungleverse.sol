//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Jungleverse is ERC1155, Ownable {

    constructor() ERC1155("Jungleverse") { }

    string public baseUri;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(to, id, amount, data);
    }

    function setURI(
        string memory _baseUri
    ) external onlyOwner {
        baseUri = _baseUri;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(
          abi.encodePacked(
            baseUri,
            Strings.toString(_tokenId)
          )
        );
    }
}