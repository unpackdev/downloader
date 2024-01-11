//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WomenOnTheirPeriod is ERC721A, Ownable {
    event SaleStateChange(bool _active);
    event PriceChange(uint256 _newPrice);

    using Strings for uint256;

    uint256 public maxTokens = 7000;
    uint256 public freeTokens = 5000;
    // Increased by 1 to avoid unnecessary arithmetic calculation when minting for gas savings
    uint256 public maxTokensPerWallet = 21;
    uint256 public price = 0.0025 ether;

    string private baseURI;
    string public notRevealedJson =
        "ipfs://bafybeibyrtqynpiuvo7krru7yfwev7zvtw7llhbcw24ptqbl73mrkciq6u/";

    bool public saleActive = false;
    bool public revealed = false;

    mapping(address => uint256) public mintedPerWallet;
    mapping(address => bool) public freeMinters;

    constructor() ERC721A("Women On Their Period", "womnpwr") {
        freeMinters[address(0xcFe1Dc41699920A978c1616D60f019fDa2B79544)] = true;
        freeMinters[address(0x8DadcD646e0fdC6415C4588c3570AB31c55Ae222)] = true;
        freeMinters[address(0x70D93013F5Aa852C1Cfa6ed6329C71079C2530EF)] = true;
        freeMinters[address(0x263F4560084fDa0410e9F5FBcF06D5A6742831E9)] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        }
        return
            string(
                abi.encodePacked(notRevealedJson, tokenId.toString(), ".json")
            );
    }

    receive() external payable {}

    modifier canMint(uint256 _amount) {
        require(saleActive, "Sale is not active!");
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        if (!freeMinters[msg.sender]) {
            require(
                _amount > 0 &&
                    _amount + mintedPerWallet[msg.sender] < maxTokensPerWallet,
                "Too many tokens per wallet!"
            );
        }
        _;
    }

    function freeMint(uint256 _amount) external canMint(_amount) {
        require(
            freeTokens >= _amount + totalSupply(),
            "Not enough free tokens left!"
        );
        _safeMint(msg.sender, _amount);
        mintedPerWallet[msg.sender] += _amount;
    }

    function mint(uint256 _amount)
        external
        payable
        canMint(_amount)
    {
        if (!freeMinters[msg.sender]) {
            require(msg.value >= price * _amount, "Not enough ETH");
        }
        _safeMint(msg.sender, _amount);
        mintedPerWallet[msg.sender] += _amount;
    }

    // Only owner functions

    function startSale() public onlyOwner {
        require(!saleActive, "Sale already started!");
        saleActive = true;
        emit SaleStateChange(true);
    }

    function stopSale() external onlyOwner {
        require(saleActive, "Sale is not active!");
        saleActive = false;
        emit SaleStateChange(false);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceChange(_newPrice);
    }

    function setMaxTokensPerWallet(uint256 _maxTokensPerWallet) external onlyOwner {
        // 1 is added to avoid one arithmetical calculation to save on gas fees
        maxTokensPerWallet = _maxTokensPerWallet + 1;
    }

    function setFreeTokens(uint256 _freeTokensAmount) external onlyOwner {
        require(_freeTokensAmount <= maxTokens, "Free tokens amount can't exceed maximum supply!");
        freeTokens = _freeTokensAmount;
    }

    function revealTokens(string calldata _ipfsCID) external onlyOwner {
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
        revealed = true;
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed!");
    }
}
