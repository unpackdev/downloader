// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
contract RoyalCats is Ownable, ERC721A {
constructor() ERC721A("RoyalCats", "RoyalCats") {}
uint256 private _mint_price = 0.05 ether;
uint256 private _public_minting_limit = 3;
uint256 private _tokens_supply = 5555;
bytes32 private merkle_root = 0;
uint private _premint_date = 1653980400;
uint private _premint_duration = 1 days;
uint private _public_mint_date = 1653980400 + 1 days;
struct specialUrl{
 string url;
 bool isSet;
}
mapping(uint256 => specialUrl) special_tokens;

function mint_requirements(uint256 mint_quantity,uint256 free_quantity) private view {
 bool minting_available = (block.timestamp >= _premint_date) && ((block.timestamp <= _premint_date + _premint_duration) || (block.timestamp >= _public_mint_date));
 require( minting_available , "minting is unavailable");
 require(_totalMinted() + mint_quantity + free_quantity <= _tokens_supply, "Ran out of supply..");
 require(msg.value >= _mint_price*mint_quantity, "Not enough ETH sent; check price!");
}

function mint(uint256 mint_quantity,uint256 free_quantity) external payable {
 mint_requirements(mint_quantity,free_quantity); 
 require(block.timestamp >= _public_mint_date, "minting is unavailable");
 uint64 number_free_minted = _getAux(msg.sender);
 uint256 number_regular_minted = _numberMinted(msg.sender)-number_free_minted;
 require(number_regular_minted + mint_quantity <=  _public_minting_limit, "max mint amount reached");
 if (mint_quantity >= _public_minting_limit){
     require(number_free_minted +free_quantity <= 1, "max mint amount reached");
 }
 else{
     require(number_free_minted +free_quantity <= 0, "max free mint amount reached");
 }
 _setAux(msg.sender,uint64(number_free_minted + free_quantity));
 _safeMint(msg.sender, mint_quantity+free_quantity);
}
function mintWhitelist(uint256 mint_quantity,uint256 free_quantity,uint256 free_mints_allowed,uint256 premints_allowed,bytes32[] calldata _merkleProofs) external payable {
 mint_requirements(mint_quantity,free_quantity);
 bytes32 leaf = keccak256(abi.encodePacked(_prepare_proof(free_mints_allowed,premints_allowed,free_mints_allowed+premints_allowed)));
 require(MerkleProof.verify(_merkleProofs, merkle_root, leaf), "bad proof..");
 uint64 number_free_minted = _getAux(msg.sender);
 uint256 number_regular_minted = _numberMinted(msg.sender)-number_free_minted;
 if(block.timestamp >= _public_mint_date){
   require(number_regular_minted + mint_quantity <= premints_allowed + _public_minting_limit, "max mint amount reached");
   if (mint_quantity >= _public_minting_limit){
       require(number_free_minted +free_quantity <= free_mints_allowed + 1, "max mint amount reached");
   }
   else{
       require(number_free_minted +free_quantity <= free_mints_allowed, "max free mint amount reached");
   }
 }
 else{
   require(number_regular_minted + mint_quantity <= premints_allowed, "max premint amount reached");
   require(number_free_minted +free_quantity <= free_mints_allowed, "max free mint amount reached");
 }
 _setAux(msg.sender,uint64(number_free_minted + free_quantity));
 _safeMint(msg.sender, mint_quantity+free_quantity);
}
function _prepare_proof(uint256 free_mints_allowed,uint256 premints_allowed,uint256 total) private view returns (string memory){
  string memory addr = Strings.toHexString(uint256(uint160(msg.sender)));
  string memory delim = '_';
  string memory free = Strings.toString(free_mints_allowed);
  string memory max_pre = Strings.toString(premints_allowed);
  string memory max_pub = Strings.toString(total);
  return string(abi.encodePacked(addr,delim,free,delim,max_pre,delim,max_pub));
}
function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
 merkle_root = merkleRoot;
}
function setPremintDate(uint premint_date) external onlyOwner {
 _premint_date = premint_date;
}
function setPremintDuration(uint premint_duration) external onlyOwner {
 _premint_duration = premint_duration;
}
function setPublicMintDate(uint public_mint_date) external onlyOwner {
 _public_mint_date = public_mint_date;
}
function setMintPrice(uint256 mint_price) external onlyOwner {
 _mint_price = mint_price;
}
function setMaxMintQuantityPerAddress(uint256 max_mint_quantity_per_address) external onlyOwner {
 _public_minting_limit = max_mint_quantity_per_address;
}
function setMaxSupply(uint256 max_supply) external onlyOwner {
 _tokens_supply = max_supply;
}
// metadata URI
string private _baseTokenURI;
function _baseURI() internal view virtual override returns (string memory) {
 return _baseTokenURI;
}
function setBaseURI(string calldata baseURI) external onlyOwner {
 _baseTokenURI = baseURI;
}
function withdraw(uint256 amount) external payable onlyOwner {
   (bool success, ) = payable(msg.sender).call{
   value: amount < address(this).balance  ? amount : address(this).balance
   }("");
   require(success);
}
/**
 * To change the starting tokenId, please override this function.
 */
function _startTokenId() internal view virtual override returns (uint256) {
 return 1;
}
function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
   if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
   if (special_tokens[tokenId].isSet){
     return special_tokens[tokenId].url;
   }
   string memory baseURI = _baseURI();
   return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '';
}
function setSpecialTokens(uint256[] memory tokenIds, string[] memory specialTokenUrls) external onlyOwner {
 for (uint256 i = 0; i < specialTokenUrls.length; i++) {
   special_tokens[tokenIds[i]].url = specialTokenUrls[i];
   special_tokens[tokenIds[i]].isSet = true;
 }
}
}
