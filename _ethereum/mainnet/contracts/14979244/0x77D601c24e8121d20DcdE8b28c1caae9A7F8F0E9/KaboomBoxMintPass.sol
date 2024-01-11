// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract KaboomBoxMintPass is ERC1155Supply, ERC1155Burnable, Ownable {
    
    string private _contractURI;
    string private _metadataURI;
    address private _minter;
    string private _name;
    string private _symbol;

    uint public supply = 777;
    uint public minted = 0;

    constructor(address minter_) 
        ERC1155("") {
        _minter = minter_;
        _name = "Kaboom Box Mint Pass";
        _symbol = "KABOOM";
    }

    function mint(address addr, uint quantity) public {
        require(msg.sender == _minter, "Invalid minter");
        if(minted + quantity <= supply) {
            _mint(addr, 0, quantity, "");
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setMetadataURI(string memory uri_) external onlyOwner {
        _metadataURI = uri_;
    }
    
    function setMinter(address addr) external onlyOwner {
        _minter = addr;
    }

    function setContractURI(string memory uri_) external onlyOwner {
        _contractURI = uri_;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "Token does not exist.");
        return _metadataURI;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}