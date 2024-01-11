// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

// 3333 total supply
// 333 totally free mints
// After this 333, 1 free mint if 2 payable per tx
// 3 mint max per wallet (free included)
contract WeAreNotAlone is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;

    uint16 public TOTAL_SUPPLY        = 3333;
    uint16 public TOTALLY_FREE_MINT   = 333;
    uint8  public MAX_FOR_TEAM        = 0;
    uint8  public MAX_PER_WALLET      = 3;
    uint8  public MAX_FREE_PER_WALLET = 1;

    uint16 public totallyFreeMinted = 0;
    uint64 public price             = 45000000000000000;
    bool   public isSaleActive      = false;

    mapping(address => bool) private freeMintByWallet;
    mapping(address => uint) private nftByWallet;

    string private baseURI;

    address[] private team = [
        0xA6F2D35D316dA15d029E6eb3d0143a38aFd5f1Bc,
        0x8B94E92FF09AE8644bBA853Fce91B1830Fac1221,
        0xEd6a65822f80BB80D3B0D794E8b1276Fc0282A83,
        0xD7664Cba12b426F54a5fFF4DF35942e0EF3a5B38,
        0x1ef54ac867B4b1112aFB7DCc48CE2e0A27A236c3
    ];

    uint[] private teamShare = [
        50,
        15,
        15,
        15,
        5
    ];

    constructor() ERC721A("We Are Not Alone", "WANA") PaymentSplitter(team, teamShare) {}

    function mint(uint _quantity) external payable {
        require(isSaleActive, "Sale is not active");
        require(msg.sender == tx.origin);
        require(totalMinted() + _quantity < TOTAL_SUPPLY + 1, "Max supply exceeded");

        if (nftByWallet[msg.sender] > 0) {
            nftByWallet[msg.sender] += _quantity;
        } else {
            nftByWallet[msg.sender] = _quantity;
        }
        require(nftByWallet[msg.sender] < MAX_PER_WALLET + 1, "3 NFTs max per wallet");

        // If totally free mint still active AND sender has not free minted
        if (totallyFreeMinted < TOTALLY_FREE_MINT && !freeMintByWallet[msg.sender]) {
            require(msg.value >= price * (_quantity - 1), "Insufficient funds");

            if (msg.value <= price * _quantity) {
                totallyFreeMinted++;
                freeMintByWallet[msg.sender] = true;
            }
        } else {
            if (!freeMintByWallet[msg.sender] && _quantity == MAX_PER_WALLET) {
                require(msg.value >= price * (_quantity - 1), "Insufficient funds");
                freeMintByWallet[msg.sender] = true;
            } else {
                require(msg.value >= _quantity * price, "Insufficient funds");
            }
        }

        _safeMint(msg.sender, _quantity);
    }

    function hasFreeMint(address _address) public view returns(bool) {
        return freeMintByWallet[_address] ? true : false;
    }

    function nftMintedByWallet(address _address) public view returns(uint) {
        return nftByWallet[_address] > 0 ? nftByWallet[_address] : 0;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function setPrice(uint64 _price) public onlyOwner {
        price = _price;
    }

    function setSupply(uint16 _supply) public onlyOwner {
        require(totalMinted() < TOTAL_SUPPLY, "Sold out!");
        TOTAL_SUPPLY = _supply;
    }
}
