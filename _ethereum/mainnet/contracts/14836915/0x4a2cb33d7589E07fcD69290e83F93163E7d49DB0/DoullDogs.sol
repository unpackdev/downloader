// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DoullDOGS is 
    Ownable,
    ERC721A
{
    using SafeMath for uint256;
    //Total Max
    uint256 public constant TOTAL_MAX_QTY = 5555;
    //Number of team reserved
    uint256 private constant DEV_MAX_QTY = 137;
    //Sales Max
    uint256 private constant SALES_MAX_QTY = TOTAL_MAX_QTY - DEV_MAX_QTY;
    //Maximum number of mints per address
    uint256 private constant MAX_QTY_PER_MINTER = 30;

    //public minting price
    uint256 private  Mint_Price = 0.02 ether;
    
    //
    mapping(address => uint256) private publicMinterToTokenQty;
    //Number of minit already
    uint256 private publicMintedQty = 0;
    //keep team own
    uint256 private devedQty = 0;

    //public minting time
    uint256 public publicMintStartTime = 1654063200;

    bool private autopay = false;

    bool public revealed = false;
    string public notRevealedUri;

    //opensea
    string private _contractURI;
    string private _tokenBaseURI;
    address proxyRegistryAddress;

    address walletCrow;
    address walletBing;
 
    constructor() ERC721A("Lucky Doull DOGS", "DOULL") 
    {
        walletCrow = 0x75ccb3BFDd64b3dEAfd11F2BDBfFF7c50e87cD70;
        walletBing = 0x1F50Cee056224a15828DEb9F4630dB6e819031FB;
    }

    //check public minting time
    modifier isPublicMintActive() 
    {
        require(
            isPublicMintActivated(),
            "PublicMintActivation: Mint is not activated"
        );
        _;
    }

    function isPublicMintActivated() public view returns (bool) 
    {
        return
            publicMintStartTime > 0 && block.timestamp >= publicMintStartTime;
    }

    //Set public minting time
    // 1654063200: start time at 01 Jun 2022 (2 PM UTC+8) in seconds
    function setPublicMintTime(uint256 _startTime) external onlyOwner 
    {
        publicMintStartTime = _startTime;
    }

    //Get price
    function getPrice() public view returns (uint256) 
    {
        return  Mint_Price;
    }
    
    //setr price
    function setPrice(uint256 _price) external onlyOwner
    {
        Mint_Price = _price;
    }

    //setr Autopay
    function setAutopay(bool _pay) external onlyOwner
    {
        autopay = _pay;
    }
    //public Mint
    function publicMint(uint256 _mintQty)
        external
        payable
        isPublicMintActive
    {
        require(
            publicMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed mint max limit"
        );
        require(
            publicMinterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= _mintQty * getPrice(), "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        publicMinterToTokenQty[msg.sender] += _mintQty;
        publicMintedQty += _mintQty;
        //SafeMint
        _safeMint(msg.sender, _mintQty);
        
        if (autopay)
        {
            uint256 balance = address(this).balance;
            if (balance > 0 )
            {
                uint256 walletBalance = balance.mul(70).div(100);
                payable(walletCrow).transfer(walletBalance);
                payable(walletBing).transfer(balance.sub(walletBalance));
            }
        }
        
    }

    //Owner Mint
    function selfMint(address _receiver, uint256 _count) external onlyOwner
    {
        require(
            totalSupply() + _count <= TOTAL_MAX_QTY,
            "Exceed mint max limit"
        );
        publicMintedQty += _count;
        _safeMint(_receiver, _count);
    }

    //Dev Mint
    function devMint(address[] calldata _receivers) external onlyOwner
    {
        require(
            devedQty + _receivers.length <= DEV_MAX_QTY,
            "Exceed Dev max limit"
        );

        devedQty += _receivers.length;

        for (uint256 i = 0; i < _receivers.length; i++)
        {
            _safeMint(_receivers[i], 1);
        }
    }

    function getBalance() external view returns (uint256) 
    {
        return address(this).balance;
    }

    function withdrawAll()  external payable
    {
        require(msg.sender == walletCrow || msg.sender == walletBing || msg.sender == owner(), "Invalid sender");
        require(address(this).balance > 0, "Withdrawble: No amount to withdraw");
        uint256 balance = address(this).balance;
        //uint256 walletBalance = (balance* 70)/100;
        //payable(walletCrow).transfer(walletBalance);
        //payable(walletBing).transfer(balance-walletBalance);
        uint256 walletBalance = balance.mul(70).div(100);
        payable(walletCrow).transfer(walletBalance);
        payable(walletBing).transfer(balance.sub(walletBalance));
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
    }

    function setReveal(bool _reveal) public onlyOwner 
    {
        revealed = _reveal;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "URIQueryForNonexistentToken: The token does not exist.");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    //opensea
    // https://github.com/ProjectOpenSea/opensea-creatures/blob/74e24b99471380d148057d5c93115dfaf9a1fa9e/migrations/2_deploy_contracts.js#L29
    // rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
    // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        proxyRegistryAddress = proxyAddress;
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

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }

}