// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FrahmGenesis is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant AMOUNT_FOR_DEV = 50;
    uint256 public constant MAX_COLLECTION_SIZE = 1100;

    // Thursday, April 28, 2022 4:00:00 PM GMT+02:00 DST
    uint32 public constant MINTLIST_SALE_START_TIME = 1651154400;
    // Friday, April 29, 2022 4:00:00 PM GMT+02:00 DST
    uint32 public constant PUBLIC_SALE_START_TIME = 1651240800;
    // Saturday, April 30, 2022 4:00:00 PM GMT+02:00 DST
    uint32 public constant BURN_START_TIME = 1651327200;

    uint256 public constant MAX_MINTLIST_MINTS = 2;
    uint256 public constant MAX_PUBLIC_MINTS_PER_TX = 10;
    uint256 public constant MINT_PRICE = 0.12 ether;

    constructor() ERC721A("Frahm Genesis", "FRAHMG") {}

    mapping(address => uint256) public mintlist;

    string private _baseTokenURI = 'https://api.frahm.art/genesis/metadata/';

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function frahmMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= AMOUNT_FOR_DEV,
            "too many already minted before frahm mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function seedMintlist(address[] memory addresses) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            mintlist[addresses[i]] = MAX_MINTLIST_MINTS;
        }
    }

    function mintlistMint(uint256 quantity) external payable callerIsUser {
        require(quantity <= MAX_MINTLIST_MINTS, "can only mint 1 or 2 in mintlist sale");
        require(block.timestamp >= MINTLIST_SALE_START_TIME, "mintlist sale has not begun yet");
        require(block.timestamp < PUBLIC_SALE_START_TIME, "mintlist sale is over");
        require(mintlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + quantity <= MAX_COLLECTION_SIZE, "reached max supply");
        mintlist[msg.sender] = MAX_MINTLIST_MINTS - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(MINT_PRICE * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(quantity <= MAX_PUBLIC_MINTS_PER_TX, "can only mint 10 per tx in public sale");
        require(block.timestamp >= PUBLIC_SALE_START_TIME, "public sale has not begun yet");
        require(totalSupply() + quantity <= getAvailableSupply(), "reached max supply");
        _safeMint(msg.sender, quantity);
        refundIfOver(MINT_PRICE * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "need to send more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function getAvailableSupply() public view returns (uint256) {
        uint256 supplyLeft = MAX_COLLECTION_SIZE - totalSupply();

        // Pre burn
        if (block.timestamp < BURN_START_TIME) {
            return supplyLeft;
        }

        uint256 timeElapsed = block.timestamp - BURN_START_TIME;

        uint256 burnAmount = supplyLeft * timeElapsed / 48 hours;

        if (burnAmount > supplyLeft) {
            return 0;
        } else {
            return supplyLeft - burnAmount;
        }
    }
}