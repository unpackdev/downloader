// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MosterApeGymClub is ERC721, Ownable, PaymentSplitter {

    uint256 public constant MAX_TOKENS = 3031;
    uint256 public constant TOKENS_PER_MINT = 10;
    uint256 public mintPrice = 0.03 ether;
    uint256 private totalMinted = 0;

    string private _baseTokenURI;
    bool public saleIsOpen = false;

    mapping (address => bool) private _reserved;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    event MintApe (address indexed buyer, uint256 startWith, uint256 batch);

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory baseURI
    ) ERC721("Moster Ape Gym Club", "MAGC") PaymentSplitter(payees, shares) {
        _baseTokenURI = baseURI;
    }

    function mintApe(uint256 numberOfTokens) external payable {
        require(saleIsOpen, "Sale is not active");
        require(numberOfTokens <= TOKENS_PER_MINT, "Max apes per mint exceeded");
        require(totalMinted + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max available apes");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        emit MintApe(msg.sender, totalMinted+1, numberOfTokens);

        for(uint256 i = 1;  i <= numberOfTokens; i++) {
            _safeMint(msg.sender, totalMinted + i);
        }

        totalMinted += numberOfTokens;
    }

    function giveaway(uint256 numberOfTokens, address mintAddress) external onlyOwner {
        require(totalMinted + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max available apes");

        for(uint256 i = 1;  i <= numberOfTokens; i++) {
            _mint(mintAddress, totalMinted + i);
        }

        totalMinted += numberOfTokens;
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function flipSaleState() external onlyOwner {
        saleIsOpen = !saleIsOpen;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
    * Change the OS proxy if ever needed.
    */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
}
