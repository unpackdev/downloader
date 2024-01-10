// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721EnumerableLite.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract InvisibleFoes is ERC721EnumerableLite, Ownable {
    using Strings for uint;

    uint public PRICE = 0.03666 ether;
    uint public MAX_SUPPLY = 6666;

    string public _baseTokenURI = "ipfs://QmZEgGp7XXy9Jxa3b35Y4Q2pzQkEt4wYDJ6zMfWcscQDs8?";

    bool public paused = true;
    bool public enablePaid = true;

    mapping(address => uint256) private freeMints;

    constructor() ERC721B("Invisible Foes", "INVFOES") {
        uint supply = totalSupply();

        for(uint i = 0; i < 100; ++i){
            _mint( msg.sender, supply + i );
        }
    }

    function mint(uint _count) external payable {
        require( !paused, "Minting paused" );

        uint supply = totalSupply();
        require( supply + _count <= MAX_SUPPLY, "Exceeds max supply" );

        if (supply + _count > 600 && enablePaid) {
            require( _count < 11, "Max is 10 per transaction" );
            require( msg.value >= PRICE * _count, "Ether sent is not correct" );
        } else {
        require(
            freeMints[ msg.sender ] + _count < 6,
            "Max free is 5 per wallet"
        );
            freeMints[ msg.sender ] += _count;
        }

        for(uint i = 0; i < _count; ++i){
            _mint( msg.sender, supply + i );
        }
    }

    function pause(bool _updatePaused) public onlyOwner {
        paused = _updatePaused;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function paidMint(bool _updateState) public onlyOwner {
        enablePaid = _updateState;
    }

    function tokenURI(uint _tokenId) external override view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function withdraw() public onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "Withdraw unsuccessful"
        );
    }
}