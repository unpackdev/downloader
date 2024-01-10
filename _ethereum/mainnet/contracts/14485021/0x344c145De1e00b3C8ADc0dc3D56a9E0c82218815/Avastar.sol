// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";

contract AvastarRemix is ERC721A, ReentrancyGuard {
  using Strings for uint256;

  // Public attributes for Manageable interface
  string public project;
  uint256 public totalSupply;
  uint256 public mintingPrice;
  uint256 public mintingMax;
  uint256 public holdingMax;
  bool public open;
  string public baseURI;
  bool public whitelisted;
  address public withdrawAddress;
  address public secret;

  struct SignatureStruct {
    address sender;
    uint256 tokenAmount;
    uint256 redeem;
  }
  
  // Project specific
  address public vaultAddress;
  uint256 public presaleMaximum;
  bool public preminted;
  mapping(address => bool) public redeemed;

  // solhint-disable-next-line
  constructor(
    string memory _project,
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) {
    project = _project;
    mintingPrice = 69000000000000000;
    mintingMax = 10;
    holdingMax = 420;
    open = false;
    whitelisted = true;
    presaleMaximum = 10;
    preminted = false;
    totalSupply = 4200;
    vaultAddress = 0x9a30D1D71DdFe4d6362a983C70C56d55b1C3d299;
    withdrawAddress = 0x6C184c2A60Dc0D8962bc439D748De9d3d929CbFe;
  }

  /**
   *  Minting function
   */
  function mint(bytes memory signature, uint256 tokenAmount, uint256 redeem) public payable nonReentrant {
    require(open, "Contract closed");
    require(verifyTransactionAmount(tokenAmount), "Insufficient ETH");
    require(verifyWhitelisting(signature, tokenAmount, redeem), 'Not whitelisted');
    require(verifyTokensAvailability(tokenAmount), "Supply limit");
    require(verifyTransactionLimit(tokenAmount), "Too many tokens");

    if (whitelisted && redeem > 0) {
      require(verifyRedeem(msg.sender), "Already redeemed");
      tokenAmount += 1;
      redeemed[msg.sender] = true;
    }
    buy(msg.sender, tokenAmount);
  }

  function premint() public onlyOwner nonReentrant {
    require(preminted == false, "Already preminted");
    buy(vaultAddress, 42);
    preminted = true;
  }

  /**
   *  Minting function by owner
   */
  function mintByOwner(address receiver, uint256 tokenAmount) public onlyOwner nonReentrant {
    require(verifyTokensAvailability(tokenAmount), "Supply limit");
    buy(receiver, tokenAmount);
  }

  function buy(address to, uint256 quantity) internal {
    _safeMint(to, quantity);
  }

  /*
   * Owner can withdraw the contract's ETH to an external address
   */
  function withdrawETH(address depositAddress, uint256 amount) public onlyOwner {
    uint256 currentBalance = address(this).balance;
    require(amount <= currentBalance, "Insufficient funds");
    if (depositAddress == address(0)) {
      revert("Withdrawing to address(0)");
    } else {
      payable(depositAddress).transfer(amount);
    }
  }
  function distribute(address [] memory _holders, uint256 [] memory _amounts) public onlyOwner () {
    require (_holders.length == _amounts.length, "Holders distribution error");
    require(_holders.length > 0, "Holders not set");
    for (uint i = 0;i<_holders.length;i++){
       if(_amounts[i]>0) {
           payable(_holders[i]).transfer(_amounts[i]);
       }
    }
 }

  function verifyRedeem(address sender) internal view returns (bool) {
    return redeemed[sender] == false;
  }

  function verifyTransactionAmount(uint256 tokenAmount) internal view returns (bool) {
    return msg.value >= tokenAmount * mintingPrice;
  }

  function verifyTokensAvailability(uint256 tokenAmount) internal view returns (bool) {
    return totalSupply >= tokenAmount + _totalMinted();
  }

  function verifyTransactionLimit(uint256 tokenAmount) internal view returns (bool) {
    return mintingMax >= tokenAmount;
  }

  /**
  * Verify if the sender wallet is whitelisted
  */
  function verifyWhitelisting(bytes memory signature, uint256 tokenAmount, uint256 redeem) internal view returns (bool) {
    if (!whitelisted) {
      return true;
    }
    SignatureStruct memory payload = SignatureStruct(msg.sender, tokenAmount, redeem);
    // Pack the payload
    bytes32 freshHash = keccak256(abi.encode(payload.sender, payload.tokenAmount, payload.redeem));
    // Get the packed payload hash
    bytes32 candidateHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash));
    // Verify if the fresh hash is signed with the provided signature 
    return verifyHashSignature(candidateHash, signature);
  }

  /**
  * Verify if signature is authentic and matches the request context 
  */
  function verifyHashSignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
    if (!whitelisted) {
      return true;
    }
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return false;
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    address signer = address(0);
    // If the version is correct, gather info
    if (v == 27 || v == 28) {
      // solium-disable-next-line arg-overflow
      signer = ecrecover(hash, v, r, s);
    }
    return secret == signer;
  }

  function minted() external view returns (uint256) {
    return _totalMinted();
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setMintingPrice(uint256 _mintingPrice) external onlyOwner {
    mintingPrice = _mintingPrice;
    open = false;
  }

  function setMintingMax(uint256 _mintingMax) external onlyOwner {
    mintingMax = _mintingMax;
  }

  function setHoldingMax(uint256 _holdingMax) external onlyOwner {
    holdingMax = _holdingMax;
  }

  function setOpen(bool _open) external onlyOwner {
    open = _open;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
    withdrawAddress = _withdrawAddress;
  }

  function setSecret(address  _secret) external onlyOwner {
    secret = _secret;
  }

  function setWhitelisted(bool _whitelisted) external onlyOwner {
    whitelisted = _whitelisted;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "Invalid token request");
    string memory base = baseURI;
    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return "";
    }

    return string(abi.encodePacked(base, tokenId.toString()));
  }

  function setMultiple(
    uint256 _totalSupply,
    uint256 _mintingPrice,
    uint256 _mintingMax,
    uint256 _holdingMax
  ) external onlyOwner {
    require(_totalSupply > _totalMinted(), "Total supply too low");
    totalSupply = _totalSupply;
    mintingPrice = _mintingPrice;
    open = (mintingPrice == _mintingPrice);
    mintingMax = _mintingMax;
    holdingMax = _holdingMax;
  }
}