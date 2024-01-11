// SPDX-License-Identifier: UNLICENSED

/*


░██████╗░░█████╗░██╗░░░░░░█████╗░██╗░░██╗██╗░░░██╗  ░██████╗░░█████╗░██████╗░░██████╗
██╔════╝░██╔══██╗██║░░░░░██╔══██╗╚██╗██╔╝╚██╗░██╔╝  ██╔════╝░██╔══██╗██╔══██╗██╔════╝
██║░░██╗░███████║██║░░░░░███████║░╚███╔╝░░╚████╔╝░  ██║░░██╗░██║░░██║██║░░██║╚█████╗░
██║░░╚██╗██╔══██║██║░░░░░██╔══██║░██╔██╗░░░╚██╔╝░░  ██║░░╚██╗██║░░██║██║░░██║░╚═══██╗
╚██████╔╝██║░░██║███████╗██║░░██║██╔╝╚██╗░░░██║░░░  ╚██████╔╝╚█████╔╝██████╔╝██████╔╝
░╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ░╚═════╝░░╚════╝░╚═════╝░╚═════╝░
...                                                                                                           

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GalaxyGods is ERC721A, Ownable {
    bool public sale_active;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public max_txn = 10;
    uint256 public max_txn_free = 3;
    uint256 public constant free_supply = 1000;
    uint256 public constant paid_supply = 1500;
    uint256 public constant maxSupply = free_supply+paid_supply;

    constructor() ERC721A("GALAXY GODS", "GGDS", max_txn) {
        sale_active = false;
        price = 0.003 ether;
    }

    function OWNER_RESERVE(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= maxSupply, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 count) external payable {
        require(sale_active, "Sale must be active.");
        require(totalSupply() + count <= maxSupply, "Exceed max supply");
        require(count <= max_txn, "Cant mint more than 10");
        require(
            (price * count) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, count);
    }

    function mintFree(uint256 count) external payable {
        require(sale_active, "Sale must be active.");
        require(totalSupply() + count <= free_supply, "Exceed max supply");
        require(count <= max_txn_free, "Cant mint more than 3");

        _safeMint(msg.sender, count);
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        sale_active = !(sale_active);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        max_txn = _maxTxn;
    }
    function setMaxTxnFree(uint256 _maxTxnFree) external onlyOwner {
        max_txn_free = _maxTxnFree;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

}