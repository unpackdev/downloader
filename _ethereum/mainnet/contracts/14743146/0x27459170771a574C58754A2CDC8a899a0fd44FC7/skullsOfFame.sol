// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";


contract SkullsOfFame is ERC721A, Ownable {
    string public baseURI;
    address public withdrawalWallet;

    constructor(string memory name, string memory symbol, string memory _baseUri) ERC721A(name, symbol) {
        baseURI = _baseUri;
    }

    function setWithdrawalWallet(address _withdrawalWallet) public onlyOwner {
        withdrawalWallet = _withdrawalWallet;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        require(payable(withdrawalWallet).send(amount));
    }

    function withdraw() public onlyOwner {
        require(payable(withdrawalWallet).send(address(this).balance));
    }

    function reserveMint(uint256 reservedAmount) public onlyOwner {
        _safeMint(msg.sender, reservedAmount);
    }

    function mintToAddress(uint256 reservedAmount, address mintAddress) public onlyOwner {
        _safeMint(mintAddress, reservedAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}
