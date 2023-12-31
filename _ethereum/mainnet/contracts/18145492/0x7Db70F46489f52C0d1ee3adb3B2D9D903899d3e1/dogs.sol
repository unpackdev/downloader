// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";

contract ImmortalDogs is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public Immortal_Dogs_PUB_PRICE = 0.055 ether;

  uint256 public MAX_Immortal_Dogs = 2000;

  uint256 private _tokenIdCounter;

  string public tokenBaseURI;
  string public unrevealedURI;

  bool public mintActive = true;
  bool public giftActive = false;

  address devPay1 = 0x9B8AF273FB41a2a8893591c88F142977b80e4E77;
  address devPay2 = 0x23bf137813776d2a971Ecdc3b93D172781dc97DF;
  address ownerPay1 = 0x7f3b7A300E22BFae4521aC75eB7d4d7d8D8a9DC4;
  address ownerPay2 = 0xd482058E0847dA334dC5aFF51463C9c6050c25cc;
  address communityWallet = 0x38756717Fa7dF8eC8dcEB00E56E300b8bc16E4e1;

  mapping (uint256 => string) public tokenMintedIPFS;

  constructor() ERC721("Immortal Dogs", "ID") {}

  function setPayout(address _newDevPay1, address _newDevPay2, address _newOwnerPay1, address _newOwnerPay2, address _newCommunityWallet) external onlyOwner {
      devPay1 = _newDevPay1;
      devPay2 = _newDevPay2;
      ownerPay1 = _newOwnerPay1;
      ownerPay2 = _newOwnerPay2;
      communityWallet = _newCommunityWallet;
  }

  function setPUBPrice(uint256 _newPrice) external onlyOwner {
    Immortal_Dogs_PUB_PRICE = _newPrice;
  }

  function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
    MAX_Immortal_Dogs = _newMaxSupply;
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIdCounter;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
    unrevealedURI = _unrevealedUri;
  }

	function setTokenMintedIPFS(uint256 _tokenId, string memory _tokenMintedIPFS) external onlyOwner {
		tokenMintedIPFS[_tokenId] = _tokenMintedIPFS;
	}

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    bool revealed = bytes(tokenBaseURI).length > 0;

    if (!revealed) {
      return unrevealedURI;
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }

  function giftMint(address _giftAddress, string memory _tokenMintedIPFS) external onlyOwner {
    require(giftActive, "Gift is not active");
    _giftMintImmortal_Dogs(_giftAddress, _tokenMintedIPFS);
  }

  function _giftMintImmortal_Dogs(address _giftAddress, string memory _tokenMintedIPFS) internal {
    require(_tokenIdCounter + 1 <= MAX_Immortal_Dogs, "This purchase would exceed the maximum Immortal_Dogs you are allowed to mint");
		uint256 mintIndex = _tokenIdCounter;

		if (mintIndex < MAX_Immortal_Dogs) {
			_tokenIdCounter += 1;
			tokenMintedIPFS[mintIndex]= _tokenMintedIPFS;
			_safeMint(_giftAddress, mintIndex);
		}
	}    

  function publicMint(string memory _tokenMintedIPFS) external payable nonReentrant {
    require(mintActive, "Public sale is not active.");
    require(msg.value >= Immortal_Dogs_PUB_PRICE, "The ether value sent is not correct");

    _safeMintImmortal_Dogs(_tokenMintedIPFS);
  }

  function _safeMintImmortal_Dogs(string memory _tokenMintedIPFS) internal {
    require(_tokenIdCounter + 1 <= MAX_Immortal_Dogs, "This purchase would exceed the max supply of Immortal_Dogs");
		uint256 mintIndex = _tokenIdCounter;

		if (mintIndex < MAX_Immortal_Dogs) {
			_tokenIdCounter += 1;
			tokenMintedIPFS[mintIndex]= _tokenMintedIPFS;
			_safeMint(msg.sender, mintIndex);
		}
	} 

  function setGiftActive(bool _active) external onlyOwner {
    giftActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    payable(devPay1).transfer((balance*250)/1000);
    payable(devPay2).transfer((balance*25)/1000);
    payable(ownerPay1).transfer((balance*325)/1000);
    payable(ownerPay2).transfer((balance*300)/1000);
    payable(communityWallet).transfer((balance*100)/1000);
  }
}