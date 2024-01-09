// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./ERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract MyLittlePanda is ERC721, Ownable {

    bool public ON_SALE;

    uint256 public TOKEN_PRICE = 0.02 ether;
    uint256 public totalTokens = 0;
    uint256 public MAX_TOKENS_PER_TXN = 10;
    uint256 public MAX_TOKENS_PER_WALLET = 20;
    uint256 public MAX_SUPPLY = 5555;

    address proxyRegistryAddress;
    address teamWallet = 0x3D27eACef8BA6aE034dA1E611B1E8Bc1aeffCF4f;

    mapping(address => uint256) public walletMints;
    
    string private BASE_URI = "https://mylilpanda.com/api/?token_id=";

    constructor(address _proxyRegistryAddress) ERC721("MyLittlePanda", "PANDA") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    
    function mint(uint16 numberOfTokens) external payable  {
        require(ON_SALE, "not on sale");
        require(totalTokens + numberOfTokens <= MAX_SUPPLY, "Not enough");
        require(walletMints[msg.sender] + numberOfTokens <= MAX_TOKENS_PER_WALLET, "Not enough");
        require(numberOfTokens <= MAX_TOKENS_PER_TXN, "mint limit");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, 'missing eth');

        for(uint256 i = 1; i <= numberOfTokens; i+=1) {
            _safeMint(msg.sender, totalTokens+i);
        }

        totalTokens += numberOfTokens;
        walletMints[msg.sender] += numberOfTokens;
    }

    function airdrop(uint16 numberOfTokens, address userAddress) external onlyOwner {
        for(uint256 i = 1; i <= numberOfTokens; i+=1) {
            _safeMint(userAddress, totalTokens+i);
        }
        totalTokens += numberOfTokens;
    }

    function startSale() external onlyOwner {
        ON_SALE = true;
    }
    function stopSale() external onlyOwner {
        ON_SALE = false;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        TOKEN_PRICE = price;
    }
    function setMaxPublic(uint256 maxTokens) external onlyOwner {
        MAX_SUPPLY = maxTokens;
    }
    function setMaxPerTxn(uint256 maxTokens) external onlyOwner {
        MAX_TOKENS_PER_TXN = maxTokens;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(teamWallet).transfer(balance);
        delete balance;
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 tokenid;
            uint256 index;
            for (tokenid = 0; tokenid < totalTokens; tokenid++) {
                if(_exists(tokenid)){
                    if(_owner == ownerOf(tokenid)){
                        result[index]=tokenid;
                        index+=1;
                    }
                }
            }
            delete tokenid;
            delete tokenCount;
            delete index;
            return result;
        }
    }

    function totalSupply() public view virtual returns(uint256){
        return totalTokens;
    }
    
    /* OpenSea Proxy - Approving it on contract means no need for holders to each pay gas to approve later when listing on OS. */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    

}