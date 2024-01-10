// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721A.sol";

contract SuperKevins is ERC721A, Ownable {
    uint256 public constant PRICE = 0.0333 ether;

    bool public publicSale = false;
    uint256 public maxSupply = 333;
    string private baseURI;

    IERC721 public immutable kevinMferContract;
    mapping(address => bool) public kevinMferMinted;

    bool public unrestrictedSale = false;

    constructor(IERC721 _kevinMferContract) ERC721A("Super Kevins", "SUPERKEVIN") {
        kevinMferContract = _kevinMferContract;
    }

    // public sale
    modifier publicSaleOpen() {
        require(publicSale, "Public Sale Not Started");
        _;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleUnrestrictedSale() external onlyOwner {
        unrestrictedSale = !unrestrictedSale;
    }

    // public mint
    modifier insideLimits(uint256 _quantity) {
        require(totalSupply() + _quantity <= maxSupply, "Hit Limit");
        _;
    }

    modifier hasValue() {
        require(msg.value >= PRICE, "Not Enough Funds");
        _;
    }

    function mint()
        public
        payable
        publicSaleOpen
        hasValue()
        insideLimits(1)
    {
        if (!unrestrictedSale) {
            // snapshot verification not worth the time and gas
            require(kevinMferContract.balanceOf(msg.sender) > 0, "Not A Kevin Mfer Owner");
            require(!kevinMferMinted[msg.sender], "Already Minted");
            kevinMferMinted[msg.sender] = true;
        }
        _safeMint(msg.sender, 1);
    }

    // admin mint
    function adminMint(address _recipient, uint256 _quantity)
        public
        onlyOwner
        insideLimits(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    // lock total mintable supply forever
    function decreaseTotalSupply(uint256 _total) public onlyOwner {
        require(_total <= maxSupply, "Over Current Max");
        require(_total >= totalSupply(), "Must Be Over Total");
        maxSupply = _total;
    }

    // base uri
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // payout
    address private constant payoutAddress1 =
        0x169F86544558aC4a1a6d90CE2F2a75F9c860A9C9;
    address private constant payoutAddress2 =
        0x43926Fb9676c91412Ba9A7e68ebD70cA080C8Ac4;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 50) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 50) / 100);
    }
}
