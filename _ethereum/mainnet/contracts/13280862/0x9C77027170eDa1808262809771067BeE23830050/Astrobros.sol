// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";

import "./Mintable.sol";

contract Astrobros is ERC721, Ownable, Mintable {
    string private _currentBaseURI;
    address public _owner;

    constructor(address _imx)
        ERC721("Astrobros", "ABROS")
        Mintable(msg.sender, _imx)
    {
        setBaseURI("https://api.astrobros-nft.com/bros/data/os/");
        _owner = msg.sender;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_owner).transfer(balance);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }
}
