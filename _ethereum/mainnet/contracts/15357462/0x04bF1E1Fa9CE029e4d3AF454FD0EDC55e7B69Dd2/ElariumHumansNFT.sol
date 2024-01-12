//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";
// import "./ERC721Enumerable.sol";

contract ElariumHumansNFT is Ownable, ERC721A, ReentrancyGuard {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    string public baseExtension = "";

    // Variables controling wheather the NFTs are revealed or not.
    bool public revealed = false;
    string public notRevealedUri;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 9066;
    uint256 private partialSupply = 4000;
    uint256 public maxPublicMint = 1;
    uint256 private pricePerToken = 0.06 ether;

    mapping(address => uint8) private _allowList;

    // constructor() ERC721("ElariumHumansNFT", "ELARIUMHUMANSNFT") {}
    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    uint256 maxBatchSize_,
    uint256 collectionSize_
    ) ERC721A(_name, _symbol, maxBatchSize_, collectionSize_) {
        maxPublicMint = maxBatchSize_;  
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    } 

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    // Function used to update the baseURI and reveal NFTs
    function reveal() public onlyOwner {
        revealed = true;
    }

    // Function used to update the maxPublicMint
    function setMaxPublicMint(uint256 n) public onlyOwner {
        maxPublicMint = n;
    }

    // Function used to update the partialSupply
    function setPartialSupply(uint256 newSupply) public onlyOwner {
        partialSupply = newSupply;
    }

    function getPartialSupply() public view returns (uint256){
        return partialSupply;
    }

    // Function used to update the pricePerToken
    function setPricePerToken(uint256 newPrice) public onlyOwner {
        pricePerToken = newPrice;
    }

    function getPricePerToken() public view returns (uint256){
        return pricePerToken;
    }

    // Function used to return tokenURI based on the reveal status
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
      require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );
      
      if(revealed == false) {
          return notRevealedUri;
      }

    //   string memory currentBaseURI = _baseURI();
      return string(super.tokenURI(tokenId));
    }

    /**
    * Mints NFT on private sale
    */
    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= partialSupply, "Purchase would exceed partial supply tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(pricePerToken * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    /*
    * Function used to mint a reserve supply of NFTS to the owner of the contract
    */
    function reserve(uint256 n) public onlyOwner {
        uint supply = totalSupply();
        require(supply + n < MAX_SUPPLY, "Not enough NFTs available");
        _safeMint(msg.sender, n);
    }

    /*
    * Function to change the state of the sale from active to inactive and vice-versa
    */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
    * Mints NFT on public sale
    */
    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        uint256 walletBalance = numberMinted(msg.sender);

        require(saleIsActive, "Sale must be active to mint tokens");

        require(numberOfTokens <= maxPublicMint, "Exceeded max token purchase");

        require(walletBalance + numberOfTokens <= maxPublicMint, "Can not mint this many");

        require(ts + numberOfTokens <= partialSupply, "Purchase would exceed partial supply tokens");

        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");

        require(pricePerToken * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

    /*
    * Function responsible for withdrawal of funds from the contract
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ERC721A functions

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
