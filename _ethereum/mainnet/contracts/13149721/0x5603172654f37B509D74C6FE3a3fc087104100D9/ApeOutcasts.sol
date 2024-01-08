//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./EnumerableMap.sol";

import "./console.sol";

contract ApeOutcasts is
  Ownable,
  ERC721Enumerable,
  ERC721Burnable,
  ReentrancyGuard
{
  bool public isMintEnabled = false;

  uint256 public freeApesGiven = 0;
  uint256 public freeApesCap = 100;
  mapping(address => uint256) freeApes;
  mapping(address => bool) public gotFreeApe;
  uint256 private MAX_SUPPLY = 10000;

  uint256[10000] private _availableTokens;
  uint256 private _numAvailableTokens = 10000;

  constructor() ERC721("ApeOutcasts", "OUTCASTS") {}

  function freeMintOne() public payable nonReentrant {
    require(
      userHasFreeApe(msg.sender),
      "You have no free mints available (or pool has ran out)."
    );
    if (freeApes[msg.sender] > 0) {
      freeApes[msg.sender]--;
    } else {
      freeApesGiven++;
      gotFreeApe[msg.sender] = true;
    }
    _mintNoCostChecks(1);
  }

  function mint(uint256 _numOfApes) public payable nonReentrant {
    require(
      _numOfApes > 0 && _numOfApes <= 20,
      "Can only mint between 1-20 at a time."
    );
    uint256 _numMinted = totalSupply();
    require(
      _numMinted + _numOfApes <= MAX_SUPPLY,
      "There are not that many ape outcasts remaining."
    );
    uint256 costForMint = getCostForApes(_numOfApes);
    require(msg.value >= costForMint, "Need to send more ETH.");
    if (msg.value > costForMint) {
      payable(msg.sender).transfer(msg.value - costForMint);
    }
    _mintNoCostChecks(_numOfApes);
  }

  function _mintNoCostChecks(uint256 _numOfApes) internal {
    require(isMintEnabled, "Minting is not enabled.");
    uint256 updatedNumAvailableTokens = _numAvailableTokens;
    for (uint256 i = 0; i < _numOfApes; i++) {
      uint256 newTokenId = useRandomAvailableToken(_numOfApes, i);
      _safeMint(msg.sender, newTokenId);
      updatedNumAvailableTokens--;
    }
    _numAvailableTokens = updatedNumAvailableTokens;
  }

  function useRandomAvailableToken(uint256 _numToFetch, uint256 _i)
    internal
    returns (uint256)
  {
    uint256 randomNum = uint256(
      keccak256(
        abi.encode(
          msg.sender,
          tx.gasprice,
          block.number,
          block.timestamp,
          blockhash(block.number - 1),
          _numToFetch,
          _i
        )
      )
    );
    uint256 randomIndex = randomNum % _numAvailableTokens;
    return useAvailableTokenAtIndex(randomIndex);
  }

  function useAvailableTokenAtIndex(uint256 indexToUse)
    internal
    returns (uint256)
  {
    uint256 valAtIndex = _availableTokens[indexToUse];
    uint256 result;
    if (valAtIndex == 0) {
      result = indexToUse;
    } else {
      result = valAtIndex;
    }

    uint256 lastIndex = _numAvailableTokens - 1;
    if (indexToUse != lastIndex) {
      uint256 lastValInArray = _availableTokens[lastIndex];
      if (lastValInArray == 0) {
        _availableTokens[indexToUse] = lastIndex;
      } else {
        _availableTokens[indexToUse] = lastValInArray;
      }
    }

    _numAvailableTokens--;
    return result;
  }

  function getCostForApes(uint256 _numApes) public pure returns (uint256) {
    uint256 _cost;
    uint256 _index;
    for (_index; _index < _numApes; _index++) {
      _cost += 0.06 ether;
    }
    return _cost;
  }

  function freeApesRemaining() internal view returns (bool) {
    return 200 - freeApesGiven > 0;
  }

  function userHasFreeApe(address userAddress) public view returns (bool) {
    if (freeApes[userAddress] > 0) {
      return true;
    }
    if (!gotFreeApe[userAddress] && freeApesRemaining()) {
      return true;
    }
    return false;
  }

  function startSale() public onlyOwner {
    isMintEnabled = true;
  }

  function endSale() public onlyOwner {
    isMintEnabled = false;
  }

  function giveFreeApes(
    address[] memory addresses,
    uint256[] memory numOfFreeApes
  ) public onlyOwner {
    require(
      addresses.length == numOfFreeApes.length,
      "tokenOwners does not match numOfFreeRolls length"
    );
    uint256 freeApesHandedOut = 0;
    for (uint256 i = 0; i < addresses.length; i++) {
      freeApes[addresses[i]] = freeApes[addresses[i]] + numOfFreeApes[i];
      freeApesHandedOut += numOfFreeApes[i];
    }
    require(
      freeApesHandedOut < freeApesCap,
      "too many freemints allocated by devs"
    );
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 _serialId)
    public
    view
    override
    returns (string memory)
  {
    string memory base = _baseURI();
    string memory _tokenURI = Strings.toString(_serialId);

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    return string(abi.encodePacked(base, _tokenURI));
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() public payable onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 serialId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, serialId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
