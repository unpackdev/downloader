// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DoullNFT is 
    Ownable,
    ERC721Enumerable
{
    using SafeMath for uint256;
    //发行个数
    uint256 private constant TOTAL_MAX_QTY = 5555;
    //团队自留个数
    uint256 private constant GIFT_MAX_QTY = 137;
    //最大可售
    uint256 private constant SALES_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;
    //每个地址最多能铸造个数
    uint256 private constant MAX_QTY_PER_MINTER = 5;

    //公开发售价格
    uint256 private  Mint_Price = 0.05 ether;
    
    //
    mapping(address => uint256) private publicSalesMinterToTokenQty;
    //已经铸造个数
    uint256 private publicSalesMintedQty = 0;
    //自己存留个数
    uint256 private giftedQty = 0;

    //公开铸造时间
    uint256 public publicSalesStartTime;

    //opensea
    string private _contractURI;
    string private _tokenBaseURI;
    address proxyRegistryAddress;

    address walletCrow;
    address walletBing;

    constructor() ERC721("TheDoullDOG", "DOULL")  
    {
        //肉哥的钱包地址
        walletCrow = 0x75ccb3BFDd64b3dEAfd11F2BDBfFF7c50e87cD70;
        //小虾米的钱包地址
        walletBing = 0x1F50Cee056224a15828DEb9F4630dB6e819031FB;

        //测试地址
        //肉哥的钱包地址
        //walletCrow = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        //小虾米的钱包地址
        //walletBing = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

        //publicSalesStartTime = 1644069600;
    }

    //公开铸造时间计算
    modifier isPublicSalesActive() {
        require(
            isPublicSalesActivated(),
            "PublicSalesActivation: Sale is not activated"
        );
        _;
    }

    function isPublicSalesActivated() public view returns (bool) 
    {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    //设置公开铸造时间
    // 1644069600: start time at 05 Feb 2022 (2 PM UTC+0) in seconds
    function setPublicSalesTime(uint256 _startTime) external onlyOwner 
    {
        publicSalesStartTime = _startTime;
    }

    //获取价格 价格变动 1000 涨 0.05
    function getPrice() public view returns (uint256) 
    {
        return 
            ((totalSupply() / 1000) + 1) * Mint_Price;
    }

    function publicSalesMint(uint256 _mintQty)
        external
        payable
        isPublicSalesActive
    {
        require(
            publicSalesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            publicSalesMinterToTokenQty[msg.sender] + _mintQty <= MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= _mintQty * getPrice(), "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        publicSalesMinterToTokenQty[msg.sender] += _mintQty;
        publicSalesMintedQty += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
        //分钱钱
        uint256 balance = address(this).balance;
        if (balance > 0 )
        {
            //肉哥7成
            uint256 walletBalance = balance.mul(70).div(100);
            payable(walletCrow).transfer(walletBalance);
            //虾米3成
            payable(walletBing).transfer(balance.sub(walletBalance));
        }
        
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );

        giftedQty += receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function withdraw()  external payable
    {
        require(address(this).balance > 0, "Withdrawble: No amount to withdraw");
        uint256 balance = address(this).balance;
        ////肉哥7成
        //uint256 walletBalance = (balance* 70)/100;
        //payable(walletCrow).transfer(walletBalance);
        ////虾米3成
        //payable(walletBing).transfer(balance-walletBalance);
        //肉哥7成
        uint256 walletBalance = balance.mul(70).div(100);
        payable(walletCrow).transfer(walletBalance);
        //虾米3成
        payable(walletBing).transfer(balance.sub(walletBalance));
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
        override(ERC721)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}