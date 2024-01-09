pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC1155.sol";
import "./IERC20.sol";

contract NFTfolioMarketplace is Ownable, ReentrancyGuard, Pausable {    
    address public NFTfolioContractAddress;  
    address public NFTfolioTokensOwnerAddress;  

    uint256 public diamondPrice = 0.99 ether;
    uint256 public goldPrice = 0.25 ether;
    uint256 public silverPrice = 0.15 ether;

    // ERC20 contract address => nft folio token id => price
    mapping(address => mapping(uint256 => uint256)) public erc20Price;


    constructor(address nftFolioContractAddress, address nftFolioTokensOwnerAddress) {
        NFTfolioContractAddress = nftFolioContractAddress;
        NFTfolioTokensOwnerAddress = nftFolioTokensOwnerAddress;
    }

    function setPrice(uint256 diamond_price, uint256 gold_price, uint256 silver_price) onlyOwner external {
        diamondPrice = diamond_price;
        goldPrice = gold_price;
        silverPrice = silver_price;
    }
    function getPrice(uint256 tokenId) external view returns(uint256) {
        if (tokenId == 0) 
            return diamondPrice;
        if (tokenId == 1) 
            return goldPrice;
        if (tokenId == 2) 
            return silverPrice;
        else 
            return 0;
    }

    function setDiamondPrice(uint256 price) onlyOwner external {
        diamondPrice = price;
    }
    function setGoldPrice(uint256 price) onlyOwner external {
        goldPrice = price;
    }
    function setSilverPrice(uint256 price) onlyOwner external {
        silverPrice = price;
    }
    function setTokensOwner(address ownerAddress) onlyOwner external  {
        NFTfolioTokensOwnerAddress = ownerAddress;
    }

    function pause() onlyOwner external  {
        _pause();
    }
    function unpause() onlyOwner external  {
        _unpause();
    }


    function setErc20Price(address erc20Address, uint256 diamond_price, uint256 gold_price, uint256 silver_price) onlyOwner external {
        erc20Price[erc20Address][0] = diamond_price;
        erc20Price[erc20Address][1] = gold_price;
        erc20Price[erc20Address][2] = silver_price;
    }
    function getErc20Price(address erc20Address, uint256 tokenId) external view returns(uint256) {
        return erc20Price[erc20Address][tokenId];
    }


    function buy(uint256 tokenId) external payable whenNotPaused {
        ERC1155 nftFolioToken = ERC1155(NFTfolioContractAddress);
        require(nftFolioToken.balanceOf(NFTfolioTokensOwnerAddress, tokenId) >= 1, "No more NFTs in the inventory");

        uint256 price;
        if (tokenId == 0)
            price = diamondPrice;
        else if (tokenId == 1)
            price = goldPrice;
        else if (tokenId == 2)
            price = silverPrice;

        require(msg.value >= price, "Insufficient funds");
  
        bytes memory data;
        nftFolioToken.safeTransferFrom(NFTfolioTokensOwnerAddress, msg.sender, tokenId, 1, data);
    }


    function buyErc20(uint256 tokenId, address erc20Address) external payable whenNotPaused {
        ERC1155 nftFolioToken = ERC1155(NFTfolioContractAddress);
        require(nftFolioToken.balanceOf(NFTfolioTokensOwnerAddress, tokenId) >= 1, "No more NFTs in the inventory");

        uint256 price;
        if (tokenId == 0)
            price = erc20Price[erc20Address][0];
        else if (tokenId == 1)
            price = erc20Price[erc20Address][1];
        else if (tokenId == 2)
            price = erc20Price[erc20Address][2];

        require(price > 0, "This ERC20 is not available");

        IERC20 erc20Token = IERC20(erc20Address);  
        require(erc20Token.approve(address(this), price));

        uint256 erc20Balance = erc20Token.balanceOf(msg.sender); 
        require(erc20Balance >= price, "Insufficient funds");

        bool success = erc20Token.transferFrom(msg.sender, NFTfolioTokensOwnerAddress, price);
        require(success, "The ERC20 could not be transfered");

        bytes memory data;
        nftFolioToken.safeTransferFrom(NFTfolioTokensOwnerAddress, msg.sender, tokenId, 1, data);
    }



    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}