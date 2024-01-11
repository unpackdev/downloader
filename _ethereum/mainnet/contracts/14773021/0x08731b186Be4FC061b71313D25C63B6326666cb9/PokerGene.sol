//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address,
 * to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PokerGene is ERC721, Ownable {
    // NOTE: Always set MAX_SUPPLY as 1 higher than intended,
    // Helps save gas on the very first mint of the collection
    uint256 public MAX_SUPPLY = 301;

    bool public IS_PUBLIC_SALE = false;
    uint256 public PUBLIC_SALE_PRICE = 0.02 ether;
    // Always set MAX_PER_WALLET one higher than intended to optimize gas
    // We subtract 1 from it before comparing
    uint256 public MAX_PER_WALLET = 6;

    string public baseTokenURI;

    address private proxyRegistryAddress;

    // We always set totalSupply as one higher as well, to save gas
    uint256 public totalSupply = 1;

    constructor(string memory baseURI, address _proxyRegistryAddress)
        ERC721("PokerGene", "POKERGENE")
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        // NOTE: nextTokenId is initialized to 1, since starting at 0 leads
        // to higher gas cost for the first mint
        setBaseURI(baseURI);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function publicMint(uint256 _count) external payable {
        uint256 _totalSupply = totalSupply;
        require(IS_PUBLIC_SALE);
        require(_totalSupply + _count - 1 < MAX_SUPPLY, "not enough supply");
        require(msg.sender == tx.origin, "no bots");
        require(
            balanceOf(msg.sender) + _count < MAX_PER_WALLET,
            "too many per wallet"
        );
        require(msg.value == PUBLIC_SALE_PRICE * _count, "wrong amount of ETH");

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, _totalSupply);
            unchecked {
                _totalSupply++;
            }
        }
        totalSupply = _totalSupply;
    }

    function mintNFTs(uint256 _count) public onlyOwner {
        uint256 _totalSupply = totalSupply;

        require(_totalSupply + _count - 1 < MAX_SUPPLY, "not enough supply");

        for (uint256 i = 0; i < _count; i++) {
            _mint(msg.sender, _totalSupply);
            unchecked {
                _totalSupply++;
            }
        }
        totalSupply = _totalSupply;
    }

    function gift(address[] calldata receivers) external onlyOwner {
        uint256 _totalSupply = totalSupply;
        require(
            _totalSupply + receivers.length - 1 < MAX_SUPPLY,
            "not enough supply"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], _totalSupply);
            unchecked {
                _totalSupply++;
            }
        }
        totalSupply = _totalSupply;
    }

    function withdrawAll() external onlyOwner {
        require(
            address(this).balance > 0,
            "Withdrawble: No amount to withdraw"
        );
        payable(msg.sender).transfer(address(this).balance);
    }

    function flipPublicSaleState() external onlyOwner {
        IS_PUBLIC_SALE = !IS_PUBLIC_SALE;
    }

    function setPublicSalePrice(uint256 _newPrice) external onlyOwner {
        PUBLIC_SALE_PRICE = _newPrice;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function setMaxMintPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _newMaxPerWallet;
    }

    // https://github.com/ProjectOpenSea/opensea-creatures/blob/32534ae831960047efb1bd96b599d4446c4a90b0/migrations/2_deploy_contracts.js
    // rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    function setProxyRegistryAddress(address _proxyAddress) external onlyOwner {
        proxyRegistryAddress = _proxyAddress;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
