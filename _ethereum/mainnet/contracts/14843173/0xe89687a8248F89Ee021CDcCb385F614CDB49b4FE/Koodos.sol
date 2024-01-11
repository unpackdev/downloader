// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
        _   _ ______ _______ 
       | \ | |  ____|__   __|
   __ _|  \| | |__     | |   
  / _` | . ` |  __|    | |   
 | (_| | |\  | |       | |   
  \__, |_| \_|_|       |_|   
     | |                     
     |_|     
*/
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./SignatureChecker.sol";

contract Koodos is ERC721Enumerable, Ownable, ReentrancyGuard {
  event Royalties(uint256 indexed received);

  address payable public splitWallet;
  address _backend = 0xb6FFdaa303f113a9d659Df47f17a0984f2A0B5F3;
  uint[3] private _remainingSupplies = [700, 500, 300];
  uint[3] public currentIndexes = [0,700,1200]; // | 0 -> 699 | 700 -> 1199 | 1200 -> 1499 |
  uint public price;
  uint8 public maxBatch = 5;
  bool public startSale;
  
  string public baseURI;
  string _name = 'Koodos';
  string _symbol = '$KOODOS';
  mapping(address => uint) public tokenPerWallet;

  constructor(address payable _splitWallet, string memory _uri, uint _price) ERC721(_name, _symbol) {
    splitWallet =_splitWallet;
    baseURI = _uri;
    price = _price;
  }
  receive() payable external {}
  function _canMint(uint8 toMint, address to, bool allowed, bytes memory signature) view internal {
    if (allowed) {
      require(recover(to, allowed, signature), "Not allowListed");
    } else {
      require(startSale, "Public sale didn't start");
    }
    require(toMint <= maxBatch && toMint > 0, "Batch between 1 to 5");
    require(msg.value == price * toMint, "Wrong value");
    require((tokenPerWallet[to] < 5 && tokenPerWallet[to] + toMint <= 5), "Can mint 5 maximum"); //remove the true to bring back to limitation
  }
  function mint(uint8[3] calldata batch, uint8 sum, address to, bool allowed, bytes memory signature) payable external {
    _canMint(sum, to, allowed, signature);
    tokenPerWallet[to] += sum;
    for (uint256 index = 0; index < batch.length; index++) {
      if(batch[index] == 0) continue;
      uint8 tierToMint = batch[index];
      require(tierToMint <= 5, "maximum 5");
      _remainingSupplies[index] -= tierToMint;
      sum -= tierToMint;
      for (uint256 x = 0; x < tierToMint; x++) {
        _mint(to, currentIndexes[index]++);
      }
    }
    require(sum == 0, "Error with the batch and sum variable");
    uint256 contractBalance = msg.value;
    Address.sendValue(splitWallet, contractBalance);
  }
  function walletInventory(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }
  function emergencyWithdraw() external {
    uint256 contractBalance = address(this).balance;
    Address.sendValue(splitWallet, contractBalance);
  }
  function burn(uint256 tokenId) external {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId));
    _burn(tokenId);
  }
  function _baseURI() internal view virtual override returns (string memory){
    return baseURI;
  }
  function setBaseURI(string memory _newURI) external onlyOwner {
    baseURI = _newURI;
  }
  function setPrice(uint _price) external onlyOwner {
    price = _price;
  }
  function setStartSale(bool value) external onlyOwner {
    startSale = value;
  }
  function recover(address to, bool allowed, bytes memory signature) public view returns(bool) {
    bytes32 message = keccak256(abi.encodePacked(to, allowed)); 
    bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)); 
    return SignatureChecker.isValidSignatureNow(_backend, hash, signature);
  }
  function getRemainingSupplies() external view returns(uint[3] memory){
    return _remainingSupplies;
  }
}