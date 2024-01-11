// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./ECDSA.sol";


contract UASISCorp is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    string public constant name = "UASIS CORP";
    string public constant symbol = "UASIS";

    address public signAddress;

    constructor(
        string memory newURI,
        address _signAddress
    ) ERC1155(newURI) {
        signAddress = _signAddress;
    }

    function mint(uint256 price, uint256 tokenId, uint256 amount, bytes memory _signature) public payable {
        require(
            msg.value == price * amount,
            "Ether value sent is not correct"
        );

        require(
            signatureWallet(msg.sender, price, tokenId, amount, _signature) == signAddress,
            "Not authorized to mint"
        );

        _mint(msg.sender, tokenId, amount, "");
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function signatureWallet(address wallet, uint256 price, uint256 tokenId, uint256 amount, bytes memory _signature) public pure returns (address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(wallet, price, tokenId, amount))
            ), _signature
        );
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
