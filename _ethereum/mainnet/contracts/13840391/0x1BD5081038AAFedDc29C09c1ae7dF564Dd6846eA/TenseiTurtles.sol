
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721EnumerableLite.sol";
import "./PaymentSplitterMod.sol";
import "./Strings.sol";

interface IERC20Proxy{
  function burnFromAccount( address account, uint leaves ) external payable;
  function mintToAccount( address[] calldata accounts, uint[] calldata leaves ) external payable;
}

interface IERC1155Proxy{
  function burnFrom( address account, uint[] calldata ids, uint[] calldata quantities ) external payable;
}

contract TenseiTurtles is ERC721B, Delegated, IERC721Batch, IERC721Enumerable, PaymentSplitterMod {
  using Strings for uint;

  event Evolve(address indexed owner, uint256 indexed tokenId);
  event Spawn(address indexed owner, uint256 indexed tokenId);

  enum TurtleType{
    Tensei,
    Meta,
    Hybrid
  }

  struct Turtle{
    address owner;
    TurtleType turtleType;
    uint32 nextBreed;
    uint32 lastStake;
  }

  uint public MAX_ORDER    = 2;
  uint public MAX_SUPPLY   = 1111;
  uint public MAX_WALLET   = 2;
  uint public PRICE        = 0.065 ether;

  uint32 public COOLDOWN_TENSEI = 259200; // 3 days
  uint32 public COOLDOWN_META   = 259200;

  uint32 public STAKE_PERIOD = 3600; // 1 hour
  uint public STAKE_TENSEI =  83333000000000000;  // 2000000000000000000 / 24
  uint public STAKE_META   = 208333000000000000;  // 5000000000000000000 / 24
  uint public STAKE_HYBRID = 208333000000000000;  // 5000000000000000000 / 24


  Turtle[] public turtles;

  bool public isPresaleActive = false;
  bool public isMintActive    = false;
  bool public isEvolveActive  = false;
  bool public isBreedActive   = false;
  bool public isStakeActive   = false;

  address public flaskAddress;
  uint public flaskToken;
  uint public flaskQuantity = 1;

  address public leafAddress;
  uint public leafEvolveQuantity = 0 ether;
  uint public leafBreedQuantity  = 210 ether;

  mapping(address => uint) public accessList;


  mapping(address => uint) private _balances;
  string private _tokenURIPrefix = 'https://ipfs.tenseiturtles.io/metadata/';
  string private _tokenURISuffix = '';

  address[] private addressList = [
    0x890903d07b5Db2FaDE12027E9B1AF16e5e6e0EA5,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  uint[] private shareList = [
    88,
    12
  ];

  constructor()
    ERC721B("Tensei Turtles", "TENSEI", 0)
    PaymentSplitterMod( addressList, shareList ){
  }

  //external
  fallback() external payable {}


  function balanceOf(address account) public view override( IERC721, ERC721B ) returns (uint) {
    require(account != address(0), "TENSEI: balance query for the zero address");
    return _balances[account];
  }

  function checkLeaf( uint tokenId ) public view returns( uint leaves ){
    require( isStakeActive,   "TENSEI: Staking is not active" );
    require(_exists(tokenId), "TENSEI: Query for nonexistent token");

    Turtle memory turtle = turtles[ tokenId ];
    if( turtle.lastStake < 2 )
      return 0;

    uint periods = (block.timestamp - turtle.lastStake)/STAKE_PERIOD;
    if( periods == 0 )
      return 0;


    if( turtle.turtleType == TurtleType.Tensei )
      return periods * STAKE_TENSEI;
    else if( turtle.turtleType == TurtleType.Meta )
      return periods * STAKE_META;
    else if( turtle.turtleType == TurtleType.Hybrid )
      return periods * STAKE_HYBRID;
    else
      return 0;
  }

  function checkLeaves( uint[] calldata tokenIds ) external view returns( uint totalLeaves_ ) {
    uint totalLeaves;
    for( uint i; i < tokenIds.length; ++i ){
      totalLeaves += checkLeaf( tokenIds[i] );
    }
    return totalLeaves;
  }

  function isOwnerOf( address account, uint[] calldata tokenIds ) external view virtual override returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( turtles[ tokenIds[i] ].owner != account )
        return false;
    }

    return true;
  }

  function ownerOf( uint tokenId ) public override( IERC721, ERC721B ) view returns( address owner_ ){
    address owner = turtles[tokenId].owner;
    require(owner != address(0), "TENSEI: query for nonexistent token");
    return owner;
  }

  function tokenByIndex(uint index) external view virtual override returns (uint) {
    require(index < totalSupply(), "TENSEI: global index out of bounds");
    return index;
  }

  function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint tokenId) {
    uint count;
    for( uint i; i < turtles.length; ++i ){
      if( owner == turtles[i].owner ){
        if( count == index )
          return i;
        else
          ++count;
      }
    }

    revert("ERC721Enumerable: owner index out of bounds");
  }

  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "TENSEI: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  function totalSupply() public override( IERC721Enumerable, ERC721B ) view returns( uint totalSupply_ ){
    return turtles.length;
  }

  function walletOfOwner( address account ) external view virtual override returns( uint[] memory ){
    uint quantity = balanceOf( account );
    uint[] memory wallet = new uint[]( quantity );
    for( uint i; i < quantity; ++i ){
        wallet[i] = tokenOfOwnerByIndex( account, i );
    }
    return wallet;
  }


  //non-payable
  function breed( uint turtleA, uint turtleB ) external {
    require( isBreedActive, "TENSEI: Breeding is not active" );
    require( _exists(turtleA) && _exists( turtleB ), "TENSEI: Query for nonexistent token(s)" );

    Turtle storage tensei;
    Turtle storage meta;
    if( turtles[ turtleA ].turtleType == TurtleType.Tensei ){
      if( turtles[ turtleB ].turtleType == TurtleType.Meta ){
        tensei = turtles[ turtleA ];
        meta = turtles[ turtleB ];
      }
      else
        revert( "Invalid combination" );
    }
    else if( turtles[ turtleA ].turtleType == TurtleType.Meta ){
      if( turtles[ turtleB ].turtleType == TurtleType.Tensei ){
        meta = turtles[ turtleA ];
        tensei = turtles[ turtleB ];
      }
      else
        revert( "Invalid combination" );
    }
    else{
      revert( "TENSEI: invalid combination" );
    }


    //verify cooldown
    uint32 time = uint32(block.timestamp);
    require( tensei.nextBreed < time && meta.nextBreed < time, "TENSEI: breeding cooldown active" );
    require( tensei.owner != msg.sender || meta.owner != msg.sender, "TENSEI: breeding of token that is not owned" );

    uint supply = totalSupply();
    require( supply + 1 <= MAX_SUPPLY, "TENSEI: Mint/order exceeds supply" );

    if( leafEvolveQuantity > 0 ){
      require( leafAddress != address(0), "TENSEI: Leaf contract unset" );
      IERC20Proxy( leafAddress ).burnFromAccount( msg.sender, leafEvolveQuantity );
    }

    tensei.nextBreed = time + COOLDOWN_TENSEI;
    tensei.nextBreed = time + COOLDOWN_META;
    _mint( msg.sender, supply, TurtleType.Hybrid );
    emit Spawn( msg.sender, supply );
  }

  function claimLeaves( uint[] calldata tokenIds ) external {
    require( isStakeActive,             "TENSEI: Staking is not active" );
    require( leafAddress != address(0), "TENSEI: Leaf contract unset" );

    uint tokenLeaves;
    Turtle storage turtle;
    uint32 time = uint32(block.timestamp);
    uint[] memory leaves = new uint[]( tokenIds.length );
    address[] memory owners = new address[]( tokenIds.length );
    for( uint i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]),      "TENSEI: Query for nonexistent token" );

      turtle = turtles[ tokenIds[i] ];
      require(turtle.owner == msg.sender, "TENSEI: Claiming token that is not owned");

      tokenLeaves = checkLeaf( tokenIds[i] );
      if( tokenLeaves > 0 ){
        leaves[ i ] = tokenLeaves;
        owners[ i ] = turtle.owner;
        turtle.lastStake = time;
      }
    }

    IERC20Proxy( leafAddress ).mintToAccount( owners, leaves );
  }

  function evolve( uint[] calldata tokenIds ) external {
    require( isEvolveActive,             "TENSEI: Evolution is not active" );

    if( flaskQuantity > 0 ){
      require( flaskAddress != address(0), "TENSEI: Flask contract unset" );

      uint[] memory tokens = new uint[]( 1 );
      tokens[0] = flaskToken;

      uint[] memory quantities = new uint[]( 1 );
      quantities[0] = tokenIds.length * flaskQuantity;

      IERC1155Proxy( flaskAddress ).burnFrom( msg.sender, tokens, quantities );
    }

    if( leafEvolveQuantity > 0 ){
      require( leafAddress != address(0), "TENSEI: Leaf contract unset" );
      IERC20Proxy( leafAddress ).burnFromAccount( msg.sender, leafEvolveQuantity * tokenIds.length );
    }

    Turtle storage turtle;
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]), "TENSEI: Query for nonexistent token" );

      turtle = turtles[tokenIds[i]];
      require(turtle.owner == msg.sender, "TENSEI: Evolving token that is not owned");
      require(turtle.turtleType == TurtleType.Tensei, "TENSEI: Only Tensei turtles can evolve" );

      turtle.turtleType = TurtleType.Meta;
      emit Evolve( msg.sender, tokenIds[i] );
    }
  }

  function setStake( uint[] calldata tokenIds, bool isSet ) external {
    require( isStakeActive, "TENSEI: Staking is not active" );

    Turtle storage turtle;
    uint32 time = uint32(block.timestamp);
    for( uint i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]), "TENSEI: Query for nonexistent token" );

      turtle = turtles[ tokenIds[i] ];
      require(turtle.owner == msg.sender, "TENSEI: Staking token that is not owned");

      turtle.lastStake = isSet ? time : 1;
    }
  }

  function transferBatch( address from, address to, uint[] calldata tokenIds, bytes calldata data ) external override{
    for(uint i; i < tokenIds.length; ++i ){
      safeTransferFrom( from, to, tokenIds[i], data );
    }
  }


  //payable
  function mint( uint quantity ) external payable {
    if( isMintActive ){
    }
    else if( isPresaleActive ){
      require( accessList[ msg.sender ] >= quantity, "TENSEI: Account is not on the access list" );
      accessList[ msg.sender ] -= quantity;
    }
    else{
      revert( "TENSEI: Sale is not active" );
    }

    require( quantity <= MAX_ORDER, string(abi.encodePacked("TENSEI: Max order is ", MAX_ORDER.toString())) );
    require( balanceOf(msg.sender) + quantity <= MAX_WALLET, string(abi.encodePacked("TENSEI: Max per wallet is ", MAX_WALLET.toString())) );
    require( msg.value >= PRICE * quantity, "TENSEI: Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "TENSEI: Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++, TurtleType.Tensei );
    }
  }


  //onlyDelegates
  function mint_(uint[] calldata quantity, address[] calldata recipient, TurtleType[] calldata types_ ) external payable onlyDelegates{
    require(quantity.length == recipient.length, "TENSEI: Must provide equal quantities and recipients" );
    require(recipient.length == types_.length,   "TENSEI: Must provide equal recipients and types" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_SUPPLY, "TENSEI: Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        uint tokenId = supply++;
        _mint( recipient[i], tokenId, types_[i] );

        if( types_[i] == TurtleType.Meta ){
          emit Evolve( recipient[i], tokenId );
        }
        else if( types_[i] == TurtleType.Hybrid ){
          emit Spawn( recipient[i], tokenId );
        }
      }
    }
  }

  function evolve_(address account, uint[] calldata tokenIds) external payable onlyDelegates{
    for(uint i; i < tokenIds.length; ++i){
      require( _exists( tokenIds[i] ),            "TENSEI: Query for nonexistent token");
      require( ownerOf( tokenIds[i] ) == account, "TENSEI: Evolution of token that is not owned" );
      require( turtles[tokenIds[i]].turtleType == TurtleType.Tensei, "TENSEI: Only Tensei turtles can evolve" );

      turtles[tokenIds[i]].turtleType = TurtleType.Meta;
      emit Evolve( account, tokenIds[i] );
    }
  }

  function breed_( address account, uint quantity ) external payable onlyDelegates{
    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "TENSEI: Mint/order exceeds supply" );

    for( uint i; i < quantity; ++i ){
      uint tokenId = supply++;
      _mint( account, tokenId, TurtleType.Hybrid );
      emit Spawn( account, tokenId );
    }
  }

  function stake_( address account, uint[] calldata tokenIds, bool isSet ) external payable onlyDelegates{
    require( isStakeActive, "TENSEI: Staking is not active" );

    Turtle storage turtle;
    uint32 time = uint32(block.timestamp);
    for( uint i; i < tokenIds.length; ++i ){
      require( _exists(tokenIds[i]), "TENSEI: Query for nonexistent token" );

      turtle = turtles[ tokenIds[i] ];
      require(turtle.owner == account, "TENSEI: staking token that is not owned");

      turtle.lastStake = isSet ? time : 1;
    }
  }

  function setNextBreeds(uint[] calldata tokenIds, uint32[] calldata nextBreeds ) external onlyDelegates {
    for(uint i; i < tokenIds.length; ++i ){
      require(_exists(tokenIds[i]), "TENSEI: Query for nonexistent token");
      turtles[tokenIds[i]].nextBreed = nextBreeds[i];
    }
  }

  function setAccessList(address[] calldata accounts, uint[] calldata allowed) external onlyDelegates{
    require( accounts.length == allowed.length, "TENSEI: Must provide equal accounts and allowed" );
    for(uint i; i < accounts.length; ++i){
      accessList[ accounts[i] ] = allowed[i];
    }
  }

  function setActive(bool isPresaleActive_, bool isMintActive_, bool isEvolveActive_, bool isBreedActive_) external onlyDelegates{
    require( isPresaleActive != isPresaleActive_ ||
      isMintActive != isMintActive_ ||
      isEvolveActive != isEvolveActive_ ||
      isBreedActive != isBreedActive_, "TENSEI: New value matches old" );
    isPresaleActive = isPresaleActive_;
    isMintActive = isMintActive_;
    isEvolveActive = isEvolveActive_;
    isBreedActive = isBreedActive_;
  }

  function setBaseURI(string calldata prefix, string calldata suffix) external onlyDelegates{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }

  function setCooldown(uint32 tenseiCooldown, uint32 metaCooldown) external onlyDelegates{
    require( COOLDOWN_TENSEI != tenseiCooldown || COOLDOWN_META != metaCooldown, "TENSEI: New value matches old" );
    COOLDOWN_TENSEI = tenseiCooldown;
    COOLDOWN_META = metaCooldown;
  }

  function setMaxOrder(uint maxOrder, uint maxSupply, uint maxWallet) external onlyDelegates{
    require( MAX_ORDER != maxOrder || MAX_SUPPLY != maxSupply || MAX_WALLET != maxWallet, "TENSEI: New value matches old" );
    require( maxSupply >= totalSupply(), "TENSEI: Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_WALLET = maxWallet;
  }

  function setFlask( address flaskAddress_, uint flaskToken_, uint flaskQuantity_ ) external onlyDelegates{
    flaskAddress = flaskAddress_;
    flaskToken = flaskToken_;
    flaskQuantity = flaskQuantity_;
  }

  function setLeaf( address leafAddress_, uint leafEvolveQuantity_, uint leafBreedQuantity_ ) external onlyDelegates{
    leafAddress = leafAddress_;
    leafEvolveQuantity = leafEvolveQuantity_;
    leafBreedQuantity = leafBreedQuantity_;
  }

  function setPrice(uint price) external onlyDelegates{
    require( PRICE != price, "TENSEI: New value matches old" );
    PRICE = price;
  }

  function setStakeOptions( bool isActive, uint32 period, uint tenseiLeaf, uint metaLeaf, uint hybridLeaf ) external onlyDelegates{
    isStakeActive = isActive;

    STAKE_PERIOD = period;
    STAKE_TENSEI = tenseiLeaf;
    STAKE_META   = metaLeaf;
    STAKE_HYBRID = hybridLeaf;
  }

  function setTurtle(uint[] calldata tokenIds, TurtleType[] calldata types,
    uint32[] calldata nextBreeds, uint32[] calldata lastStakes ) external onlyDelegates {

    Turtle storage turtle;
    for(uint i; i < tokenIds.length; ++i ){
      require(_exists(tokenIds[i]), "TENSEI: Query for nonexistent token");

      turtle = turtles[tokenIds[i]];
      turtle.turtleType = types[i];
      turtle.nextBreed  = nextBreeds[i];
      turtle.lastStake  = lastStakes[i];
    }
  }


  //onlyOwner
  function addPayee( address account, uint shares ) external onlyOwner {
    _addPayee( account, shares );
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee( index, account, newShares );
  }


  //internal
  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
    if( from != address(0) )
      --_balances[ from ];

    if( to != address(0) )
      ++_balances[ to ];
  }

  function _exists(uint tokenId) internal view override returns (bool) {
    return tokenId < turtles.length && turtles[tokenId].owner != address(0);
  }

  function _mint(address to, uint tokenId, TurtleType type_ ) internal {
    _beforeTokenTransfer(address(0), to, tokenId);
    turtles.push(Turtle( to, type_, 0, 0 ));
    emit Transfer(address(0), to, tokenId);
  }

  function _transfer(address from, address to, uint tokenId) internal override {
    require(turtles[tokenId].owner == from, "TENSEI: transfer of token that is not owned");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _beforeTokenTransfer(from, to, tokenId);

    turtles[tokenId].owner = to;
    emit Transfer(from, to, tokenId);
  }
}
