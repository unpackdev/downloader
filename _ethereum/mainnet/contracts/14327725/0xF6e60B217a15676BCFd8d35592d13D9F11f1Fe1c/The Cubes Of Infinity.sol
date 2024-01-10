// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


//░▀█▀░█░█░█▀▀░░░█▄█░▀█▀░█▀█░█▀▄░░░█▀▄░█░░░█▀█░█▀▀░█░█░▀░█▀▀                    
//░░█░░█▀█░█▀▀░░░█░█░░█░░█░█░█░█░░░█▀▄░█░░░█░█░█░░░█▀▄░░░▀▀█                    
//░░▀░░▀░▀░▀▀▀░░░▀░▀░▀▀▀░▀░▀░▀▀░░░░▀▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀░░░▀▀▀                    
//░▀█▀░█░█░█▀▀░░░█▀▀░█░█░█▀▄░█▀▀░█▀▀░░░█▀█░█▀▀░░░▀█▀░█▀█░█▀▀░▀█▀░█▀█░▀█▀░▀█▀░█░█
//░░█░░█▀█░█▀▀░░░█░░░█░█░█▀▄░█▀▀░▀▀█░░░█░█░█▀▀░░░░█░░█░█░█▀▀░░█░░█░█░░█░░░█░░░█░
//░░▀░░▀░▀░▀▀▀░░░▀▀▀░▀▀▀░▀▀░░▀▀▀░▀▀▀░░░▀▀▀░▀░░░░░▀▀▀░▀░▀░▀░░░▀▀▀░▀░▀░▀▀▀░░▀░░░▀░


import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
 
contract TheCubesOfInfinity is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private supply;
 
    uint256 public constant maxSupply = 250;
    uint256 public totalSupply;
    uint256 public constant maxMintPerTx = 10;
    uint256 public constant totalMintablePresale = 2;
    uint256 public publicSalePrice = 0.12 ether;
    uint256 public preSalePrice = 0.06 ether;
    uint256 public totalSupplyRemaining = maxSupply;
    uint256 public batchSize = 130;
    uint256 public batchCount;
    string public notRevealedUri;
    string public baseURI;
    bool public mintable = false;
    bool public preSaleMintable = false;
    bool public isRevealed = false;
    mapping(address => bool) public isWhiteListed;
    mapping(address => uint256) public addressPresaleBalance;
 
    event Mintable(bool mintable);
    event PreSaleMintable(bool preSaleMintable);
    event NotRevealedURI(string notRevealedUri);
    event BaseURI(string baseURI);
    event BatchSize(uint256 batchSize);
    event BatchCount(uint256 batchCount);
    event AddToWhiteList(address[] accounts);
    event RemoveFromWhiteList(address account);
 
    constructor(
    string memory _initNotRevealedURI
   
    ) ERC721("The Cubes Of Infinity", "TCOI") {
        setNotRevealedURI(_initNotRevealedURI);
        supply.increment();
    }
 
    modifier isMintable() {
        if (msg.sender != owner())
        require(mintable, "'The Cubes Of Infinity' is not mintable on public sale now.");
        _;
    }
 
    modifier isPreSaleMintable() {
        require(preSaleMintable, "'The Cubes Of Infinity' is not mintable on presale now.");
        _;
    }
 
    modifier isNotExceedMaxMintPerTx(uint256 amount) {
        require(
            amount <= maxMintPerTx,
            "Mint amount of 'The Cubes Of Infinity' exceeds max limit per transaction for public sale."
        );
        _;
    }
 
    modifier isNotExceedAvailableSupply(uint256 amount) {
        require(
            batchCount + amount <= batchSize,
            "Not enough 'The Cubes Of Infinity' to mint. Please check your amount."
        );
        _;
    }
 
   modifier isPaymentSufficientPublicSale(uint256 amount) {
        require(
            msg.value == amount * publicSalePrice,
            "Not enough ETH transferred to mint a 'The Cubes Of Infinity'."
        );
        _;
    }

    modifier isPaymentSufficientPreSale(uint256 amount) {
        require(
            msg.value == amount * preSalePrice,
            "Not enough ETH transferred to mint a 'The Cubes Of Infinity'."
        );
        _;
    }
 
    modifier isWhiteList() {
        require(
            isWhiteListed[msg.sender],
            "You are not on the whitelist for 'The Cubes Of Infinity' presale."
        );
        _;
    }
    
    //Functions

    function preSaleMint(uint256 amount)
        external
        payable
        isPreSaleMintable
        isWhiteList
        isNotExceedAvailableSupply(amount)
        isPaymentSufficientPreSale(amount)
    {
        if (msg.sender != owner()) {
        if (preSaleMintable == true) {
            uint256 ownerMintedCount = addressPresaleBalance[msg.sender];
            require(ownerMintedCount + amount <= totalMintablePresale, "max 'The Cubes of Infinity' per address exceeded for presale");
        }
    }
        for (uint256 index = 1; index <= amount; index++){
        uint256 id = supply.current();
        addressPresaleBalance[msg.sender]++;
        _safeMint(msg.sender, id);
        supply.increment();
        totalSupplyRemaining--;
        batchCount++;
        totalSupply++;
    }
    }
 
    function mint(uint256 amount)
        external
        payable
        isMintable
        isNotExceedMaxMintPerTx(amount)
        isNotExceedAvailableSupply(amount)
        isPaymentSufficientPublicSale(amount)
    {
        for (uint256 index = 1; index <= amount; index++) {
            uint256 id = supply.current();
            _safeMint(msg.sender, id);
            supply.increment();
            totalSupplyRemaining--;
            batchCount++;
            totalSupply++;
        }
    }
   
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
   
    if (isRevealed == false) {
        return notRevealedUri;
    }
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
        : "";
    }

    function setPublicSalePrice(uint256 _newPrice) external onlyOwner {
        publicSalePrice = _newPrice;
    }
 
    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
 
        emit Mintable(mintable);
    }
 
    function setPreSaleMintable(bool _preSaleMintable) external onlyOwner {
        preSaleMintable = _preSaleMintable;
 
        emit PreSaleMintable(preSaleMintable);
    }
 
    function setBatchSize(uint256 _batchSize) external onlyOwner {
        batchSize = _batchSize;
 
        emit BatchSize(batchSize);
    }
 
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
 
        emit NotRevealedURI(_notRevealedURI);
    }

    function reveal(bool _state) external onlyOwner {
        isRevealed = _state;
    }
 
    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
 
        emit BaseURI(baseURI);
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 
    function withdraw() external onlyOwner {
        (bool dev, ) = payable(0xEDB8150008916A0c777E34BB996Da853F052bD17).call{value: address(this).balance * 15 / 100}(""); 
    require(dev);
        (bool creatorx, ) = payable(0xA02Cf45566E91b5EFCF6eAfd402Bd885c61253F6).call{value: address(this).balance * 18 / 100}(""); 
    require(creatorx);
        (bool creatory, ) = payable(0xb0Ca7169CC440DEf187243ECf411B34aB75eCA01).call{value: address(this).balance * 50 / 100}("");
    require(creatory);
        (bool creatorz, ) = payable(0xEBfe1ab93D1122E065adCaFD8C3174261e8E726F).call{value: address(this).balance}("");
    require(creatorz);
    }
   
    function addToWhiteList(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhiteListed[_addresses[i]] = true;
        }
 
        emit AddToWhiteList(_addresses);
    }

    // This function reserve 30 Cubes for the team to use for gifts & giveaways.
	// @dev For One Time Use Only.
	// @param reserve Mint first 30 Non-Fungible Tokens of The Cubes Of Infinity.
    function DevMint() 
        external 
        onlyOwner {
        uint256 _totalSupply =  0;
        uint256 i;
        for (i = 1; i < 31; i++) {
            _safeMint(msg.sender, _totalSupply + i);
            supply.increment();
            batchCount++;
            totalSupply++;
            totalSupplyRemaining--;
        }
    }
}