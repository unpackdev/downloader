
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Signed.sol";
import "./IPowerPass1155.sol";
import "./AM721Batch.sol";

abstract contract MetaciplesCore is AM721Batch, Signed {
  using Strings for uint;

  struct PowerPass {
    address contractAddress;
    uint8 tokenId;
    bool canBurn;
  }

  struct Recipe{
    uint16 powerPassId;
    uint8 quantity;
  }

  event Mint( address indexed to, bytes32 indexed recipeId, uint256 indexed tokenId );

  uint public MAX_SUPPLY = 10000;
  uint public PRICE      = 0;

  bool public isActive   = false;
  mapping(uint => PowerPass) public proxies;

  string private _tokenURIPrefix = '';
  string private _tokenURISuffix = '';


  //safety first
  fallback() external payable {}

  receive() external payable {}

  function withdraw() external {
    require(address(this).balance >= 0, "AvatarMaker: No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //non-payable
  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "AvatarMaker: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //payable
  function mint( bytes32 recipeId, bytes calldata recipeData, bytes calldata signature ) external payable {
    require( isActive, "AvatarMaker: Mint is not active" );
    verifySignature( recipeId, string( recipeData ), signature );

    Recipe[] memory recipes = abi.decode( recipeData, (Recipe[]));
    for(uint i; i < recipes.length; ++i ){
      Recipe memory recipe = recipes[i];
      PowerPass memory proxy = proxies[ recipe.powerPassId ];
      require( proxy.contractAddress != address(0), "AvatarMaker: PowerPass is unset" );

      if( proxy.canBurn )
        IPowerPass1155( proxy.contractAddress ).burnFrom( proxy.tokenId, recipe.quantity, msg.sender );
    }

    uint tokenId = totalSupply();
    _mint( msg.sender, tokenId );
    emit Mint( msg.sender, recipeId, tokenId );
  }

  //onlyDelegates
  function mintTo(address[] calldata recipients, bytes32[] calldata recipeIds) external payable onlyDelegates{
    require( recipients.length == recipeIds.length, "AvatarMaker: Must provide equal quantities and recipients" );

    uint supply = totalSupply();
    require( supply + recipients.length < MAX_SUPPLY, "AvatarMaker: Mint/order exceeds supply" );

    for(uint i; i < recipients.length; ++i){
      uint tokenId = supply++;
      _mint( recipients[i], tokenId );
      emit Mint( msg.sender, recipeIds[i], tokenId );
    }
  }

  function setActive(bool isActive_) public onlyDelegates{
    isActive = isActive_;
  }

  function setBaseURI(string calldata _newPrefix, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newPrefix;
    _tokenURISuffix = _newSuffix;
  }

  function setMax(uint maxSupply) external onlyDelegates{
    require( maxSupply >= totalSupply(), "AvatarMaker: Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

  function setPrice(uint price ) external onlyDelegates{
    PRICE = price;
  }

  function setProxy(uint powerPassId, address powerPassProxy, uint8 tokenId, bool canBurn ) public onlyDelegates{
    proxies[powerPassId] = PowerPass(
      powerPassProxy,
      tokenId,
      canBurn
    );
  }


  //internal
  function _mint(address to, uint tokenId) internal override {
    require(to != address(0), "ERC721: mint to the zero address");
    _beforeTokenTransfer(address(0), to);
    _owners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  function createHash( bytes32 recipeId, string memory recipeData ) internal view returns ( bytes32 ){
    return keccak256( abi.encodePacked( address(this), msg.sender, recipeId, recipeData, _secret ) );
  }

  function verifySignature( bytes32 recipeId, string memory recipeData, bytes calldata signature ) internal view {
    address extracted = getSigner( createHash( recipeId, recipeData ), signature );
    require( isAuthorizedSigner( extracted ), "Signature verification failed" );
  }
}
