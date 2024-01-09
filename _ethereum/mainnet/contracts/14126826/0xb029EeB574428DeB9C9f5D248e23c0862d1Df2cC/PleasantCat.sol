// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Mintable.sol";

contract PleasantCat is ERC721, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmdsMbsVCpWZUYYF8iXyEwVMZUsCKtYtFHeXCqBBX5YFCD/";
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }
}
