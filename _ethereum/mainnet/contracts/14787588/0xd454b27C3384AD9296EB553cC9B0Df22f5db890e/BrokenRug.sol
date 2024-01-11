// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract BrokenRug is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    uint256 public constant BROKEN_ROUTE_ID = 0;
    string public name = "Broken Rug";

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmUoBwt3amr8oiB8oNtpkY3WN1VqZgoF5J21oF8JjcZPLK") {
    }

    function uri(uint256 _id) override public view returns (string memory) {
        require(exists(_id), "Non existent id");
        return "https://gateway.pinata.cloud/ipfs/QmUoBwt3amr8oiB8oNtpkY3WN1VqZgoF5J21oF8JjcZPLK";
    }

    function airdrop(uint256 _tokenId, address[] calldata _addressList, uint256 _quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addressList.length; i++) {
            _mint(_addressList[i], _tokenId, _quantity, "");
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function transfer(address from, address to, uint256 id, uint256 amount, bytes memory data) 
        public 
        onlyOwner 
    {
        safeTransferFrom(from, to, id, amount, data);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}