pragma solidity ^0.8.0;

import "./TTT.sol";
import "./MerkleProof.sol";

contract TTTSaleTwo is Ownable {
  using Strings for string;
  using SafeMath for uint256;

  address public tttAddress;
  bytes32 public holderRoot;
  bytes32 public whitelistRoot;

  uint256 price = 20000000000000000;
  uint256 preSaleQuantity = 6666;
  uint256 totalQuantity = 7777;
  uint256 publicSaleDate = 1640070000;

  mapping(address => uint) private holderQuantityMinted;
  mapping(address => bool) private wlHasMinted;

  constructor(address _tttAddress, bytes32 whitelistMerkleRoot, bytes32 holderMerkleRoot) {
    tttAddress = _tttAddress;

    holderRoot = holderMerkleRoot;
    whitelistRoot = whitelistMerkleRoot;
  }

  function getBalance() public onlyOwner view returns (uint256) {
    return address(this).balance;
  }

  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner()).transfer(amount);
  }

  function addressHasWLMinted(address _address) private view returns (bool) {
    return wlHasMinted[_address];
  }

  function hasAllotment(address _address, uint256 _quantity, uint256 maxQuantity) private view returns (bool){
    return (maxQuantity - holderQuantityMinted[_address] - _quantity) >= 0;
  }

  function holderMint(address _toAddress, uint256 _quantity, uint256 maxQuantity, bytes32[] calldata proof) public payable{
    TTT newTTT = TTT(tttAddress);
    uint256 tttSupply = newTTT.getCurrentTokenId();

    require(block.timestamp < publicSaleDate, 'The pre-sale has finished');
    require(tttSupply + _quantity <= preSaleQuantity, 'Attempted quantity to mint exceeds total pre-sale supply if minted');
    require(msg.value >= (_quantity * price), 'Value below price');
    require(hasAllotment(_toAddress, _quantity, maxQuantity), 'You have exceeded your allowed Tot mints');

    require(_holderVerify(_holderLeaf(_toAddress, maxQuantity), proof), "Invalid merkle proof");

    for (uint256 i = 0; i < _quantity; i++) {
      newTTT.mintTo(_toAddress);
    }

    holderQuantityMinted[_toAddress] += _quantity;
  }

  function whitelistMint(uint256 _quantity, bytes32[] calldata proof) public payable{
    TTT newTTT = TTT(tttAddress);
    uint256 tttSupply = newTTT.getCurrentTokenId();

    require(block.timestamp < publicSaleDate, 'The pre-sale has finished');
    require(_quantity <= 5, 'Quantity exceeds allotted 5');
    require(tttSupply + _quantity <= preSaleQuantity, 'Attempted quantity to mint exceeds total pre-sale supply if minted');
    require(msg.value >= (_quantity * price), 'Value below price');
    require(!addressHasWLMinted(msg.sender), 'address has already minted');

    require(_whitelistVerify(_whitelistLeaf(msg.sender), proof), "Invalid merkle proof");

    for (uint256 i = 0; i < _quantity; i++) {
      newTTT.mintTo(msg.sender);
    }

    wlHasMinted[msg.sender] = true;
  }

  function mint(address _toAddress, uint256 _quantity) public payable{
    require(block.timestamp >= publicSaleDate, 'Public sale has not started');
    require(msg.value >= (_quantity * price), 'Value below price');

    TTT newTTT = TTT(tttAddress);
    uint256 tttSupply = newTTT.getCurrentTokenId();
    require(tttSupply + _quantity < totalQuantity, 'Attempted quantity to mint exceeds total supply if minted');

    for (uint256 i = 0; i < _quantity; i++) {
      newTTT.mintTo(_toAddress);
    }
  }

  function updatePreSaleQuantity(uint256 _quantity) public onlyOwner{
    preSaleQuantity = _quantity;
  }

  function updatePublicSaleDate(uint256 _newPublicSaleDate) public onlyOwner{
    publicSaleDate = _newPublicSaleDate;
  }

  function getCurrentToken() public view returns (uint256) {
    TTT newTTT = TTT(tttAddress);
    uint256 currentToken = newTTT.getCurrentTokenId();

    return (currentToken);
  }

  function getQuantityMintedByHolder(address _address) public view returns (uint256) {
    uint256 quantityMinted = holderQuantityMinted[_address];

    return (quantityMinted);
  }

  function _whitelistLeaf(address account)
  internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account));
  }

  function _whitelistVerify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
    return MerkleProof.verify(proof, whitelistRoot, leaf);
  }

  function _holderLeaf(address account, uint256 maxQuantity)
  internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, maxQuantity));
  }

  function _holderVerify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
    return MerkleProof.verify(proof, holderRoot, leaf);
  }

  function updateWhiteListRoot(bytes32 newRoot)public onlyOwner{
    whitelistRoot = newRoot;
  }

  function updateHolderRoot(bytes32 newRoot)public onlyOwner{
    holderRoot = newRoot;
  }
}
