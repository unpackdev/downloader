// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721AS.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract superBLOX is ERC721AS, Ownable, Pausable, ReentrancyGuard {
    
  using ECDSA for bytes32;

  uint256 public constant VIP_PRICE = 26900000000000000; //0.0269 ether;
  uint256 public constant FRENS_PRICE = 69000000000000000; //0.069 ether;
  uint256 public constant PUBLIC_PRICE = 89000000000000000; //0.089 ether;
  uint256 public constant FRENS_MAX_MINT = 2;
  uint256 public constant COLLECTION_SIZE = 9969;

  mapping(address => uint256) private _allocations;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721AS("superBLOX", "SB", maxBatchSize_,collectionSize_ ) {
         require(maxBatchSize_ > 0, "ERC721AS: max batch size must be nonzero");
           require(
      collectionSize_ > 0,
      "ERC721AS: collection must have a nonzero supply"
    );
  }

  //16 Feb 5 PM PST. Whoops! 8 PM EST. Actually
  uint256 public vipSaleStartTime = 1645232400000; 
  string private _baseTokenURI;

   function setVipSaleStartTime(uint256 _timestamp) external onlyOwner {
    vipSaleStartTime = _timestamp;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier vipSaleIsOn(){
    if(block.timestamp < vipSaleStartTime){
      revert('VIP sale has not started yet');
    }
    if(block.timestamp > (vipSaleStartTime + 1 days)){
      revert('The VIP sale has ended');
    }
    _;
  }

 function rejectInsufficientFunds(uint256 _totalPrice) private {
    require(msg.value == _totalPrice, "Wrong amount of ETH sent.");
  }


  function vipMint(uint256 quantity, uint256 allocation, bytes memory signature )
    external
    payable
    whenNotPaused
    callerIsUser
    vipSaleIsOn
  {
    require(quantity <= maxBatchSize, "Cannot mint this many at a time");
    require((totalSupply() + quantity) <= collectionSize, "Sold Out");

    checkVipSig(signature);

    if ( numberMinted(msg.sender) == 0 ){
      require( quantity <= allocation, 'You cannot mint this many');
      rejectInsufficientFunds(VIP_PRICE * quantity);
      _allocations[msg.sender]=allocation;
      _safeMint(msg.sender, quantity);
    }
    else {
      require(
        quantity <= _allocations[msg.sender],
        "You cannot mint this many"
      );
      rejectInsufficientFunds(VIP_PRICE * quantity);
      _safeMint(msg.sender, quantity);
    }
  }

// Frens should mint here, then mint public sale
  function frensMint(uint256 quantity, bytes memory signature )
    external
    payable
    whenNotPaused
    callerIsUser
  {
    require(block.timestamp > (vipSaleStartTime + 1 days), "The frens sale has not started");
    checkFrensSig(signature);
    require(totalSupply() + quantity <= collectionSize, "Sold Out");
    require(
      numberMinted(msg.sender) + quantity <= FRENS_MAX_MINT, // 2
      "cannot mint this many"
    );
    rejectInsufficientFunds(FRENS_PRICE * quantity);
    _safeMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity )
    external
    payable
    whenNotPaused
    callerIsUser
  {
    require(block.timestamp > (vipSaleStartTime + 1 days), "The public sale has not started");
    require(quantity <= maxBatchSize, "Cannot mint this many at a time");
    require(totalSupply() + quantity <= collectionSize, "Sold Out");
    rejectInsufficientFunds(PUBLIC_PRICE * quantity);
    _safeMint(msg.sender, quantity);
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function checkVipSig(bytes memory _signature)
    internal
    view
  {
    bytes32 messagehash = keccak256(
        abi.encodePacked(address(this), msg.sender, COLLECTION_SIZE)
    );
    address signer = messagehash.toEthSignedMessageHash().recover(
        _signature
    );
    require(owner()==signer, 'Invalid signature');
  }

  function checkFrensSig(bytes memory _signature)
    internal
    view
  {
    bytes32 messagehash = keccak256(
        abi.encodePacked(address(this), msg.sender)
    );
    address signer = messagehash.toEthSignedMessageHash().recover(
        _signature
    );
    require(owner()==signer, 'Invalid signature');
  }
}