// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC721AQueryable.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BedtimeCreationsCompanions is ERC721AQueryable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "https://www.bedtimerealm.com/nft/json/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "https://www.bedtimerealm.com/nft/hidden.json";
  
  uint256 public maxSupply = 1000;

  bool public paused = true;
  bool public revealed = false;

  uint256 public publicCost = 40000000000000000;
  uint256 public mintCounter = 0;

  address public erc20TokenAddress = 0xbB4f3aD7a2cf75d8EfFc4f6D7BD21d95F06165ca;
  uint256 public erc20TokenCost = 115000000000000000000000000;
  uint256 public erc20MintLimit = 100;

  uint256 public erc20MintCounter = 0;

  uint256 public bonusThreshold = 5;

  address public devAddy = 0x036D0560582c444ff13d5822e2759A9f1E3D1e1e;
  address public artistAddy = 0xEFd6E29eD1b602B4d0410bF008Bd667562DF1013;

  constructor() ERC721A("Bedtime Creations Companions", "BCC") Ownable(msg.sender) 
  {
    _startTokenId();
  }

  function _startTokenId()
        internal
        pure
        override
        returns(uint256)
    {
        return 1;
    }

// RUNS BEFORE ALL MINT FUNCTIONS
  modifier mintCompliance (uint256 _mintAmount) 
  {
    require(!paused, "Minting is PAUSED!");

    uint256 increaseAmount = (_mintAmount / bonusThreshold);
    _mintAmount += increaseAmount;

    require(mintCounter + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

// ---------------! SETTERS !------------------

  function setPublicMintCost(uint256 _mintCost) external onlyOwner
  {
      publicCost = _mintCost;
  }

  function setRevealed(bool _state) public onlyOwner 
  {
    revealed = _state;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner 
  {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner 
  {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner 
  {
    paused = _state;
  }

  function setERC20Token(address _erc20TokenAddress, uint256 _erc20TokenCost, uint256 _erc20MintLimit) public onlyOwner 
  {
    erc20TokenAddress = _erc20TokenAddress;
    erc20TokenCost = _erc20TokenCost;
    erc20MintLimit = _erc20MintLimit;
  }

  function setBonusThreshold(uint256 _newAmount) public onlyOwner
  {
    bonusThreshold = _newAmount;
  }

  function setDevAddy(address _newAddress) public onlyOwner
  {
    devAddy = _newAddress;
  }

  function setArtistAddy(address _newAddress) public onlyOwner
  {
    artistAddy = _newAddress;
  }

// ---------------! GETTERS !----------------------

  function getPausedState() public view returns (bool)
  {
    return paused;
  }

  function getTotalSupply() public view returns (uint256)
  {
    return totalSupply();
  }

// ---------------! MINT FUNCTIONS !-------------------

  function publicMint(uint256 _mintAmount, address receiver) external mintCompliance(_mintAmount) payable
  {
    require(msg.value >= _mintAmount * publicCost, "Insufficient funds!");
    require(_mintAmount > 0, "Invalid mint amount!");

    uint256 increaseAmount = (_mintAmount / bonusThreshold);
    _mintAmount += increaseAmount;

    mintCounter += _mintAmount;
    _safeMint(receiver, _mintAmount);
  }

  function publicMintRaw(uint256 _mintAmount) external mintCompliance(_mintAmount) payable
  {
    require(msg.value >= _mintAmount * publicCost, "Insufficient funds!");
    require(_mintAmount > 0, "Invalid mint amount!");

    mintCounter += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  function publicMintWithSheesh(uint256 _mintAmount, address receiver) external mintCompliance(_mintAmount)
  {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(erc20TokenAddress != address(0), "ERC-20 token not set!");
    require(erc20MintCounter + _mintAmount <= erc20MintLimit, "Mint limit with Sheesh has been reached!");

    IERC20 tokenContract = IERC20(erc20TokenAddress);
    tokenContract.transferFrom(msg.sender, address(this), _mintAmount * erc20TokenCost);

    uint256 increaseAmount = (_mintAmount / bonusThreshold);
    _mintAmount += increaseAmount;

    mintCounter += _mintAmount;
    erc20MintCounter += _mintAmount;
    _safeMint(receiver, _mintAmount);
  }

// AIRDROP TO MULTIPLE ADDRESSES
  function mintForAddressMultiple(address[] calldata addresses, uint256[] calldata amount) public onlyOwner
  {
    for (uint256 i; i < addresses.length; i++)
    {
      require(mintCounter + amount[i] <= maxSupply, "Max supply exceeded!");
      mintCounter += amount[i];
      _safeMint(addresses[i], amount[i]);
    }
  }

// STANDARD BURN FUNCTION
    function burn(uint256 tokenId) public virtual 
    {
      require(msg.sender == ownerOf(tokenId), "Caller is not the token owner");
      _burn(tokenId);
    }

    function burnMultiple(uint256[] calldata ids) public virtual
    {
      for (uint256 i; i < ids.length; i++)
      {
        require(msg.sender == ownerOf(ids[i]), "Caller is not the token owner");
        _burn(ids[i]);
      }
    }

// ---------------! BASELINE FUNCTIONS !---------------

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override (ERC721A, IERC721A)
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
        : "";
  }

  function withdrawAll() external onlyOwner 
  {
    payable(owner()).transfer(address(this).balance);

    if (erc20TokenAddress != address(0)) 
    {
        IERC20 erc20Token = IERC20(erc20TokenAddress);
        erc20Token.transfer(owner(), erc20Token.balanceOf(address(this)));
    }
  }

  function withdrawAllWithSplit() external onlyOwner 
  {
    uint256 ethBalance = address(this).balance;
    uint256 ethToRecipient = (ethBalance / 100) * 3;

    payable(devAddy).transfer(ethToRecipient);
    payable(artistAddy).transfer(ethToRecipient);
    payable(owner()).transfer(ethBalance - ethToRecipient*2);

    if (erc20TokenAddress != address(0)) 
    {
        IERC20 erc20Token = IERC20(erc20TokenAddress);
        uint256 erc20Balance = erc20Token.balanceOf(address(this));
        uint256 erc20ToRecipient = (erc20Balance / 100) * 3;

        erc20Token.transfer(devAddy, erc20ToRecipient);
        erc20Token.transfer(artistAddy, erc20ToRecipient);
        erc20Token.transfer(owner(), erc20Balance - erc20ToRecipient*2);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}