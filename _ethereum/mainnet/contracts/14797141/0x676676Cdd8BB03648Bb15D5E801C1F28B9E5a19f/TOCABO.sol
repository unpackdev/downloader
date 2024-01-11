// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract TOCABO is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }

    Status public status;
    string private baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 10;
    uint256 public constant MAX_SUPPLY = 5666;
    uint256 public constant PRICE = 0.005 * 10**18; 
    uint256 public constant FREE_MINT_SUPPLY = 600;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("Tocabo", "TOCABO") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "TOCABO: Not started yet.");
        require(tx.origin == msg.sender, "TOCABO: Contract call not allowed.");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "TOCABO: This is more than allowed."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "TOCABO: Not enough quantity."
        );

        _safeMint(msg.sender, quantity);

        if (totalSupply() + quantity<= FREE_MINT_SUPPLY) {
            refundIfOver(0);
        } else {
        refundIfOver(PRICE * quantity);
        }

        emit Minted(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "TOCABO: Not enough ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "TOCABO: NFTs have been completely minted.");
    }
}
