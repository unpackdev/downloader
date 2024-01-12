// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MalibuCoinI.sol";

//     __    __  ______  __      __  ______  __  __                         
//    /\ "-./  \/\  __ \/\ \    /\ \/\  == \/\ \/\ \                        
//    \ \ \-./\ \ \  __ \ \ \___\ \ \ \  __<\ \ \_\ \                       
//     \ \_\ \ \_\ \_\ \_\ \_____\ \_\ \_____\ \_____\                      
//      \/_/  \/_/\/_/\/_/\/_____/\/_/\/_____/\/_____/                      
//     ______  ______  ______  ______  __  __       __  __  __  __  ______  
//    /\  == \/\  ___\/\  __ \/\  ___\/\ \_\ \     /\ \_\ \/\ \/\ \/\__  _\ 
//    \ \  __<\ \  __\\ \  __ \ \ \___\ \  __ \    \ \  __ \ \ \_\ \/_/\ \/ 
//     \ \_____\ \_____\ \_\ \_\ \_____\ \_\ \_\    \ \_\ \_\ \_____\ \ \_\ 
//      \/_____/\/_____/\/_/\/_/\/_____/\/_/\/_/     \/_/\/_/\/_____/  \/_/ 

contract MalibuBeachHut is ERC1155Supply, Ownable, ReentrancyGuard {

    string collectionURI = "";
    string private name_;
    string private symbol_; 
    uint256 public tokenQty;
    uint256 public commissionQty;
    uint256 public tokenPrice;
    uint256 public currentTokenId;
    uint256 public backfillTokenId;
    uint256 public maxMintQty;
    uint256 public maxWalletQty;
    uint[] public unlockableNFTs;
    uint256 public unlockableQty;
    uint256 public unlockablePrice;
    uint256 public currentUnlockableId;
    bool public paused;
    address public CoinContract;

    MalibuCoinI public coin;

    constructor() ERC1155(collectionURI) {
        name_ = "Malibu Beach Hut";
        symbol_ = "MBH";
        tokenQty = 5;
        commissionQty = 3;
        tokenPrice = 300 * 10 ** 18;
        currentTokenId = 137;
        backfillTokenId = 137;
        maxMintQty = 1;
        maxWalletQty = 1;
        unlockableQty = 2;
        unlockablePrice = 150 * 10 ** 18;
        paused = true;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    function mint(uint256 id)
        public
        nonReentrant
    {
        checkMintRequirements(id, tokenPrice);

        coin.transferFrom(_msgSender(), address(this), tokenPrice);
        _mint(_msgSender(), id, maxMintQty, "");
    }

    function mintUnlockable() 
        public 
        nonReentrant 
    {
        uint256 counter = 0;

        for(uint i = 0; i < unlockableNFTs.length; i++){
           if(balanceOf(_msgSender(), unlockableNFTs[i]) > 0) {
                counter++;
           }
        }

        require(counter >= unlockableQty, "You do not own enough base NFTs for this unlockable");

        checkMintRequirements(currentUnlockableId, unlockablePrice);

        coin.transferFrom(_msgSender(), address(this), unlockablePrice);
        _mint(_msgSender(), currentUnlockableId, maxMintQty, "");
    }

    function checkMintRequirements(uint256 id, uint256 price) private view {
        require(paused == false, "Minting is paused");
        require(totalSupply(id) < tokenQty, "All Minted");
        require(id <= currentTokenId, "This token ID has not been published yet" );
        require(id > backfillTokenId, "This token ID is reserved" );
        require(this.balanceOf(_msgSender(), id) + maxMintQty <= maxWalletQty, "You have hit the max tokens per wallet");
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(coin.balanceOf(_msgSender()) >= price, "You do not own enough Malibu Coins to make this transaction");
    }

    //=============================================================================
    // Private Functions
    //=============================================================================

    function adminMintOverride(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function mintCommission(address account) public onlyOwner {
        currentTokenId++;
        _mint(account, currentTokenId, commissionQty, "");
    }

    function setCollectionURI(string memory newCollectionURI) public onlyOwner {
        collectionURI = newCollectionURI;
    }

    function getCollectionURI() public view returns(string memory) {
        return collectionURI;
    }

    function setTokenQty(uint256 qty) public onlyOwner {
        tokenQty = qty;
    }

    function setCommissionQty(uint256 qty) public onlyOwner {
        commissionQty = qty;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function setBackfillTokenId(uint256 id) public onlyOwner {
        backfillTokenId = id;
    }

    function setCurrentTokenId(uint256 id) public onlyOwner {
        currentTokenId = id;
    }

    function setMaxMintQty(uint256 qty) public onlyOwner {
        maxMintQty = qty;
    }

    function setMaxWalletQty(uint256 qty) public onlyOwner {
        maxWalletQty = qty;
    }

    function setUnlockableNFTs(uint[] memory nfts) public onlyOwner {
        unlockableNFTs = nfts;
    }

    function setUnlockableQty(uint256 qty) public onlyOwner {
        unlockableQty = qty;
    }

    function setUnlockablePrice(uint256 price) public onlyOwner {
        unlockablePrice = price;
    }

    function setcurrentUnlockableId(uint256 id) public onlyOwner {
        currentUnlockableId = id;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function setMalibuCoin(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        coin = MalibuCoinI(_contract);
        CoinContract = _contract;
    }

    function coinWithdraw() public onlyOwner {
        coin.transferFrom(address(this), owner(), coin.balanceOf(address(this)));
    }

    //=============================================================================
    // Override Functions
    //=============================================================================
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(collectionURI, Strings.toString(_tokenId), ".json"));
    }    
}
