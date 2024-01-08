// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract LittleDemons is ERC721Tradable {

    uint256 private constant TOTAL_NFTS = 6666;

    string private _baseTokenURI;

    event BaseTokenURIUpdated(string newValue, string oldValue);

    enum State
    {
        Closed,
        Whitelist,
        Open
    }

    State public state;
    mapping (address => bool) public whitelist;

    event StateUpdated(State state);
/*
   * On Rinkeby: "0xF57B2c51dED3A29e6891aba85459d600256Cf317"
   * On mainnet: "0xa5409ec958C83C3f309868babACA7c86DCB077c1"
*/

    constructor() ERC721Tradable("Little Demons", "LD", 0xF57B2c51dED3A29e6891aba85459d600256Cf317) {
        setBaseTokenURI("https://littledemons.netlify.app/public/");
    }

    function addToWhitelist(address[] memory wallets) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++) {
            whitelist[wallets[i]] = true;
        }
    }

    function setState(State _state) external onlyOwner {
        state = _state;
        emit StateUpdated(state);
    }

    function price() public pure returns (uint256) {
        return 0.0666 ether;
    }

    function mint(uint256 count) public payable {
        require(state != State.Closed, "Closed");
        if(state == State.Whitelist) {
            require(whitelist[msg.sender], "Not whitelisted");
        }
        require(count <= 20, "Max 20 NFTs at once");
        require(totalSupply() + count <= TOTAL_NFTS, "Max 6666");
        require(count * price() == msg.value, "Wrong amount sent");

        for (uint i = 0; i < count; i++) {
            _mintTo(msg.sender);
        }
    }

    function baseTokenURI() public view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory value) public onlyOwner {
        emit BaseTokenURIUpdated(value, _baseTokenURI);
        _baseTokenURI = value;
    }

    function withdraw() external onlyOwner {
        (bool success,) = owner().call {value: address(this).balance } ("");
        require(success, "Error withdrawing");
    }
}
