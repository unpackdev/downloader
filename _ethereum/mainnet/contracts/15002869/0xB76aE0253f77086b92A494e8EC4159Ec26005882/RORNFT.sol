// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";

contract RugOrRich is ERC721A, Ownable {

    constructor() ERC721A("Rug Or Rich", "ROR") {}

    string private _uri;

    uint public maxSupply = 7833;
    bool public saleStatus = false;
    uint public price = 47 * 10**14;
    uint public maxPerTx = 7;
    uint public maxPerWallet = 7;
    uint public maxFreePerTx = 2;
    uint public maxFreePerWallet = 2;
    uint public maxFreeMintCount = 7833;
    uint public freeMintCount = 0;
 
    // ---------------------------------------------------------------------------------------------
    // MAPPINGS
    // ---------------------------------------------------------------------------------------------

    mapping(address => uint) public feeMinted; 

    mapping(address => uint) public freeMinted; 

    // ---------------------------------------------------------------------------------------------
    // OWNER SETTERS
    // ---------------------------------------------------------------------------------------------

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMaxFreeMintCount(uint _count) external onlyOwner {
        maxFreeMintCount = _count;
    }

    function setSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }

    function setMaxSupply(uint supply) external onlyOwner {
        maxSupply = supply;
    }

    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }
    
    function setMaxPerTx(uint amount) external onlyOwner {
        maxPerTx = amount;
    }
    
    function setMaxPerWallet(uint amount) external onlyOwner {
        maxPerWallet = amount;
    }

    function setMaxFreePerTx(uint amount) external onlyOwner {
        maxFreePerTx = amount;
    }
    
    function setMaxFreePerWallet(uint amount) external onlyOwner {
        maxFreePerWallet = amount;
    }
    
    function setBaseURI(string calldata uri_) external onlyOwner {
        _uri = uri_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function devMint(uint256 amount) external onlyOwner {
        require(amount > 0, "AMOUNT_ERROR!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS");
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable {
        require(amount > 0, "AMOUNT_ERROR!");
        require(saleStatus, "SALE_NOT_ACTIVE!");
        require(tx.origin == msg.sender, "NOT_ALLOW_CONTRACT_CALL!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS!");
        if (freeMinted[msg.sender] + amount <= maxFreePerWallet && freeMintCount + amount <= maxFreeMintCount) {
            // free mint
            require(amount <= maxFreePerTx, "EXCEEDS_MAX_PER_TX!");
            freeMintCount += amount;
            _safeMint(msg.sender, amount);
            freeMinted[msg.sender] += amount;
        } else {
            require(amount * price <= msg.value, "NOT_ENOUGH_MONEY!");
            require(amount <= maxPerTx, "EXCEEDS_MAX_PER_TX!");
            require(feeMinted[msg.sender] + amount <= maxPerWallet, "EXCEEDS_MAX_PER_WALLET!");
            _safeMint(msg.sender, amount);
            feeMinted[msg.sender] += amount;
        }
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
}