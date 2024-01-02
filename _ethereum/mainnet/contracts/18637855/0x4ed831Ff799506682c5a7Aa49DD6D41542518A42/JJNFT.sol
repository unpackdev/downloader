// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";

contract JJNFT is ERC721, Ownable {
    uint public immutable MAX_SUPPLY;
    bool private _minted = false;

    string public baseURI;
    string private _contractURI;

    constructor(
        uint _maxSupply,
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) ERC721("Vysochin Estate", "JJNFT0001") {
        MAX_SUPPLY = _maxSupply;
        baseURI = _initialBaseURI;
        _contractURI = _initialContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function totalSupply() public view returns (uint) {
        return _minted ? MAX_SUPPLY : 0;
    }

    function mintNFTs(address to) public onlyOwner {
        require(_minted == false, "Already minted");

        for (uint i = 0; i < MAX_SUPPLY; i++) {
            _safeMint(to, i + 1);
        }
        _minted = true;
    }

    function tokensByAddress(
        address _address
    ) public view returns (uint[] memory) {
        uint balance = balanceOf(_address);
        if (balance == 0) {
            return new uint[](0);
        }
        uint[] memory tokens = new uint[](balance);
        uint index = 0;
        for (uint i = 1; i <= MAX_SUPPLY; i++) {
            if (ownerOf(i) == _address) {
                tokens[index] = i;
                index++;
                if (index > balance) {
                    break;
                }
            }
        }
        return tokens;
    }
}
