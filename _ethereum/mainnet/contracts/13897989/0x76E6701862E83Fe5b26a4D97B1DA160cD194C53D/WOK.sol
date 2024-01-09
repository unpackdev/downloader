// SPDX-License-Identifier: GPL-3.0
//////////////WORLD OF KAIJU/////////////////////////
/////////////ALL RIGHT RESERVED//////////////////////
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WOK is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.055 ether;
  uint256 public maxSupply = 1222;
  uint256 public maxMintAmount = 10;
  bool public publicsaleonly = false;
  string public notRevealedUrl;
  bool public revealed = false;
  bool public isFreeActive = false;
	mapping(address => uint256) private _claimed;

 constructor(
  ) ERC721("World of Kaiju", "WOK") {
}


  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

    function freeMint() external payable {
        uint256 supply = totalSupply();
		
        require(isFreeActive, "Free minting is not active");
		
		// free first 222 for the community (1 per address only)
        require(_claimed[msg.sender] == 0, "Free token already claimed");	
		require(supply <= 221, "Free Mint is finished!");
        _claimed[msg.sender] += 1;
		_safeMint(msg.sender, supply);
    }
	
	
	
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(publicsaleonly, "Public sale is not live.");
    require(_mintAmount > 0, "Minimum to mint is 1.");
    require(_mintAmount <= maxMintAmount,"Not allow over maximum mint to purchased.");
    require(supply + _mintAmount <= maxSupply, "Sold out!");
	
	//validate mint amount
    require(msg.value >= cost * _mintAmount, "Wrong mint price.");
	
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
	
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (!revealed) {
      return notRevealedUrl;
    } else {
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
	}
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxPerMint(uint256 _newmaxPerMint) public onlyOwner {
    maxMintAmount = _newmaxPerMint;
  }

  function setMaxSupply(uint256 _newmaxSupply) public onlyOwner {
    maxSupply = _newmaxSupply;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedUrl(string memory _setNotRevealedUrl) public onlyOwner {
    notRevealedUrl = _setNotRevealedUrl;
  }
  
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function PublicSaleEnabled(bool _state) public onlyOwner {
    publicsaleonly = _state;
  }

  function RevealEnabled(bool _state) public onlyOwner {
    revealed = _state;
  }

	function setFreeActive(bool val) external onlyOwner {
		isFreeActive = val;
	}

  function Reserved(uint256 _mintAmount) public onlyOwner {
	uint256 supply = totalSupply();
	require(supply + _mintAmount <= maxSupply, "Sold out!");
	
	//claim 50 at a time.
	require(_mintAmount <= 50, "Too many requested");
	
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
	
  }
  //checking
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}