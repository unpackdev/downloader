// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Emotions is ERC721, Ownable {
  constructor() ERC721("Emotions", "EMO") {}

  string private uri = "https://assets.bossdrops.io/emotions/";

  uint public constant MAX_TOKENS = 1777;

  // Only 10 nfts can be purchased per transaction.
  uint public constant maxNumPurchase = 10;

  // How many tokens an early access member is allowed to mint.
  uint public earlyAccessTokensPerUser = 1;

  uint public totalEarlyAccessTokensAllowed = 269;

  uint public currentEarlyAccessTokensClaimed = 0;

  mapping (address => bool) private earlyAccessAllowList;

  mapping (address => uint) private earlyAccessClaimedTokens;

  /**
  * The state of the sale:
  * 0 = closed
  * 1 = early access
  * 2 = open
  */
  uint public saleState = 0;

  // Mint price is 0.07 ETH. 
  uint public mintPriceWei = 70000000000000000;

  uint public numMinted = 0;

  function canClaimEarlyAccessToken(address addr) view public returns (bool) {
    return earlyAccessAllowList[addr] && earlyAccessClaimedTokens[addr] < earlyAccessTokensPerUser && currentEarlyAccessTokensClaimed < totalEarlyAccessTokensAllowed;
  }

  function mint(uint num) public payable {
    require(saleState == 1 || saleState == 2, "Sale must be active to mint");
    if (saleState == 1) {
      _checkEarlyAccess(msg.sender, num);
      earlyAccessClaimedTokens[msg.sender] = SafeMath.add(earlyAccessClaimedTokens[msg.sender], 1);
      currentEarlyAccessTokensClaimed = SafeMath.add(currentEarlyAccessTokensClaimed, 1);
    } else if (saleState == 2) {
      _checkRegularSale(num);
    }
    require(msg.value >= SafeMath.mul(num, mintPriceWei), "Insufficient amount sent");
    _mintTo(msg.sender, num);
  }

  function _mintTo(address to, uint num) internal {
    uint newTotal = SafeMath.add(num, numMinted);
    require(newTotal <= MAX_TOKENS, "Minting would exceed max allowed supply");
    while(numMinted < newTotal) {
        _mint(to, numMinted);
        numMinted++;
    }
  }
  
  function totalSupply() public view virtual returns (uint) {
    return numMinted;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function _checkRegularSale(uint numberOfTokens) pure internal {
    require(numberOfTokens <= maxNumPurchase, "Can only mint 10 tokens at a time");
  }

  function _checkEarlyAccess(address sender, uint numberOfTokens) view internal {
    require(earlyAccessAllowList[sender], "Sender is not on the early access list");
    require(currentEarlyAccessTokensClaimed < totalEarlyAccessTokensAllowed, "Minting would exceed total allowed for early access");
    require(earlyAccessClaimedTokens[sender] < earlyAccessTokensPerUser, "Sender cannot claim any more early access gauntlets at this time");
    require(numberOfTokens == 1, "Can only mint 1 token in the early access sale");
  }

  /** OWNER FUNCTIONS */
  function ownerMint(uint num) public onlyOwner {
    _mintTo(msg.sender, num);
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setEarlyAccessTokensPerUser(uint num) public onlyOwner {
    earlyAccessTokensPerUser = num;
  }

  function setSaleState(uint newState) public onlyOwner {
      require(newState >= 0 && newState <= 2, "Invalid state");
      saleState = newState;
  }

  function setTotalEarlyAccessTokensAllowed(uint num) public onlyOwner {
    totalEarlyAccessTokensAllowed = num;
  }

  function addEarlyAccessMembers(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
      earlyAccessAllowList[addresses[i]] = true;
    }
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    uri = baseURI;
  }

  function setMintPrice(uint newPriceWei) public onlyOwner {
    mintPriceWei = newPriceWei;
  }
}
