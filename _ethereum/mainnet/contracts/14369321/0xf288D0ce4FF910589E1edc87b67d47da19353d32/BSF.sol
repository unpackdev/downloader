// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./Ownable.sol";

contract BoredStickFigures is ERC1155, Ownable {
    string private _uri = "ipfs://";
    string public name = "Bored Stick Figures";
    
    // Mapping from token ID to IPFS hash
    //mapping(uint256 => string) private _hashes;
    string[192] private _hashes;

    constructor() ERC1155(_uri) {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // function mint(address account, uint256 id, uint256 amount, string memory data) public onlyOwner {
    //     _hashes[id] = data;
    //     _mint(account, id, amount, "");
    // }
    
    function uri(uint256 id) public view virtual override returns (string memory) {
        //return _uri;
        return string(abi.encodePacked("ipfs://", _hashes[id-1]));
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, string[192] memory hashes) public onlyOwner {
        _hashes = hashes;
        _mintBatch(to, ids, amounts, "");
    }

    function contractURI() public view returns (string memory) {
        return "QmXVdcMT1STTB39a2ZfFQEEeVz1ruFP1LG3nWRG2tn9HeE";
    }
}
