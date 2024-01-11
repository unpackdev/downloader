// SPDX-License-Identifier: GPL-3.0

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel



pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract StonerChicks is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.069 ether;
  uint256 public wlcost = 0.042 ether;
  uint256 public maxSupply = 8400;
  uint256 public WlSupply = 4400;
  uint256 public MaxperWallet = 7;
  uint256 public MaxperWalletOG = 7;
  bool public paused = false;
  bool public revealed = false;
  bool public preSale = true;
  bool public publicSale = true;
  bool public OGSale = true;
  bytes32 public merkleRoot;

  address private p1 = 0x50518CA1fBaae47d51A78dBD0b1829BA9F345A08;
  address private p2 = 0xa848983BBaB6E7aeAac5a2a0475D629B2F183B41;
  address private p3 = 0x34FA0BB757C492241B3468a2763388904A0FB85c;
  address private p4 = 0x1490547915f6e741A44671bD0fDc48b379387fe0;
  address private p5 = 0x3DEF3D85197Fced830551Ab07902635cc191b86d;

  constructor() ERC721A("Stoner Chicks", "SC") {
    setNotRevealedURI("ipfs://bafkreigvop5uanykumqpmlcjtyxmhecxn3qvxfvzjpjigufy2p5zegkgyq");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "SC: oops contract is paused");
    require(publicSale, "SC: Sale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "SC: need to mint at least 1 NFT");
    require(supply + tokens <= maxSupply, "SC: We Soldout");
    require(tokens <= MaxperWallet, "SC: Max NFT Per TX exceeded");
    require(msg.value >= cost * tokens, "SC: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }
/// @dev presale mint for whitelisted
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "SC: oops contract is paused");
    require(preSale, "SC: Presale Hasn't started yet");
    uint256 supply = totalSupply();
    require(tokens > 0, "SC: need to mint at least 1 NFT");
    require(supply + tokens <= WlSupply, "SC: Whitelist MaxSupply exceeded");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "SC: You are not Whitelisted");
    require(tokens <= MaxperWallet, "SC: Max NFT Per TX exceeded");
    require(msg.value >= wlcost * tokens, "SC: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }

  /// @dev presale mint for OGs
    function ogmint(uint256 tokens, bytes32[] calldata merkleProof) public payable nonReentrant {
    require(!paused, "SC: oops contract is paused");
    require(OGSale, "SC: Sale Hasn't started yet");
    uint256 supply = totalSupply();
    uint256 amount = tokens - 1;
    require(tokens > 0, "SC: need to mint at least 1 NFT");
    require(supply + tokens <= WlSupply, "SC: Whitelist MaxSupply exceeded");
    require(tokens <= MaxperWalletOG, "SC: OGs Can mint only 7 NFT per TX");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "SC: You are not an OG");

      if(_numberMinted(_msgSender()) <= 0) {
      require(msg.value >= wlcost * amount, "SC: insufficient funds");
      } else {
      require(msg.value >= wlcost * tokens, "SC: insufficient funds");
      }

      _safeMint(_msgSender(), tokens);
    
  }





  /// @dev use it for giveaway and mint for address
     function gift(uint256 _mintAmount, address[] memory _address) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    for(uint256 X = 0; X < _address.length; X++)

      _safeMint(_address[X], _mintAmount);
    
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

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
  
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }

    function setOGMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWalletOG = _limit;
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

        function toggleogsale(bool _state) external onlyOwner {
        OGSale = _state;
    }
  
 
  function withdraw() public payable onlyOwner nonReentrant {
        uint256 _each = address(this).balance / 5;
        require(payable(p1).send(_each));
        require(payable(p2).send(_each));
        require(payable(p3).send(_each));
        require(payable(p4).send(_each));
        require(payable(p5).send(_each));
  }
}
