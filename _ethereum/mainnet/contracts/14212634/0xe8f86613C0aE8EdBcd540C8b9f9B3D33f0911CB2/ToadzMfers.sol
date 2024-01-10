// SPDX-License-Identifier: UNLICENSED

/*

╔╦╗┌─┐┌─┐┌┬┐┌─┐  ╔╦╗┌─┐┌─┐┬─┐┌─┐
 ║ │ │├─┤ ││┌─┘  ║║║├┤ ├┤ ├┬┘└─┐
 ╩ └─┘┴ ┴─┴┘└─┘  ╩ ╩└  └─┘┴└─└─┘                                                                                                          

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ToadzMfers is ERC721A, Ownable {
    bool public saleEnabled = false;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public maxTXN = 20;

    uint256 public constant FREE_SUPPLY = 3333;
    uint256 public constant PAID_SUPPLY = 2222;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY+PAID_SUPPLY;

    constructor() ERC721A("Toadz Mfers", "Tmfers", maxTXN) {
        price = 0.01 ether;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSale() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        maxTXN = _maxTxn;
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

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 num) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + num <= MAX_SUPPLY, "Exceed max supply");
        require(num > 0, "Must mint at least 1 token");
        require(
            (price * num) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, num);
    }

    function freeMint(uint256 num) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + num <= FREE_SUPPLY, "Exceed max supply");
        require(num > 0, "Must mint at least 1 token");

        _safeMint(msg.sender, num);
    }
}