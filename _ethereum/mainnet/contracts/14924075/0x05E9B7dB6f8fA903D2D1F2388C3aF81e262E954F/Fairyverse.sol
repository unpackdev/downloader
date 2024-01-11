// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";

/*
DEGEN MINT TLDR;
CALL mintPublic WITH A QUANTITY OF 0 AND VALUE OF 0 FOR JUST FREE MINT
OTHERWISE ANY QUANTITY LESS THAN OR EQUAL TO 10 AND VALUE OF .005 * THAT QUANTITY, FREE MINT WILL BE ADDED ON TOP
*/

contract Fairyverse is ERC721A , Ownable{
    string public constant AREAD_ME =
        "CALL mintPublic WITH A QUANTITY OF 0 AND VALUE OF 0 FOR JUST FREE MINT. OTHERWISE ANY QUANTITY LESS THAN OR EQUAL TO 10 AND VALUE OF .005 * THAT QUANTITY, FREE MINT WILL BE ADDED ON TOP";
    uint256 public constant RESERVED_SUPPLY = 1;
    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant MAX_PER_WALLET = 10;

    constructor() ERC721A("Fairyverse", "FYV") {}

    /**
     * Public sale mechanism
     */
    bool public publicSale = false;
    uint256 public freeRedeemed = 0;
    uint256 public  MINT_PRICE = .005 ether;
    uint256 public  FREE_SUPPLY = 2000;

    bool public reserved = false;

    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    function increaseFreeSupply(uint256 amount) external onlyOwner {
        require(amount > FREE_SUPPLY);
        FREE_SUPPLY = amount;
    }
    function decreasePrice(uint256 price) external onlyOwner {
        require(price < MINT_PRICE);
        MINT_PRICE = price;
    }

    /**
     * Public minting
     */
    mapping(address => uint256) public publicAddressMintCount;
    mapping(address => bool) public FreeClaimed;

    function mintPublic(uint256 _quantity) public payable {
        require(msg.sender == tx.origin);
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        require(
            publicAddressMintCount[msg.sender] + _quantity <= MAX_PER_WALLET,
            "Surpasses max per wallet"
        );
        require(publicSale, "Public sale not started");
        require(msg.value == (_quantity) * MINT_PRICE);

        publicAddressMintCount[msg.sender] += _quantity;

        if (freeRedeemed < FREE_SUPPLY && !FreeClaimed[msg.sender]) {
            _quantity += 1;
            freeRedeemed += 1;
            FreeClaimed[msg.sender] = true;
        }
        require(_quantity > 0, "Free mint sold out");
        _safeMint(msg.sender, _quantity);
    }

    function reserve() public onlyOwner {
        require(!reserved);
        reserved = true;
        _safeMint(msg.sender, RESERVED_SUPPLY);
    }

    /**
     * Base URI
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdrawal
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}
