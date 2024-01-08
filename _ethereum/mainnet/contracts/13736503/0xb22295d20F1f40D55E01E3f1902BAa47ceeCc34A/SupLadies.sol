
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
import "./ERC721EnumerableB.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

interface IERC721Proxy{
  function balanceOf( address account ) external view returns ( uint quantity );
  function ownerOf( uint tokenId ) external view returns ( address owner );
}

interface IPPL20{
  function burnFromAccount( address account, uint pineapples ) external;
  function burnFromTokens( address[] calldata tokenContracts, uint[] calldata tokenIds, uint pineapples ) external;
}

contract SupLadies is Delegated, ERC721EnumerableB, PaymentSplitter {
  using Strings for uint;

  uint public MAX_ORDER  = 19;
  uint public MAX_SUPPLY = 3914;
  uint public MAX_VOUCHERS = 1957;
  uint public ETH_PRICE  = 0.1957 ether;
  uint public PPL_PRICE  = 19.57 ether;

  bool public isMintActive = false;
  bool public isPineapplesActive = false;
  bool public isVoucherMintActive = false;
  bool public isVoucherUseActive = false;

  address public ahmcAddress = 0x61DB9Dde04F78fD55B0B4331a3d148073A101850;
  address public artwAddress = 0x22d202872950782012baC53346EE3DaE3D78E0CB;
  address public pineapplesAddress = 0x3e51F6422e41915e96A0808d21Babb83bcd278e5;

  mapping(address => uint) public vouchers;
  uint public voucherCount;

  string private _tokenURIPrefix;
  string private _tokenURISuffix;

  address[] private addressList = [
    0x13d86B7a637B9378d3646FA50De24e4e8fd78393,
    0xc9241a5e35424a927536D0cA30C4687852402bCB,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    57,
    35,
    8
  ];

  constructor()
    Delegated()
    ERC721B("SupLadies", "SL", 0)
    PaymentSplitter( addressList, shareList ){
  }

  //external
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isMintActive,                      "ETH sale is not active" );
    require( quantity <= MAX_ORDER,             "Order too big" );
    require( msg.value >= ETH_PRICE * quantity, "Ether sent is not correct" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  function mintWithPineapplesAccount( uint quantity ) external {
    require( isPineapplesActive,    "Pineapple sale is not active" );
    require( quantity <= MAX_ORDER, "Order too big" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Order exceeds supply" );
    _requireBalances();

    uint totalPineapples = PPL_PRICE * quantity;
    IPPL20( pineapplesAddress ).burnFromAccount( msg.sender, totalPineapples);
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  function mintWithPineapplesTokens( uint quantity, address[] calldata tokenContracts, uint[] calldata tokenIds ) external {
    require( isPineapplesActive,    "Pineapple sale is not active" );
    require( quantity <= MAX_ORDER, "Order too big" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Order exceeds supply" );
    _requireBalances();
    _requireOwnership( tokenContracts, tokenIds );

    uint totalPineapples = PPL_PRICE * quantity;
    IPPL20( pineapplesAddress ).burnFromTokens(tokenContracts, tokenIds, totalPineapples);
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  function mintVouchersFromAccount( uint quantity ) external {
    require( isVoucherMintActive,   "Voucher sale is not active" );
    require( quantity <= MAX_ORDER, "Order too big" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,         "Order exceeds supply" );
    require( voucherCount + quantity <= MAX_VOUCHERS, "Order exceeds supply" );
    _requireBalances();

    uint totalPineapples = PPL_PRICE * quantity;
    IPPL20( pineapplesAddress ).burnFromAccount( msg.sender, totalPineapples);

    voucherCount += quantity;
    vouchers[ msg.sender ] += quantity;
  }

  function mintVouchersFromTokens( uint quantity, address[] calldata tokenContracts, uint[] calldata tokenIds ) external {
    require( isVoucherMintActive,   "Voucher sale is not active" );
    require( quantity <= MAX_ORDER, "Order too big" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,         "Order exceeds supply" );
    require( voucherCount + quantity <= MAX_VOUCHERS, "Order exceeds supply" );
    _requireBalances();
    _requireOwnership( tokenContracts, tokenIds );

    uint totalPineapples = PPL_PRICE * quantity;
    IPPL20( pineapplesAddress ).burnFromTokens(tokenContracts, tokenIds, totalPineapples);

    voucherCount += quantity;
    vouchers[ msg.sender ] += quantity;
  }

  function useVouchers( uint quantity ) external {
    require( isVoucherUseActive,    "Voucher mint is not active" );
    require( quantity <= MAX_ORDER, "Order too big" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,    "Order exceeds supply" );
    require( quantity <= vouchers[ msg.sender ], "Order exceeds vouchers" );

    voucherCount -= quantity;
    vouchers[ msg.sender ] -= quantity;
    for(uint i = 0; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    uint256 supply = totalSupply();
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function mintVouchersTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    uint256 supply = totalSupply();
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_VOUCHERS, "Vouchers exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      voucherCount += quantity[i];
      vouchers[ recipient[i] ] += quantity[i];
    }
  }

  function setActive(bool isActive_, bool isPineapplesActive_, bool isVoucherMintActive_, bool isVoucherUseActive_) external onlyDelegates{
    require( isMintActive != isActive_ ||
      isPineapplesActive != isPineapplesActive_ ||
      isVoucherMintActive != isVoucherMintActive_ ||
      isVoucherUseActive != isVoucherUseActive_, "New value matches old" );
    isMintActive = isActive_;
    isPineapplesActive = isPineapplesActive_;
    isVoucherMintActive = isVoucherMintActive_;
    isVoucherUseActive = isVoucherUseActive_;
  }

  function setBaseURI(string calldata prefix, string calldata suffix) external onlyDelegates{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }

  function setContracts(address pineapplesAddress_, address ahmcAddress_, address artwAddress_ ) external onlyDelegates {
    pineapplesAddress = pineapplesAddress_;
    ahmcAddress = ahmcAddress_;
    artwAddress = artwAddress_;
  }

  function setMaxSupply(uint maxOrder, uint maxSupply, uint maxVouchers) external onlyDelegates{
    require( MAX_ORDER != maxOrder || MAX_SUPPLY != maxSupply || MAX_VOUCHERS != maxVouchers, "New value matches old" );
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
    MAX_VOUCHERS = maxVouchers;
  }

  function setPrice(uint ethPrice, uint pplPrice ) external onlyDelegates{
    require( ETH_PRICE != ethPrice || PPL_PRICE != pplPrice, "New value matches old" );
    ETH_PRICE = ethPrice;
    PPL_PRICE = pplPrice;
  }

  //private
  function _requireBalances() private view {
    uint ahmc = IERC721( ahmcAddress ).balanceOf( msg.sender );
    if( ahmc >= 2 )
      return;

    uint artw = IERC721( artwAddress ).balanceOf( msg.sender );
    if( artw >= 11 )
      return;

    if( ahmc > 0 && artw >= 5 )
      return;

    revert( "Not enough AHMC/ARTW tokens" );
  }

  function _requireOwnership( address[] calldata tokenContracts, uint[] calldata tokenIds ) private view {
    for( uint i; i < tokenContracts.length; ++i ){
      require( msg.sender == IERC721( tokenContracts[i] ).ownerOf( tokenIds[i] ), "Invalid owner of token" );
    }
  }
}
