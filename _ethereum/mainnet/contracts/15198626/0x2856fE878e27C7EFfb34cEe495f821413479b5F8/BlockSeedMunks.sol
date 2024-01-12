// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BlockSeedMunks is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MaxSupply = 3000;
    uint256 public  QtyPerPublicMint = 10;
    uint256 public  QtyPerWhitelistMint = 10;
    uint256 public  MaxPerPublicWallet = 3000;
    uint256 public  MaxPerWhiteListWallet = 3000;
    uint256 public  PublicSalePrice = 0.1 ether;
    uint256 public  WhitelistSalePrice = 0.067 ether;

    uint256 public MaxMintPhase1 = 200;
    uint256 public MaxMintPhase2 = 1000;
    uint256 public MaxMintPhase3 = 2000;
    uint256 public MaxMintPhase4 = MaxSupply;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause = true;
    bool public teamMinted;
    bool public Phase1;
    bool public Phase2;
    bool public Phase3;
    bool public Phase4;

    mapping(address=>bool) public whiteListedAddress;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("BLOCKSEED MUNKS", "BSM"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "BlockSeedMunks :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        if(whiteListSale || publicSale && Phase1){
            
            if (!whiteListedAddress[msg.sender] && publicSale){
                require(publicSale, "BlockSeedMunks :: Minting is on Pause.");
                require((totalSupply() + _quantity) <= MaxMintPhase1, "BlockSeedMunks :: Cannot mint beyond phase 1 supply");
                require((totalPublicMint[msg.sender]  +_quantity) <= QtyPerPublicMint, "BlockSeedMunks :: Cannot mint beyond public max mint!");
                require(msg.value >= (PublicSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price ");
                require(_quantity + balanceOf(msg.sender) <= MaxPerPublicWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");


                totalPublicMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }
            else if (whiteListedAddress[msg.sender] && whiteListSale){
                require(whiteListSale, "BlockSeedMunks :: Minting is on Pause");
                require((totalSupply() + _quantity) <= MaxMintPhase1, "BlockSeedMunks :: Cannot mint beyond phase 1 supply");
                require((totalWhitelistMint[msg.sender] + _quantity)  <= QtyPerWhitelistMint, "BlockSeedMunks:: Cannot mint beyond whitelist max mint!");
                require(msg.value >= (WhitelistSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price");
                require(_quantity + balanceOf(msg.sender) <= MaxPerWhiteListWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");
                require(whiteListedAddress[msg.sender], "BlockSeedMunks :: Sorry you are not white listed!");

                totalWhitelistMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }
        }
        else if (publicSale || whiteListSale && Phase2){

            if (!whiteListedAddress[msg.sender] && publicSale){
                require(publicSale, "BlockSeedMunks :: Minting is on Pause.");
                require((totalSupply() + _quantity) <= MaxMintPhase2, "BlockSeedMunks :: Cannot mint beyond phase 2 supply");
                require((totalPublicMint[msg.sender]  +_quantity) <= QtyPerPublicMint, "BlockSeedMunks :: Cannot mint beyond public max mint!");
                require(msg.value >= (PublicSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price ");
                require(_quantity + balanceOf(msg.sender) <= MaxPerPublicWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");


                totalPublicMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }
            else if (whiteListedAddress[msg.sender] && whiteListSale){
                require(whiteListSale, "BlockSeedMunks :: Minting is on Pause");
                require((totalSupply() + _quantity) <= MaxMintPhase2, "BlockSeedMunks :: Cannot mint beyond phase 2 supply");
                require((totalWhitelistMint[msg.sender] + _quantity)  <= QtyPerWhitelistMint, "BlockSeedMunks:: Cannot mint beyond whitelist max mint!");
                require(msg.value >= (WhitelistSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price");
                require(_quantity + balanceOf(msg.sender) <= MaxPerWhiteListWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");
                require(whiteListedAddress[msg.sender], "BlockSeedMunks :: Sorry you are not white listed!");

                totalWhitelistMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }
            
        }
        else if (publicSale || whiteListSale && Phase3){

            if (!whiteListedAddress[msg.sender] && publicSale){
                require(publicSale, "BlockSeedMunks :: Minting is on Pause.");
                require((totalSupply() + _quantity) <= MaxMintPhase3, "BlockSeedMunks :: Beyond phase 3 Supply");
                require((totalPublicMint[msg.sender] +_quantity) <= QtyPerPublicMint, "BlockSeedMunks :: Cannot mint beyond public max mint!");
                require(msg.value >= (PublicSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price ");
                require(_quantity + balanceOf(msg.sender) <= MaxPerPublicWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");


                totalPublicMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }  
            else if (whiteListedAddress[msg.sender] && whiteListSale){
                require(whiteListSale, "BlockSeedMunks :: Minting is on Pause");
                require((totalSupply() + _quantity) <= MaxMintPhase3, "BlockSeedMunks :: Cannot mint beyond phase 3 supply");
                require((totalWhitelistMint[msg.sender] + _quantity)  <= QtyPerWhitelistMint, "BlockSeedMunks:: Cannot mint beyond whitelist max mint!");
                require(msg.value >= (WhitelistSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price");
                require(_quantity + balanceOf(msg.sender) <= MaxPerWhiteListWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");
                require(whiteListedAddress[msg.sender], "BlockSeedMunks :: Sorry you are not white listed!");

                totalWhitelistMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }
        }
        else if (publicSale || whiteListSale && Phase4){

            if (!whiteListedAddress[msg.sender] && publicSale){
                require(publicSale, "BlockSeedMunks :: Minting is on Pause.");
                require((totalSupply() + _quantity) <= MaxSupply, "BlockSeedMunks :: Cannot mint beyond total Supply");
                require((totalPublicMint[msg.sender] +_quantity) <= QtyPerPublicMint, "BlockSeedMunks :: Cannot mint beyond public max mint!");
                require(msg.value >= (PublicSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price ");
                require(_quantity + balanceOf(msg.sender) <= MaxPerPublicWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");


                totalPublicMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }            
            else if (whiteListedAddress[msg.sender] && whiteListSale){
                require(whiteListSale, "BlockSeedMunks :: Minting is on Pause");
                require((totalSupply() + _quantity) <= MaxSupply, "BlockSeedMunks :: Cannot mint beyond phase total Supply");
                require((totalWhitelistMint[msg.sender] + _quantity)  <= QtyPerWhitelistMint, "BlockSeedMunks:: Cannot mint beyond whitelist max mint!");
                require(msg.value >= (WhitelistSalePrice * _quantity), "BlockSeedMunks :: Payment is below the price");
                require(_quantity + balanceOf(msg.sender) <= MaxPerWhiteListWallet , "BlockSeedMunks :: You can not mint more than the maximum allowed per user.");
                require(whiteListedAddress[msg.sender], "BlockSeedMunks :: Sorry you are not white listed!");

                totalWhitelistMint[msg.sender] += _quantity;
                _safeMint(msg.sender, _quantity);
            }
     
        }
        else {
            require(!pause, "BlockSeedMunks :: Minting is paused");
        }
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "BlockSeedMunks :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 40);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
         //   ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function addWhiteListAddress(address[] memory _address) public onlyOwner {
        
        for(uint i=0; i<_address.length; i++){
            whiteListedAddress[_address[i]] = true;
        }
    }

    /////// Blacklisting (Wallet id can not buy, sell or transfer)
    function blackList(address _address) public onlyOwner {
        require(!isBlacklisted[_address], "user already blacklisted");
        isBlacklisted[_address] = true;
    }
    
    function removeFromBlacklist(address _address) public onlyOwner {
        require(isBlacklisted[_address], "user is not blacklisted");
        isBlacklisted[_address] = false;
    }

    //////// Max Per Public Mint
    function setMaxPerPublicMint(uint256 _quantity) public onlyOwner {
        QtyPerPublicMint=_quantity;
    }
 
    function getMaxPerPublicMint() public view returns (uint256) {
       
           return QtyPerPublicMint;
    }

    ////// Max Per WhiteList Mint
    function setMaxPerWhiteListMint(uint256 _quantity) public onlyOwner {
        QtyPerWhitelistMint=_quantity;
    }
 
    function getMaxPerWhiteListMint() public view returns (uint256) {
       
           return QtyPerWhitelistMint;
    }

    //////// PUBLIC SALE PRICE
    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
        PublicSalePrice = _newPrice;
    }

    function getPublicPrice(uint256 _quantity) public view returns (uint256) {
       
        return _quantity*PublicSalePrice ;
    }
    
    //////// WHITELIST SALE PRICE  
    function setWhiteListPrice(uint256 _newPrice) public onlyOwner() {
        WhitelistSalePrice = _newPrice;
    }

    function getWhiteListPrice(uint256 _quantity) public view returns (uint256) {
       
        return _quantity*WhitelistSalePrice ;
    }

    ////// Max Per Public Wallet
    function setMaxPerPublicWallet(uint256 _maxPerPublicWallet) public onlyOwner() {
        MaxPerPublicWallet = _maxPerPublicWallet;
    }

    function getMaxPerPublicWallet() public view returns (uint256) {
       
        return MaxPerPublicWallet ;
    }

    ////// Max Per WhiteList Wallet
    function setMaxPerWhiteListWallet(uint256 _maxPerWhiteListWallet) public onlyOwner() {
        MaxPerWhiteListWallet = _maxPerWhiteListWallet;
    }

    function getMaxPetWhiteListWallet() public view returns (uint256) {
       
        return MaxPerWhiteListWallet ;
    }


    /////// Togglers //////
    function EnablePause() external onlyOwner{
        pause = true;
        Phase1 = false;
        Phase2 = false;
        Phase3 = false;
        Phase4 = false;
        whiteListSale = false;
        publicSale = false;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function EnablePhase1() external onlyOwner{
        Phase1 = true;
        whiteListSale = true;
        publicSale = false;
        Phase2 = false;
        Phase3 = false;
        Phase4 = false;
        pause = false;
    }

    function EnablePhase2() external onlyOwner{
        Phase2 = true;
        Phase1 = false;
        Phase3 = false;
        Phase4 = false;
        whiteListSale = true;
        publicSale = true;
        pause = false;
        PublicSalePrice = 0.1 ether;
    }

    function EnablePhase3() external onlyOwner{
        Phase3 = true;
        Phase1 = false;
        Phase2 = false;
        Phase4 = false;
        whiteListSale = true;
        publicSale = true;
        pause = false;
        PublicSalePrice = 0.12 ether;
    }

    function EnablePhase4() external onlyOwner{
        Phase4 = true;
        Phase1 = false;
        Phase2 = false;
        Phase3 = false;
        whiteListSale = true;
        publicSale = true;
        pause = false;
        PublicSalePrice = 0.14 ether;
    }

    //3% to utility/investors wallet
    function withdraw() external onlyOwner{
        uint256 withdrawAmount = address(this).balance * 8/100;
        payable(0x05eC6A427417a723d3f37C3262fE7feCF31FFd20).transfer(withdrawAmount);
        payable(msg.sender).transfer(address(this).balance);
    }
}

