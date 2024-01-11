// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract HIDDENSTONEZ is Ownable, ERC721A {
  constructor() ERC721A("HiddenStonez", "HIDDENSTONEZ") {}

  uint256 private constant _wei_price = 0.007 ether;
  uint256 private constant _free_mint_quantity = 1000;
  uint256 private constant _max_mint_quantity_per_address = 30;
  uint256 private constant _max_supply = 3000;
  bytes32 public merkle_root = 0x00;

  function mint(uint256 quantity) external payable {

    uint256 minted = _totalMinted();
    require(minted + quantity <= _max_supply, "Ran out of supply..");
    if (minted > _free_mint_quantity){
      require(msg.value >= _wei_price*quantity, "Not enough ETH sent; check price!");
    }

    require(_max_mint_quantity_per_address >= quantity + _numberMinted(msg.sender) , "Max minting per account exceeded");
    
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);
  }


  function mintWhitelist(bytes32[] calldata _merkleProofs, uint256 quantity) external payable {

    uint256 minted = _totalMinted();
    require(minted + quantity <= _max_supply, "Ran out of supply..");
    
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProofs, merkle_root, leaf));

    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);
  }

  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    merkle_root = merkleRoot;
  }

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  

  /**
    * To change the starting tokenId, please override this function.
    */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

}