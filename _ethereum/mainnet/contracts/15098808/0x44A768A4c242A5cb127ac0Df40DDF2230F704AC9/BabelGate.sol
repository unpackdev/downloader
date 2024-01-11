pragma solidity ^0.8.0;

import "./console.sol"; //SPDX-License-Identifier: Unlicense
import "./ERC721PresetMinterPauserAutoId.sol";

contract BabelGate is ERC721PresetMinterPauserAutoId {
    using Counters for Counters.Counter;
    uint256 private price;
    Counters.Counter private _tokenIdTracker;
    string private _baseuri;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 _price
    ) public ERC721PresetMinterPauserAutoId(name_, symbol_, uri_) {
        _baseuri = uri_;
        price = _price;
    }

    function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
        address payable o = payable(msg.sender);
        o.transfer(address(this).balance);
    }

    function buyOne() public payable {
        require(msg.value >= price, "No enough ether to buy");
        address payable to = payable(msg.sender);
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function setPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
    }

    function setBaseURI(string memory uri_) public {
        _baseuri = uri_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_baseuri, Strings.toString(tokenId), ".json")
            );
    }
}
