// SPDX-License-Identifier: MIT
pragma solidity^0.8.12;

import "./ERC1155.sol";


contract Titan is ERC1155 {
    address public owner;
    address public airdrop_address;
    string public name;

    event token_revealed(string _uri);
    event token_minted(address _user, uint256 _id);
    constructor(address _owner) ERC1155("ipfs://QmTNPqNiqqMFXHbA3gkVoCoDhMzWdA9Bz15BLSCoh2KLHM/metadata/{id}.json") {
        airdrop_address = msg.sender;
        owner = _owner;
        _setName('Titan Collection');
    }

     function _setName(string memory _name) internal {
        name = _name;
    }

    function setURI(string memory _uri) external {
        require(airdrop_address == msg.sender, "Only called by airdrop address");
        _setURI(_uri);
        emit token_revealed(_uri);
    }

    function mint(address _user, uint256 id) external {
        require(airdrop_address == msg.sender, "Only called by airdrop address");
        _mint(_user, id, 1, '');
        emit token_minted(_user, id);
    }
}