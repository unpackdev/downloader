// SPDX-License-Identifier: GPL-3.0

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel



pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract SuperlativeDoodleKongz is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.075 ether;
  uint256 public wlcost = 0.05 ether;
  uint256 public maxSupply = 4444;
  uint256 public WlSupply = 1500;
  bool public paused = false;
  bool public revealed = false;
  bool public preSale = true;
  bool public publicSale = false;

  address private p1 = 0x7dE82f982f715Aca4f27AF5901dB6620a83550BC; // Founder
  address private p2 = 0x753c50233CDE9908Ee769432eA70D4af960E8851; // Founder
  address private p3 = 0x2ED8e11ea6be865d9b9F4C3F83E8d8D63d6084B6; // 10% for Community Funds

  constructor() ERC721A("Superlative Doodle Kongz", "SDK") {
    setNotRevealedURI("ipfs://Qmd9rA2k9DGgdPqzcsjbzBmD5DDoUFVcS3UueT5eRiJtCn");
  }

  // internal DO NOT DELETE THESE FUNCTION AT ALL
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

/// @dev public sale
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "SDK: oops contract is paused");
    require(publicSale, "SDK: Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "SDK: need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "SDK: We Soldout");
    require(msg.value >= cost * tokens, "SDK: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }
/// @dev presale mint for OG
    function presalemint(uint256 tokens) public payable nonReentrant {
    require(!paused, "SDK: oops contract is paused");
    require(preSale, "SDK: Presale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "SDK: need to mint at least 1 NFT");
    require(supply + tokens <= WlSupply, "SDK: Whitelist MaxSupply exceeded");
    require(msg.value >= wlcost * tokens, "SDK: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }




  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
    
  }

  


  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

    function setWlCost(uint256 _newWlCost) public onlyOwner {
    wlcost = _newWlCost;
  }

    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

    function setwlsupply(uint256 _newsupply) public onlyOwner {
    WlSupply = _newsupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

    function togglepublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }
  
 
  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(p3).call{value: address(this).balance * 10 / 100}("");
    require(success);

        uint256 _each = address(this).balance / 2;
        require(payable(p1).send(_each));
        require(payable(p2).send(_each));
  }
}
