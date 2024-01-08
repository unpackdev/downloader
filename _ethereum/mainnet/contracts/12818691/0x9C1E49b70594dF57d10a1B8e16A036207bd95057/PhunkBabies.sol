// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract PhunkBabies is Ownable, ERC721Enumerable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  // You can use this hash to verify the image file containing all the PhunkBabies
  string public constant imageHash =
    "acb2c6b4aff94fd7ceab964f5e7d2a16c0893b4635638326fad56a5f949d5408";

  constructor() ERC721("PhunkBabies", "PHNKBY") {}

  bool public isSaleOn = false;

  bool public saleHasBeenStarted = false;

  uint256 public constant MAX_MINTABLE_AT_ONCE = 50;

  uint256[3901] private _availableTokens;
  uint256 private _numAvailableTokens = 3901;
  uint256 private _numFreeRollsGiven = 0;

  mapping(address => uint256) public freeRollPhunkBabies;

  uint256 private _lastTokenIdMintedInInitialSet = 3901;

  function numTotalPhunkBabies() public view virtual returns (uint256) {
    return 3901;
  }

  function freeRollMint() public nonReentrant() {
    uint256 toMint = freeRollPhunkBabies[msg.sender];
    freeRollPhunkBabies[msg.sender] = 0;
    uint256 remaining = numTotalPhunkBabies() - totalSupply();
    if (toMint > remaining) {
      toMint = remaining;
    }
    _mint(toMint);
  }

  function getNumFreeRollPhunkBabies(address owner) public view returns (uint256) {
    return freeRollPhunkBabies[owner];
  }

  function mint(uint256 _numToMint) public payable nonReentrant() {
    require(isSaleOn, "Sale hasn't started.");
    uint256 totalSupply = totalSupply();
    require(
      totalSupply + _numToMint <= numTotalPhunkBabies(),
      "There aren't this many PhunkBabies left."
    );
    uint256 costForMintingPhunkBabies = getCostForMintingPhunkBabies(_numToMint);
    require(
      msg.value >= costForMintingPhunkBabies,
      "Too little sent, please send more eth."
    );
    if (msg.value > costForMintingPhunkBabies) {
      payable(msg.sender).transfer(msg.value - costForMintingPhunkBabies);
    }

    _mint(_numToMint);
  }

  // internal minting function
  function _mint(uint256 _numToMint) internal {
    require(_numToMint <= MAX_MINTABLE_AT_ONCE, "Minting too many at once.");

    uint256 updatedNumAvailableTokens = _numAvailableTokens;
    for (uint256 i = 0; i < _numToMint; i++) {
      uint256 newTokenId = useRandomAvailableToken(_numToMint, i);
      _safeMint(msg.sender, newTokenId);
      updatedNumAvailableTokens--;
    }
    _numAvailableTokens = updatedNumAvailableTokens;
  }

  function useRandomAvailableToken(uint256 _numToFetch, uint256 _i)
    internal
    returns (uint256)
  {
    uint256 randomNum =
      uint256(
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
      // This means the index itself is still an available token
      result = indexToUse;
    } else {
      // This means the index itself is not an available token, but the val at that index is.
      result = valAtIndex;
    }

    uint256 lastIndex = _numAvailableTokens - 1;
    if (indexToUse != lastIndex) {
      // Replace the value at indexToUse, now that it's been used.
      // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
      uint256 lastValInArray = _availableTokens[lastIndex];
      if (lastValInArray == 0) {
        // This means the index itself is still an available token
        _availableTokens[indexToUse] = lastIndex;
      } else {
        // This means the index itself is not an available token, but the val at that index is.
        _availableTokens[indexToUse] = lastValInArray;
      }
    }

    _numAvailableTokens--;
    return result;
  }

  function getCostForMintingPhunkBabies(uint256 _numToMint)
    public
    view
    returns (uint256)
  {
    require(
      totalSupply() + _numToMint <= numTotalPhunkBabies(),
      "There aren't this many PhunkBabies left."
    );
    if (_numToMint == 1) {
      return 0.006 ether;
    } else if (_numToMint == 3) {
      return 0.018 ether;
    } else if (_numToMint == 5) {
      return 0.03 ether;
    } else if (_numToMint == 10) {
      return 0.06 ether;
    } else if (_numToMint == 50) {
      return 0.3 ether;
    } else {
      revert("Unsupported mint amount");
    }
  }

  function getPhunkBabiesBelongingToOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 numPhunkBabies = balanceOf(_owner);
    if (numPhunkBabies == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](numPhunkBabies);
      for (uint256 i = 0; i < numPhunkBabies; i++) {
        result[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return result;
    }
  }

  /*
   * Dev stuff.
   */

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory base = _baseURI();
    string memory _tokenURI = Strings.toString(_tokenId);

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    return string(abi.encodePacked(base, _tokenURI));
  }

  // contract metadata URI for opensea
  string public contractURI;

  /*
   * Owner stuff
   */

  function startSale() public onlyOwner {
    isSaleOn = true;
    saleHasBeenStarted = true;
  }

  function endSale() public onlyOwner {
    isSaleOn = false;
  }

  function giveFreeRoll(address receiver) public onlyOwner {
    // max number of free mints we can give to the community for promotions/marketing
    require(_numFreeRollsGiven < 200, "already given max number of free rolls");
    uint256 freeRolls = freeRollPhunkBabies[receiver];
    freeRollPhunkBabies[receiver] = freeRolls + 1;
    _numFreeRollsGiven = _numFreeRollsGiven + 1;
  }

  // for handing out free rolls to 3901 punbaby owners
  function seedFreeRolls(
    address[] memory tokenOwners,
    uint256[] memory numOfFreeRolls
  ) public onlyOwner {
    require(
      !saleHasBeenStarted,
      "cannot seed free rolls after sale has started"
    );
    require(
      tokenOwners.length == numOfFreeRolls.length,
      "tokenOwners does not match numOfFreeRolls length"
    );

    // light check to make sure the proper values are being passed
    require(numOfFreeRolls[0] <= 3, "cannot give more than 3 free rolls");

    for (uint256 i = 0; i < tokenOwners.length; i++) {
      freeRollPhunkBabies[tokenOwners[i]] = numOfFreeRolls[i];
    }
  }

  function seedInitialContractState(
    address[] memory tokenOwners,
    uint256[] memory tokens
  ) public onlyOwner {
    require(
      !saleHasBeenStarted,
      "cannot initial phunk mint if sale has started"
    );
    require(
      tokenOwners.length == tokens.length,
      "tokenOwners does not match tokens length"
    );

    uint256 lastTokenIdMintedInInitialSetCopy = _lastTokenIdMintedInInitialSet;
    for (uint256 i = 0; i < tokenOwners.length; i++) {
      uint256 token = tokens[i];
      require(
        lastTokenIdMintedInInitialSetCopy > token,
        "initial phunk mints must be in decreasing order for our availableToken index to work"
      );
      lastTokenIdMintedInInitialSetCopy = token;

      useAvailableTokenAtIndex(token);
      _safeMint(tokenOwners[i], token);
    }
    _lastTokenIdMintedInInitialSet = lastTokenIdMintedInInitialSetCopy;
  }

  // URIs
  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    contractURI = _contractURI;
  }

  function withdrawMoney() public payable onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}