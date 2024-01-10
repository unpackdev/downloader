// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Mintable.sol";

/*
   ________  __
  / __/ /\ \/ /
 _\ \/ /__\  /
/___/____//_/__  __   ____
 | | /| / / __ \/ /  / __/
 | |/ |/ / /_/ / /__/ _/
 |__/|__/\____/____/_/_  _______
  / _ \/ _ |/ ___/  _/ |/ / ___/
 / , _/ __ / /___/ //    / (_ /
/_/|_/_/_|_\___/___/_/|_/\___/
 / ___/ /  / / / / _ )
/ /__/ /__/ /_/ / _  |
\___/____/\____/____/

*/

contract SlyWolfRacingClubIMX is Mintable, ERC721 {
    string private _baseURIPath;

    constructor(address _owner, address _imx)
        ERC721("SlyWolfRacingClubIMX", "SWRCX")
        Mintable(_owner, _imx) {}

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIPath = baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPath;
    }

    function _mintFor(address to, uint256 id, bytes memory) internal override {
        _safeMint(to, id);
    }
}