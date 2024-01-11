// SPDX-License-Identifier: GPL-3.0

  pragma solidity ^0.8.7;

  import "./Ownable.sol";
  import "./ERC721A.sol";                 


  contract Invisibears is Ownable, ERC721A {
      using Strings for uint256;

      string public baseExtension = ".json";
      uint256 public FREE_MINT_SUPPLY = 500;
      uint256 public MAX_MINT_PER_TRANSACTION = 30; 
      uint256 public MAX_FREEMINT_PER_USER = 5; 
      uint256 public totalMaxSupply = 5000; 
      uint256 public mintPrice = 0.009 ether;
      uint64 public startTimestamp;
      bool public mintActive = true;
      string private _baseTokenURI;

    constructor() ERC721A("Invisibears", "IBS") {}

    function mint(uint256 quantity) external payable {
        require(startTimestamp !=0 &&  block.timestamp >= startTimestamp,"Mint is not active yet");
        require(mintActive == true,"Mint have been Paused");
        require(quantity > 0, "Mint quantity should be over 0");
        require(quantity <= MAX_MINT_PER_TRANSACTION, "Max mint per transaction exceeded");
        require(totalSupply() + quantity <= totalMaxSupply, "Reached max supply");
        require(msg.value >= mintPrice * quantity, "Insufficient Funds");
      // _safeMint's second argument now takes in a quantity, not a tokenId.
      _safeMint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity) external payable {
        require(startTimestamp !=0 &&  block.timestamp >= startTimestamp,"Mint is not active yet");
        require(mintActive == true,"Mint have been Paused");
        require(_numberMinted(msg.sender) < MAX_FREEMINT_PER_USER,"you are unable to freemint anymore");
        require(quantity > 0, "Mint quantity should be over 0");
        require(quantity <= MAX_FREEMINT_PER_USER, "Max mint per transaction exceeded");
        require(totalSupply() + quantity <= FREE_MINT_SUPPLY, "reached max free mint supply");
      // _safeMint's second argument now takes in a quantity, not a tokenId.
      _safeMint(msg.sender, quantity);
    }


    function setMaxSupply(uint256 _updatedQty) public onlyOwner{
      require(_updatedQty >= totalSupply());
      totalMaxSupply = _updatedQty;
    }
    function setMaxFreeSupply(uint256 _updateQty) public onlyOwner{
        FREE_MINT_SUPPLY = _updateQty;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
          : "";
    }
    
    function setBaseURI(string calldata baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
      payable(msg.sender).transfer(payable(address(this)).balance);   
    }

    function pauseMint() public onlyOwner {
      mintActive = false; 
    }

    function resumeMint() public onlyOwner {
      mintActive = true; 
    }

    function setPublicMintStartTime(uint32 _time) external onlyOwner {
      startTimestamp = _time;
    }

    function devMint( address devAddress, uint256 quantity) payable public onlyOwner {
          _safeMint(devAddress, quantity);
    }

    function numberMinted () external view returns (uint256){
      return _numberMinted(msg.sender);
    }

  }