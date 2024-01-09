pragma solidity ^0.8.0;

import "./TTT.sol";
import "./MerkleProof.sol";

contract TTTSale is Ownable {
  using Strings for string;
  using SafeMath for uint256;

  address public tttAddress;
  bytes32 remintRoot;
  bytes32 freeMintRoot;
  bytes32 whitelistRoot;
  bool isRemintOpen = true;
  uint256 price = 20000000000000000;
  uint256 totalQuantity = 7777;
  uint256 preSaleDate = 1643936400;
  uint256 publicSaleDate = 1644282000;
  uint256 preSaleMintLimit = 6;
  uint256 normalMintLimit = 21;

  mapping(address => bool) private holderHasReminted;
  mapping(address => uint) private holderFreeMintsUsed;
  mapping(address => bool) private wlHasMinted;

  constructor(address _tttAddress, bytes32 _remintMerkleRoot, bytes32 _freeMintMerkleRoot, bytes32 whitelistMerkleRoot) {
    tttAddress = _tttAddress;
    remintRoot = _remintMerkleRoot;
    freeMintRoot = _freeMintMerkleRoot;
    whitelistRoot = whitelistMerkleRoot;
  }

  function getBalance() public onlyOwner view returns (uint256) {
    return address(this).balance;
  }

  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner()).transfer(amount);
  }

  function withdrawPartial(uint256 _amount) public onlyOwner {
    payable(owner()).transfer(_amount);
  }

  function addressHasReminted(address _address) private view returns (bool) {
    return holderHasReminted[_address];
  }

  function addressHasWLMinted(address _address) private view returns (bool) {
    return wlHasMinted[_address];
  }

  function hasFreeMintsAvailable(address _address, uint256 _quantity, uint256 maxQuantity) private view returns (bool){
    return (maxQuantity - holderFreeMintsUsed[_address] - _quantity) >= 0;
  }

  function remint(address _toAddress, uint256[] calldata _tokens, bytes32[] calldata _proof) public {
    require(isRemintOpen == true, "Reminting is closed");
    require(!addressHasReminted(_toAddress), 'Address has already reminted');
    require(_remintVerify(_remintLeaf(_toAddress, _tokens), _proof), "Invalid merkle proof");
    TTT newTTT = TTT(tttAddress);
    for (uint i = 0; i < _tokens.length; i++){
      newTTT.reMint(_toAddress, _tokens[i]);
    }
    holderHasReminted[_toAddress] = true;
  }

  function freeMint(address _toAddress, uint256 _quantity, uint256 _maxQuantity, bytes32[] calldata _proof) public{
    TTT newTTT = TTT(tttAddress);
    uint256 tttSupply = newTTT.getCurrentTokenId();
    require(block.timestamp < publicSaleDate, 'The free mint period has ended');
    require(tttSupply + _quantity <= totalQuantity, 'Attempted quantity to mint exceeds total supply if minted');
    require(hasFreeMintsAvailable(_toAddress, _quantity, _maxQuantity), 'This will exceed your allowed free Tot mints');
    require(_freeMintVerify(_freeMintLeaf(_toAddress, _maxQuantity), _proof), "Invalid merkle proof");
    newTTT.bulkMint(_toAddress, _quantity);
    holderFreeMintsUsed[_toAddress] = holderFreeMintsUsed[_toAddress].add(_quantity);
  }

  function combinedRemintAndFreeMint(address _toAddress, uint256[]  calldata _remintTokens, bytes32[] calldata _remintProof,
    uint256 _freeMintQuantity, uint256 _freeMintMaxQuantity, bytes32[] calldata _freeMintProof) public
  {
    remint(_toAddress, _remintTokens, _remintProof);
    freeMint(_toAddress, _freeMintQuantity, _freeMintMaxQuantity, _freeMintProof);
  }

  function whitelistMint(uint256 _quantity, bytes32[] calldata proof) public payable{
    TTT newTTT = TTT(tttAddress);
    uint256 tttSupply = newTTT.getCurrentTokenId();
    require(block.timestamp > preSaleDate, 'Pre-sale has not started yet');
    require(_quantity < preSaleMintLimit, 'Quantity exceeds allowed pre-sale quantity');
    require(tttSupply + _quantity < totalQuantity, 'Attempted quantity to mint exceeds total supply if minted');
    require(msg.value >= (_quantity * price), 'Value below price');
    require(!addressHasWLMinted(msg.sender), 'address has already minted for pre-sale');
    require(_whitelistVerify(_whitelistLeaf(msg.sender), proof), "Invalid merkle proof");
    for (uint256 i = 0; i < _quantity; i++) {
      newTTT.mintTo(msg.sender);
    }
    wlHasMinted[msg.sender] = true;
  }

  function mint(address _toAddress, uint256 _quantity) public payable{
    require(block.timestamp >= publicSaleDate, 'Public sale has not started');
    require(msg.value >= (_quantity * price), 'Value below price');
    require(_quantity < normalMintLimit, 'Quantity exceeds amount allowed per transaction');
    TTT newTTT = TTT(tttAddress);
    uint256 tttSupply = newTTT.getCurrentTokenId();
    require(tttSupply + _quantity < totalQuantity, 'Attempted quantity to mint exceeds total supply if minted');

    for (uint256 i = 0; i < _quantity; i++) {
      newTTT.mintTo(_toAddress);
    }
  }

  function bulkMint(address _toAddress, uint256 _quantity) public payable{
    require(block.timestamp >= publicSaleDate, 'Public sale has not started');
    require(msg.value >= (_quantity * price), 'Value below price');
    TTT newTTT = TTT(tttAddress);
    require(_quantity < normalMintLimit, 'Quantity exceeds amount allowed per transaction');
    uint256 tttSupply = newTTT.getCurrentTokenId();
    require(tttSupply + _quantity < totalQuantity, 'Attempted quantity to mint exceeds total supply if minted');
    newTTT.bulkMint(_toAddress, _quantity);
  }

  function updatePreSaleMintLimit(uint256 _quantity) public onlyOwner {
    preSaleMintLimit = _quantity;
  }

  function updatePublicSaleDate(uint256 _newPublicSaleDate) public onlyOwner {
    publicSaleDate = _newPublicSaleDate;
  }

  function getCurrentToken() public view returns (uint256) {
    TTT newTTT = TTT(tttAddress);
    uint256 currentToken = newTTT.getCurrentTokenId();
    return (currentToken);
  }

  function getMinterInformation(address _address) public view returns (uint256, bool, bool) {
    bool hasReminted = addressHasReminted(_address);
    uint256 freeMintsRedeemed = holderFreeMintsUsed[_address];
    bool wlHasMintedBool = wlHasMinted[_address];
    return (freeMintsRedeemed, hasReminted, wlHasMintedBool);
  }

  function _remintLeaf(address account, uint256[] memory _tokens)
  internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, _tokens));
  }

  function _remintVerify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
    return MerkleProof.verify(proof, remintRoot, leaf);
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

  function _freeMintLeaf(address account, uint256 maxQuantity)
  internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, maxQuantity));
  }

  function _freeMintVerify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
    return MerkleProof.verify(proof, freeMintRoot, leaf);
  }

  function updateWhiteListRoot(bytes32 newRoot) public onlyOwner {
    whitelistRoot = newRoot;
  }

  function updateRemintRoot(bytes32 newRoot) public onlyOwner {
    remintRoot = newRoot;
  }

  function updateFreeMintRoot(bytes32 newRoot) public onlyOwner {
    freeMintRoot = newRoot;
  }

  function updateIsRemintOpen(bool _isRemintOpen) public onlyOwner {
    isRemintOpen = _isRemintOpen;
  }

  function updateTotalQuantity(uint256 _quantity) public onlyOwner {
    totalQuantity = _quantity;
  }

  function updateNormalMintLimit(uint256 _quantity) public onlyOwner {
    normalMintLimit = _quantity;
  }
}
