// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";


contract GANNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Address for address;
    
    Counters.Counter private _tokenIdCounter;

    ERC721 Gapes = ERC721(0xBaE6f981dc151CfC633212f06A9c5B4E37920454);
    ERC721 Faces = ERC721(0x0D3dcc1d43eadc4c9083BbBDd8bCe840e4D08F3E);
    ERC721 Nature = ERC721(0x86FB9B866C25c54F1F11ec28016308c8a67840b6);

    string private baseURI = "ipfs://QmfL3KzXXiTGv827PKcufA9etuRjjEEGUaPSQK5bzJdj4w/";
    string private _contractURI = "ipfs://QmbuJXbZzedzmG3cQUzXnpK5wDmMNyfC5vsR6tHZoYZaUp";

    string public constant PROVANCE = "28fa99c42d0a30d19703f180011c127ea10099f3e36f5ce6761d5109134ce9f0";

    address payable internal devwallet = payable(0x376Fd64563274bb4fCde4eBCFbAbEde3503688Ba);

    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant PRICEGAPE = 0.05 ether;
    uint256 public constant MAXPURCHASE = 10;
    uint256 public constant MAXSUPPLY = 448;
    uint256 public promo = 10;

    bool public saleIsActive;
    bool public presaleIsActive;

    mapping(address => uint256) public GapesMinted;

    bool public frozenMetadata;
    event PermanentURI(string _baseURI, string _contractURI);

    constructor() ERC721("GANNFT-Space", "GAN-Space") {
    }

    function _baseURI() internal view override returns (string memory) {        
        return baseURI;
    }

    function setBaseUri(string memory baseURI_) external onlyOwner {
        require(!frozenMetadata,"Metadata already frozen");
        baseURI = baseURI_;
    }

    function contractURI() public view returns (string memory) {        
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        require(!frozenMetadata,"Metadata already frozen");
        _contractURI = contractURI_;
    }

    function freezeMetadata() external onlyOwner {
        frozenMetadata = true;
        emit PermanentURI(baseURI, _contractURI);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive || presaleIsActive && (Faces.balanceOf(_msgSender()) > 0 || Nature.balanceOf(_msgSender()) > 0), "Sale must be active to mint new NFTs");
        require(numberOfTokens <= MAXPURCHASE, "You can't mint that many at once");
        require(totalSupply() + numberOfTokens <= MAXSUPPLY, "Purchase would exceed max supply");
        require(PRICE * numberOfTokens <= msg.value, "too little value has been sent");       

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mintGAPE(uint256 numberOfTokens) public payable {
        //minting for Gape holders
        require(saleIsActive || presaleIsActive && (Faces.balanceOf(_msgSender()) > 0 || Nature.balanceOf(_msgSender()) > 0), "Sale must be active to mint new NFTs");
        require(numberOfTokens <= MAXPURCHASE, "You can't mint that many at once");
        require(totalSupply() + numberOfTokens <= MAXSUPPLY, "Purchase would exceed max supply");
        require(numberOfTokens <= Gapes.balanceOf(_msgSender()) - GapesMinted[_msgSender()], "You don't own enough Gapes");
        require(PRICEGAPE * numberOfTokens <= msg.value, "too little value has been sent");       

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        GapesMinted[_msgSender()] += numberOfTokens;
    }

    function mintPromo(uint256 numberOfTokens) public onlyOwner {
        //mint promotional NFTs before the sale begins
        require(numberOfTokens <= promo, "You can't mint that many at once");
        require(totalSupply() + numberOfTokens <= MAXSUPPLY, "Purchase would exceed max supply");

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        //subtract from total reserved for promo
        promo -= numberOfTokens;
    }


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    //kept as a fallback
    function withdrawETH_old () public onlyOwner {
        devwallet.transfer(address(this).balance);
	}

    function withdraw() external {
        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = devwallet.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
