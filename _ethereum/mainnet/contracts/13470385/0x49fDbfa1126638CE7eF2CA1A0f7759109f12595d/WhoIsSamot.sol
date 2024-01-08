// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./SafeMath.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title WhoIsSamot
 * WhoIsSamot - a contract for Who Is Samot NFTs
 */
contract WhoIsSamot is ERC721Tradable {
    using SafeMath for uint256;
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xD9CC8af4E8ac5Cb5e7DdFffD138A58Bac49dAEd5;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public maxToMint = 5;
    uint256 public maxToMintWhitelist = 5;
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    string _baseTokenURI;
    string _contractURI;
    address[] whitelistAddr;

    constructor(address _proxyRegistryAddress, address[] memory addrs)
        ERC721Tradable("Who Is Samot?", "SAMOT", _proxyRegistryAddress)
    {
        whitelistAddr = addrs;
        for (uint256 i = 0; i < whitelistAddr.length; i++) {
            addAddressToWhitelist(whitelistAddr[i]);
        }
    }

    struct Whitelist {
        address addr;
        uint256 hasMinted;
    }
    mapping(address => Whitelist) public whitelist;

    function baseTokenURI()
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
    }

    function setMaxToMintWhitelist(uint256 _maxToMint) external onlyOwner {
        maxToMintWhitelist = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function reserve(address to, uint256 numberOfTokens) public onlyOwner {
        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            mintTo(to);
        }
    }

    function addAddressToWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        require(!isWhitelisted(addr), "Already whitelisted");
        whitelist[addr].addr = addr;
        whitelist[addr].hasMinted = 0;
        success = true;
    }

    function addAddressesToWhitelist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        whitelistAddr = addrs;
        for (uint256 i = 0; i < whitelistAddr.length; i++) {
            addAddressToWhitelist(whitelistAddr[i]);
        }
        success = true;
    }

    function isWhitelisted(address addr)
        public
        view
        returns (bool isWhiteListed)
    {
        return whitelist[addr].addr == addr;
    }

    function getNFTPrice() public view returns (uint256) {
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended");
        uint256 currentSupply = totalSupply();
        if (currentSupply >= 8001) {
            return 12800000000000000000; // 8001 - 8888 12.8 ETH
        } else if (currentSupply >= 7001) {
            return 6400000000000000000; // 7001 - 8000 6.4 ETH
        } else if (currentSupply >= 6001) {
            return 3200000000000000000; // 6001 - 7000 3.2 ETH
        } else if (currentSupply >= 5001) {
            return 1600000000000000000; // 5001 - 6000 1.6 ETH
        } else if (currentSupply >= 4001) {
            return 800000000000000000; // 4001  - 5000 0.8 ETH
        } else if (currentSupply >= 3001) {
            return 400000000000000000; // 3001 - 4000 0.4 ETH
        } else if (currentSupply >= 2001) {
            return 200000000000000000; // 2001 - 3000 0.2 ETH
        } else if (currentSupply >= 1001) {
            return 100000000000000000; // 1001 - 2000 0.1 ETH
        } else {
            return 50000000000000000; // 0 - 1000 0.05 ETH
        }
    }

    function mint(address to, uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Sale has already ended."
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(
            getNFTPrice().mul(numberOfTokens) <= msg.value,
            "ETH sent is incorrect."
        );
        if (preSaleIsActive) {
            require(
                numberOfTokens <= maxToMintWhitelist,
                "Exceeds wallet pre-sale limit."
            );
            require(isWhitelisted(to), "Your address is not whitelisted.");
            require(
                whitelist[to].hasMinted.add(numberOfTokens) <=
                    maxToMintWhitelist,
                "Exceeds per wallet pre-sale limit."
            );
            require(
                whitelist[to].hasMinted <= maxToMintWhitelist,
                "Exceeds per wallet pre-sale limit."
            );
            whitelist[to].hasMinted = whitelist[to].hasMinted.add(
                numberOfTokens
            );
        } else {
            require(
                numberOfTokens <= maxToMint,
                "Exceeds per transaction limit."
            );
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            mintTo(to);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(10).div(100);
        uint256 wallet2Balance = balance.mul(85).div(100);
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(msg.sender).transfer(
            balance.sub(wallet1Balance.add(wallet2Balance))
        );
    }
}
