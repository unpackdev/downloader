// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC721AUpgradeable.sol";

/*
 *
 * ██╗░░██╗██╗███╗░░██╗░█████╗░  ██████╗░░█████╗░░██████╗░██████╗
 * ██║░██╔╝██║████╗░██║██╔══██╗  ██╔══██╗██╔══██╗██╔════╝██╔════╝
 * █████═╝░██║██╔██╗██║██║░░██║  ██████╔╝███████║╚█████╗░╚█████╗░
 * ██╔═██╗░██║██║╚████║██║░░██║  ██╔═══╝░██╔══██║░╚═══██╗░╚═══██╗
 * ██║░╚██╗██║██║░╚███║╚█████╔╝  ██║░░░░░██║░░██║██████╔╝██████╔╝
 * ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚════╝░  ╚═╝░░░░░╚═╝░░╚═╝╚═════╝░╚═════╝░
 *
 * 01000111 01010011 01010110 01001100 01000111 01010011 01010110
 * 01001001 01010011 01011010 01001111 01010101 01001100 01010101
 * 01000111 01010011 01010110 01011000 01010010 01001011 01010011
 * 01010110 01001001 01010010 01001000 01000111 01001100 01011000
 * 01011010 01001101 01001101 01010110 01001000
 */

contract KINOPass is
    Initializable,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 private _totalETHBalance;

    string public baseURI;
    uint256 public maxNFTSupply;
    uint256 public totalPublicSaleMints;
    uint256 public publicSaleLimit;
    uint256 public publicSalePrice;
    bool public onPublicSale;

    event Pause();
    event UnPause();
    event SetBaseURI(string uri);
    event SetPublicSaleStatus(bool status);
    event SetPublicSaleLimit(uint256 counter);
    event SetPublicSalePrice(uint256 price);
    event PublicSale(address indexed account, uint256 amount, uint256 price);
    event Withdraw(address indexed owner, address indexed to, uint256 amount);

    receive() external payable {}

    function initialize(string memory baseURI_) public initializer {
        __ERC721A_init("KINO Pass", "KP");
        __Ownable_init();
        __Pausable_init();
        baseURI = baseURI_;
        _totalETHBalance = 0;
        maxNFTSupply = 500;
        totalPublicSaleMints = 0;
        publicSaleLimit = 3;
        publicSalePrice = 300_000_000_000_000_000; // 0.3 ETH
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _publicSaleMint(uint256 amount) internal {
        require(
            publicSalePrice * amount == msg.value,
            "KP: Your public sale payment amount does not match required presale minting amount."
        );
        require(
            amount <= publicSaleLimit,
            "KP: Your presale payment amount exceeds our presale minting amount limit."
        );
        super._safeMint(msg.sender, amount);
        _totalETHBalance += publicSalePrice * amount;
        totalPublicSaleMints += amount;
        emit PublicSale(msg.sender, amount, msg.value);
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function pause() external onlyOwner {
        _pause();
        emit Pause();
    }

    function unpause() external onlyOwner {
        _unpause();
        emit UnPause();
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
        emit SetBaseURI(uri);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        onPublicSale = status;
        emit SetPublicSaleStatus(status);
    }

    function setPublicSaleLimit(uint256 limit) external onlyOwner {
        publicSaleLimit = limit;
        emit SetPublicSaleLimit(limit);
    }

    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
        emit SetPublicSalePrice(price);
    }

    function withdrawETH(address payable to, uint256 value) external onlyOwner {
        require(to != address(0), "KP: Can't withdraw to the zero address.");
        require(
            value <= address(this).balance,
            "KP: Withdraw amount exceed the balance of this contract."
        );
        to.transfer(value);
        emit Withdraw(owner(), to, value);
    }

    function claim(uint256 amount) external payable whenNotPaused {
        require(onPublicSale, "KP: Public sale is not yet live.");
        require(
            (getTokenIdCounter() + amount) <= maxNFTSupply,
            "KP: You can't mint that amount of tokens. Exceeds max supply."
        );
        _publicSaleMint(amount);
    }

    function getTotalETHBalance() external view onlyOwner returns (uint256) {
        return _totalETHBalance;
    }

    function getTokenIdCounter() public view returns (uint256) {
        return totalPublicSaleMints;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId_.toString(), ".json")
                )
                : "";
    }
}
