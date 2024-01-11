// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";

//   ___   ___    ___   ___         _  __ ___  ___   ____
//  / __| / _ \  / _ \ |   \       | |/ /|_ _||   \ |_  /
// | (_ || (_) || (_) || |) |      |   <  | | | |) | / / 
//  \___| \___/  \___/ |___/       |_|\_\|___||___/ /___|
//

// Contract by @txorigin

contract GoodKidz is Ownable, ERC721A {
    uint256 public maxSupply                    = 5555;
    uint256 public maxFreeSupply                = 2500;
    
    uint256 public maxPerTxDuringMint           = 5;
    uint256 public maxPerAddressDuringFreeMint  = 3;
    
    uint256 public price                        = 0.005 ether;
    bool    public saleIsActive                 = false;

    address constant internal DEV_ADDRESS  = 0xDEADd426B0EC914b636121C5F3973F095D3Fa666;
    address constant internal TEAM_ADDRESS = 0x5e11eaBE10594d941E3826f91dbeaBF53fAec092;

    string private _baseTokenURI;

    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("Good Kidz", "GDZ") {
        _safeMint(msg.sender, 1);
    }

    modifier mintCompliance() {
        require(saleIsActive, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

    function mint(uint256 _quantity) external payable mintCompliance() {
        require(
            maxSupply >= totalSupply() + _quantity,
            "GDZ: Exceeds max supply."
        );
        require(
            _quantity > 0 && _quantity <= maxPerTxDuringMint,
            "Invalid mint amount."
        );
        _safeMint(msg.sender, _quantity);
        refundIfOver(price * _quantity);
    }

    function freeMint(uint256 _quantity) external mintCompliance() {
        require(
            maxFreeSupply >= totalSupply() + _quantity, 
            "GDZ: Exceeds max free supply."
        );
        uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
        require(
            _freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,
            "GDZ: Exceeds max free mints per address!"
        );
        freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function refundIfOver(uint256 _price) private {
        require(msg.value >= _price, "Not enough ETH sent.");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTxDuringMint = _amount;
    }

    function setMaxFreePerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringFreeMint = _amount;
    }

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function cutMaxSupply(uint256 _amount) public onlyOwner {
        require(
            maxSupply - _amount >= totalSupply(), 
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= _amount;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawBalance() external payable onlyOwner {
        uint256 _balance = address(this).balance;

        (bool success, ) = payable(DEV_ADDRESS).call{
            value: (_balance * 1900) / 10000
        }("");
        require(success, "Dev transfer failed.");

        (success, ) = payable(TEAM_ADDRESS).call{
            value: address(this).balance
        }("");
        require(success, "Team transfer failed.");
    }
}