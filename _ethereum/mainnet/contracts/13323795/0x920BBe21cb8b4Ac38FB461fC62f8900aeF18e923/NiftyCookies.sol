// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

//  __    _  ___   _______  _______  __   __  _______  _______  _______  ___   _  ___   _______  _______ 
// |  |  | ||   | |       ||       ||  | |  ||       ||       ||       ||   | | ||   | |       ||       |
// |   |_| ||   | |    ___||_     _||  |_|  ||       ||   _   ||   _   ||   |_| ||   | |    ___||  _____|
// |       ||   | |   |___   |   |  |       ||       ||  | |  ||  | |  ||      _||   | |   |___ | |_____ 
// |  _    ||   | |    ___|  |   |  |_     _||      _||  |_|  ||  |_|  ||     |_ |   | |    ___||_____  |
// | | |   ||   | |   |      |   |    |   |  |     |_ |       ||       ||    _  ||   | |   |___  _____| |
// |_|  |__||___| |___|      |___|    |___|  |_______||_______||_______||___| |_||___| |_______||_______|

contract NiftyCookies is ERC1155, Ownable {
    using Strings for uint256;
    
    string private baseURI;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }
    
    function mint(uint256 id, uint256 amount) external onlyOwner {
        _mint(msg.sender, id, amount, "");
    }
    
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    
    function uri(uint256 typeId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, typeId.toString())) : baseURI;
    }
}