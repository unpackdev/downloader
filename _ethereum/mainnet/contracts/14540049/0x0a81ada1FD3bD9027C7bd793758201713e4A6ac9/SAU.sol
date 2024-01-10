// SUPER APE UNIVERSITY

// Website: https://superape.university/
// Twitter: https://twitter.com/SuperApeUniv
// Instagram:  https://www.instagram.com/superapeuniversity/
// Discord: https://discord.com/invite/superapeuniversity

/*
╔═══╗╔╗ ╔╗╔═══╗╔═══╗╔═══╗    ╔═══╗╔═══╗╔═══╗    ╔╗ ╔╗╔═╗ ╔╗╔══╗╔╗  ╔╗╔═══╗╔═══╗╔═══╗╔══╗╔╗  ╔╗
║╔═╗║║║ ║║║╔═╗║║╔══╝║╔═╗║    ║╔═╗║║╔═╗║║╔══╝    ║║ ║║║║╚╗║║╚╣╠╝║╚╗╔╝║║╔══╝║╔═╗║║╔═╗║╚╣╠╝║╚╗╔╝║
║╚══╗║║ ║║║╚═╝║║╚══╗║╚═╝║    ║║ ║║║╚═╝║║╚══╗    ║║ ║║║╔╗╚╝║ ║║ ╚╗║║╔╝║╚══╗║╚═╝║║╚══╗ ║║ ╚╗╚╝╔╝
╚══╗║║║ ║║║╔══╝║╔══╝║╔╗╔╝    ║╚═╝║║╔══╝║╔══╝    ║║ ║║║║╚╗║║ ║║  ║╚╝║ ║╔══╝║╔╗╔╝╚══╗║ ║║  ╚╗╔╝ 
║╚═╝║║╚═╝║║║   ║╚══╗║║║╚╗    ║╔═╗║║║   ║╚══╗    ║╚═╝║║║ ║║║╔╣╠╗ ╚╗╔╝ ║╚══╗║║║╚╗║╚═╝║╔╣╠╗  ║║  
╚═══╝╚═══╝╚╝   ╚═══╝╚╝╚═╝    ╚╝ ╚╝╚╝   ╚═══╝    ╚═══╝╚╝ ╚═╝╚══╝  ╚╝  ╚═══╝╚╝╚═╝╚═══╝╚══╝  ╚╝  
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SAU is  ERC721A, Ownable {

    using Strings for uint256;

    //Declaration of the Variables

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    uint256 public preSalePrice = 50000000000000000; 
    uint256 public mainSalePrice = 70000000000000000; 
    uint256 public maxSupplyHero = 2750; 
    uint256 public maxSupplyVillain = 2750; 
    uint256 public teamReserveHero = 27; 
    uint256 public teamReserveVillain = 27; 
    uint256 public genesisApe; 
    uint256 public teamReserve = teamReserveHero + teamReserveVillain ;
    uint256 public maxSupplyCollection = maxSupplyHero + maxSupplyVillain + genesisApe + teamReserve;
    uint256 public maxMintPerTnx = 10; 
    uint256 public heroMintCount;
    uint256 public villainMintCount;

    bool public revealed = false;
    bool public mintLive;
    bool public preSaleLive;

    mapping(address => bool) private whiteList;
    mapping(address => uint256) private mintCount;

    modifier preSaleIsLive() {
        require(preSaleLive, "Pre-Sale not live");
        _;
    }

    modifier mintIsLive() {
        require(mintLive, "Mint not live");
        _;
    }

    modifier isRevealed() {
        require(revealed, "Not revealed");
        _;
    }

    constructor(
    uint256  _maxMintPerTnx,
    uint256  _genesisApe,
    string memory initBaseURI,
    string memory initNotRevealedUri
    ) ERC721A ("Super Ape University", "SAU", _maxMintPerTnx, _genesisApe) {
    maxMintPerTnx = _maxMintPerTnx;
    genesisApe = _genesisApe;
    baseURI = initBaseURI;
    notRevealedUri = initNotRevealedUri; 
    _safeMint(msg.sender, 1);
    }

    //Internal

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //Minting

    //Pre-Sale Mint

    function presaleMintHero(uint256 _unitSize) external payable preSaleIsLive{
        
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(tx.origin == msg.sender, "Transaction Error: Contracts Not Allowed");
        require(whiteList[msg.sender], "Transaction Error: The Connect Wallet is Not Whitelisted");
        require(totalSupply() <= maxSupplyCollection, "Sale Closed: The Collection is Sold Out");
        require(heroMintCount + _unitSize <= maxSupplyHero, "All the Hero Super Apes are taken ! Please try minting the Villan Ape");
        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply");
        require(_unitSize <= maxMintPerTnx, "Transaction Error: Number of NFTs' are Maxed Out per Transaction");
        require(msg.value >= _unitSize * preSalePrice,"Try to send more ETH");

        mintCount[_to] = minted + _unitSize;
        for (uint256 i = 1; i <= _unitSize; i++) {
            heroMintCount++;
        }
        _safeMint(msg.sender, _unitSize);
    }

    function presaleMintVIllain(uint256 _unitSize) external payable preSaleIsLive{
        
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(tx.origin == msg.sender, "Transaction Error: Contracts Not Allowed");
         require(totalSupply() < maxSupplyCollection, "Sale Closed: The Collection is Sold Out");
        require(whiteList[msg.sender], "Transaction Error: The Connect Wallet is Not Whitelisted");
        require(villainMintCount + _unitSize <= maxSupplyVillain, "All the Villain Super Apes are taken ! Please try minting the Hero Ape");
        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");
        require(_unitSize <= maxMintPerTnx, "Transaction Error: Number of NFTs' are Maxed Out per Transaction"  );
        require(msg.value >= _unitSize * preSalePrice,"Try to send more ETH");

        mintCount[_to] = minted + _unitSize;
        for (uint256 i = 1; i <= _unitSize; i++) {
             villainMintCount++;
        }
        _safeMint(msg.sender, _unitSize);
    }

    //Main Sale Mint

    function mainsaleMintHero(uint256 _unitSize) external payable mintIsLive{
        
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(tx.origin == msg.sender, "Transaction Error: Contracts Not Allowed");
        require(totalSupply() <= maxSupplyCollection, "Sale Closed: The Collection is Sold Out");
        require(heroMintCount + _unitSize <= maxSupplyHero, "All the Hero Super Apes are taken ! Please try minting the Villain Ape");
        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");
        require(_unitSize <= maxMintPerTnx, "Transaction Error: Number of NFTs' are Maxed Out per Transaction"  );
        require(msg.value >= _unitSize * mainSalePrice,"Try to send more ETH");

        mintCount[_to] = minted + _unitSize;
        for (uint256 i = 1; i <= _unitSize; i++) {
            heroMintCount++;
        }
        _safeMint(msg.sender, _unitSize);
    }

    function mainsaleMintVIllain(uint256 _unitSize) external payable mintIsLive{
        
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(tx.origin == msg.sender, "Transaction Error: Contracts Not Allowed");
        require(totalSupply() < maxSupplyCollection, "Sale Closed: The Collection is Sold Out");
        require(villainMintCount + _unitSize <= maxSupplyVillain, "All the Villain Super Apes are taken ! Please try minting the Hero Ape");
        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");
        require(_unitSize <= maxMintPerTnx, "Transaction Error: Number of NFTs' are Maxed Out per Transaction");
        require(msg.value >= _unitSize * mainSalePrice,"Try to send more ETH");

        mintCount[_to] = minted + _unitSize;
        for (uint256 i = 1; i <= _unitSize; i++) {
            villainMintCount++;
        }
        _safeMint(msg.sender, _unitSize);  
    }

    //Airdrops

    function airdropHero(address[] calldata _to, uint256 _unitSize) external onlyOwner {

        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");

        for (uint256 i = 0; i < _to.length; i++){
                heroMintCount++;
                _safeMint(_to[i], _unitSize);
                
        }
            
    }

    function airdropVillain(address[] calldata _to, uint256 _unitSize) external onlyOwner {

        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");

        for (uint256 i = 0; i < _to.length; i++){
                villainMintCount++;
                _safeMint(_to[i], _unitSize);
                
        }
            
    }

    //DevMint

    function devMintHero(address[] calldata _to, uint256 _unitSize) external onlyOwner {

        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");
        require (_unitSize <= teamReserveHero, "Exceeds team reserve");

        for (uint256 i = 0; i < _to.length; i++){
                _safeMint(_to[i], _unitSize);
                teamReserveHero -= _unitSize;
        }
            
    }

    function devMintVillain(address[] calldata _to, uint256 _unitSize) external onlyOwner {

        require(totalSupply() + _unitSize <= maxSupplyCollection, "Minting would exceed max supply.");
        require (_unitSize <= teamReserveVillain, "Exceeds team reserve");

        for (uint256 i = 0; i < _to.length; i++){
                _safeMint(_to[i], _unitSize);
                teamReserveVillain -= _unitSize;
        }
            
    }

    //Owner Functions

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner{
        baseExtension = _newBaseExtension;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

     function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
        notRevealedUri = _newNotRevealedURI;
    }

    function setMintPerTnx(uint256 _newMintPerTnx) public onlyOwner {
        maxMintPerTnx = _newMintPerTnx;
    }

    function setPreSalePriceWei(uint256 _newPreSalePrice) public onlyOwner {
        preSalePrice = _newPreSalePrice;
    }

    function setVillainSupply(uint256 _newMaxSupplyVillain) public onlyOwner {
        maxSupplyVillain = _newMaxSupplyVillain;
    }

    function setHeroSupply(uint256 _newMaxSupplyHero) public onlyOwner {
        maxSupplyHero = _newMaxSupplyHero;
    }

    function setTeamReserveHero(uint256 _newTeamReserveHero) public onlyOwner {
        teamReserveHero = _newTeamReserveHero;
    }

    function setTeamReserveVillain(uint256 _newTeamReserveVillain) public onlyOwner {
        teamReserveVillain = _newTeamReserveVillain;
    }

    function setMainSalePriceWei(uint256 _newMainSalePrice) public onlyOwner {
        mainSalePrice = _newMainSalePrice;
    }

    function addToWhiteList(address[] calldata addresses) public onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++)
            whiteList[addresses[i]] = true;
    }

    function enableMintLive() public onlyOwner {
        if (mintLive) {
            mintLive = false;
            return;
        }
        mintLive = true;
    }

     function enablePreSaleLive() public onlyOwner {
        if (preSaleLive) {
            preSaleLive = false;
            return;
        }
        preSaleLive = true;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    //Finance

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "SAU: Insufficent balance");
        payable(msg.sender).transfer(balance);
    }

    //Public Functions

    function isWhiteListed(address _address) public view returns (bool){
        return whiteList[_address];
    }

    function tokensAvailableForMint() public view returns (uint256) {
        return availableHeros() + availableVillains(); 
    }

    function availableHeros() public view returns (uint256) {
        return maxSupplyHero - heroMintCount; 
    }

    function availableVillains() public view returns (uint256) {
        return maxSupplyVillain - villainMintCount; 
    }
    
    function numberOfMints(address _address) public view returns (uint256){
        return mintCount[_address];
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory baseTokenURI = _baseURI();
        return bytes(baseTokenURI).length > 0
            ? string(abi.encodePacked(baseTokenURI, _tokenId.toString(), baseExtension )): '';
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++)
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        return tokenIds;
    }

    function multiTransferFrom(
        address from_, 
        address to_, 
        uint256[] calldata tokenIds_) 
        public {
    
        uint256 tokenIdsLength = tokenIds_.length;
        for (uint256 i = 0; i < tokenIdsLength; i++) {
        transferFrom(from_, to_, tokenIds_[i]);
            }
    }

    function multiSafeTransferFrom(
      address from_, 
      address to_, 
      uint256[] calldata tokenIds_, 
      bytes calldata data_) 
      public {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
        safeTransferFrom(from_, to_, tokenIds_[i], data_);
             }
    }
}
