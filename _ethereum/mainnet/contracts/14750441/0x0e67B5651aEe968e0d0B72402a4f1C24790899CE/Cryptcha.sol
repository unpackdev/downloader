// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Cryptcha is ERC721A, Ownable {
    uint256 private constant CLOSED_SALE = 0;
    uint256 private constant PUBLIC_SALE = 1;

    uint256 public saleState = CLOSED_SALE;

    address payable private _wallet;
    address payable private _devWallet;

    uint256 public maxSupply;
    bool public maxSupplyLocked;
    uint256 public publicMintPrice;

    // basis of 100
    uint256 private _devShare;
    string baseURI = "ipfs://";

    constructor(
        address payable wallet,
        address payable devWallet,
        uint256 initialMaxSupply,
        uint256 initialPublicMintPrice,
        uint256 devShare
    ) ERC721A("Cryptcha", "CRYPTCHA") {
        _wallet = wallet;
        _devWallet = devWallet;
        maxSupply = initialMaxSupply;
        publicMintPrice = initialPublicMintPrice;

        _devShare = devShare;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(uint256 count) external payable {
        require(saleState == PUBLIC_SALE, "Cryptcha: sale is closed");
        require(totalSupply() + count <= maxSupply, "Cryptcha: none left");
        require(count <= 5, "Cryptcha: Cannot mint more than 5 tokens at once");

        _mintFromPublicSale(count);
    }

    function devMint(address to, uint256 count) public payable onlyOwner {
        require(totalSupply() + count <= maxSupply, "Cryptcha: none left");
        _safeMint(to, count);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function lockMaxSupply() public onlyOwner {
        maxSupplyLocked = true;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(
            !maxSupplyLocked,
            "Cryptcha: cannot change max supply, it is locked"
        );
        require(
            newMaxSupply >= _totalMinted(),
            "Cryptcha: cannot set max supply less than current minted supply"
        );
        maxSupply = newMaxSupply;
    }

    function setPublicMintPrice(uint256 newPrice) public onlyOwner {
        publicMintPrice = newPrice;
    }

    function _mintFromPublicSale(uint256 count) internal {
        require(
            msg.value >= publicMintPrice * count,
            "Cryptcha: not enough funds sent"
        );
        _safeMint(msg.sender, count);
    }

    function setSaleState(uint256 nextSaleState) public onlyOwner {
        require(
            nextSaleState >= 0 && nextSaleState <= 2,
            "Cryptcha: sale state out of range"
        );
        saleState = nextSaleState;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 devPayment = (balance * _devShare) / 100;
        uint256 remainder = balance - devPayment;

        (bool success, ) = _devWallet.call{value: devPayment}("");
        (bool success2, ) = _wallet.call{value: remainder}("");

        require(success && success2, "Cryptcha: withdrawl failed");
    }

    function allOwners() external view returns (address[] memory) {
        address[] memory _allOwners = new address[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i++) {
            if (_exists(i)) {
                address owner = ownerOf(i);
                _allOwners[i] = owner;
            } else {
                _allOwners[i] = address(0x0);
            }
        }

        return _allOwners;
    }

    // payable fallback
    fallback() external payable {}

    receive() external payable {}
}
