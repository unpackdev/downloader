// SPDX-License-Identifier: MIT

//    _____                  _        _    _                 _
//   / ____|                | |      | |  | |               | |
//  | |     _ __ _   _ _ __ | |_ ___ | |__| | ___   ___   __| |
//  | |    | '__| | | | '_ \| __/ _ \|  __  |/ _ \ / _ \ / _` |
//  | |____| |  | |_| | |_) | || (_) | |  | | (_) | (_) | (_| |
//   \_____|_|   \__, | .__/ \__\___/|_|  |_|\___/ \___/ \__,_|
//                __/ | |
//               |___/|_|

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";

contract NftContract is ERC721A, ReentrancyGuard, Ownable {
    string baseURI = "";
    uint256 public MAX_SUPPLY = 3000;
    uint256 public MINT_PRICE = 0.04 ether;
    uint256 public MAX_MINT_AMOUNT = 5;
    uint256 public MAX_PER_ADDRESS = 5;
    bool public PAUSED = true;

    error ContractOnPause();
    error MaxSupplyExceeded();
    error MaxMintAmountExceeded();
    error MaxMintPerAddressExceeded();
    error IncorrectTransferAmount();
    error TransferFailed();

    constructor() ERC721A("CryptoHood Club", "CHC") {}

    function mint(uint256 amount) external payable nonReentrant {
        uint256 supply = totalSupply();
        if (supply + amount > MAX_SUPPLY) revert MaxSupplyExceeded();

        if (_msgSender() != owner()) {
            if (PAUSED) revert ContractOnPause();
            if (amount > MAX_MINT_AMOUNT) revert MaxMintAmountExceeded();
            if (_numberMinted(_msgSender()) + amount > MAX_PER_ADDRESS)
                revert MaxMintPerAddressExceeded();
            if (msg.value != MINT_PRICE * amount)
                revert IncorrectTransferAmount();
        }
        _safeMint(_msgSender(), amount);
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        MAX_MINT_AMOUNT = _newMaxMintAmount;
    }

    function setMaxPerAddress(uint256 _newMaxPerAddress) public onlyOwner {
        MAX_PER_ADDRESS = _newMaxPerAddress;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        MINT_PRICE = _newMintPrice;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function togglePause() public onlyOwner {
        PAUSED = !PAUSED;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    //internal function for base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //set the base URI on IPFS
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}
