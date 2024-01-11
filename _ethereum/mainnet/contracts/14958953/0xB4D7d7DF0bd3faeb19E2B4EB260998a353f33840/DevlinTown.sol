// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract DevlinTown is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    uint256 public mintPrice = 0.005 ether;
    uint256 public maxMintPerTransaction = 5;
    uint256 public maxMintPerWallet = 10;
    uint256 public maxFreeMintPerWallet = 2;
    uint256 public maxTeamMint = 300;
    uint256 public maxSupply = 6666;
    uint256 public maxFreeSupply = 1200;
    bool public isMintActive = false;

    string private baseURI;
    bool private _teamAlreadyMinted = false;
    address private _teamAddress = 0x1C96b17C0bb7A9B3EB69a4cEdbF2674e5961931d;

    mapping(address => uint256) public walletFreeMintCount;
    mapping(address => uint256) public walletMintCount;

    constructor() ERC721A("DevlinTown.wtf", "DEVLIN") {}

    function mint(uint256 quantity) external payable nonReentrant {
        require(tx.origin == _msgSender(), "Not today, son");
        require(isMintActive, "Mint is not activated");

        uint256 totalSupplyWithQuantity = totalSupply() + quantity;

        if(_teamAlreadyMinted == false) {
            totalSupplyWithQuantity += maxTeamMint;
        }

        require(totalSupplyWithQuantity <= maxSupply, "Max supply exceeded");
        require(quantity > 0, "Cannot mint less than 1");
        require(quantity <= maxMintPerTransaction, "Exceeded per tx limit");
        require(walletMintCount[_msgSender()] + quantity <= maxMintPerWallet, "Exceeded per wallet limit");

        if(totalSupply() > maxFreeSupply) {
            uint256 requiredValue = quantity * mintPrice;
            require(msg.value >= requiredValue, "Insufficient funds");
        } else {
            uint256 senderFreeMintCount = walletFreeMintCount[_msgSender()];
            uint256 freeMintsLeft = maxFreeMintPerWallet - senderFreeMintCount;

            uint256 totalPrice = quantity * mintPrice;
            uint256 mintWorth = msg.value / mintPrice;

            int256 discountNeeded = int256(quantity) - int256(mintWorth);

            require(discountNeeded <= int256(freeMintsLeft) , "Insufficient funds");

            if (freeMintsLeft > 0 && discountNeeded > 0) {
                if (discountNeeded > int256(freeMintsLeft)) {
                    uint256 requiredValue = totalPrice - uint256(discountNeeded) * mintPrice;
                    require(msg.value >= requiredValue, "Insufficient funds");
                }

                require(totalSupply() + uint256(discountNeeded) <= maxFreeSupply, "Max free supply exceeded");

                walletFreeMintCount[_msgSender()] += uint256(discountNeeded);
            }
        }

        walletMintCount[_msgSender()] += quantity;
        _safeMint(_msgSender(), quantity);
    }

    function freeMint() external nonReentrant {
        require(tx.origin == _msgSender(), "Not today, son");
        require(isMintActive, "Mint is not activated");

        uint256 quantity = maxFreeMintPerWallet - walletFreeMintCount[_msgSender()];
        require(quantity > 0, "Wallet free mints already claimed");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(totalSupply() + quantity <= maxFreeSupply, "Max free supply exceeded");
        require(walletMintCount[_msgSender()] + quantity <= maxMintPerWallet, "Exceeded per wallet limit");

        walletFreeMintCount[_msgSender()] += quantity;
        walletMintCount[_msgSender()] += quantity;

        _safeMint(_msgSender(), quantity);
    }

    function teamMint() external onlyOwner nonReentrant {
        require(isMintActive, "Mint is not activated");
        require(_teamAlreadyMinted == false, "Already claimed");

        _teamAlreadyMinted = true;

        walletMintCount[_teamAddress] += maxTeamMint;
        _safeMint(_teamAddress, maxTeamMint);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function flipMintActiveState() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = owner().call{ value: address(this).balance }('');
        require(success, 'Withdraw failed');
    }
}