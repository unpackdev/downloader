// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ShopXReserveNFT.sol";

/**
 * @title ShopXReserveNFT Factory
 * @dev Create smart contract that will create ShopxReserveNFT contract for a given (name, symbol, brand).
 * https://eips.ethereum.org/EIPS/eip-1014
 * https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol#L32

  _uintArgs[0]: _maxSupply
  _uintArgs[1]: _mintPrice
  _uintArgs[2]: _mintLimitPerWallet
  _uintArgs[3]: _royaltyValue

  _addressArgs[0]: _royaltyRecipient
  _addressArgs[1]: _beneficiaryAddress
 */
contract ShopXReserveFactory {

  address[] public allReserveX;

  uint256 public shopxFee;
  address public shopxAddress;
  address[] public shopxAdmins;

  mapping(address => bool) public isShopxAdmin;
  mapping(address => bool) public isReserveX;

  event FactoryCreated(address indexed ShopXReserveFactory);
  event ContractCreated(string name, string symbol, string brand, address indexed ReserveX, uint index);
  event ShopxAddressUpdate(address indexed _shopxAddress);

  constructor (
    uint256 _shopxFee,
    address _shopxAddress,
    address[] memory _shopxAdmins
  ) public {
    require(_shopxAddress != address(0), "ReserveX: address zero is not a valid shopxAddress");
    require(_shopxAdmins.length > 0, "ShopxAdmins: ShopxAdmins cannot be empty");
    shopxFee = _shopxFee;
    shopxAddress = _shopxAddress;

    for (uint i = 0; i < _shopxAdmins.length; i++) {
      require(_shopxAdmins[i] != address(0), "ReserveX: address zero is not a valid shopxAdmin");
      shopxAdmins.push(_shopxAdmins[i]);
      isShopxAdmin[_shopxAdmins[i]] = true;
    }

    emit FactoryCreated(address(this));
  }

  function createReserveNFT(
    string memory _name,
    string memory _symbol,
    string memory _brand,
    string memory _baseURI,
    uint256[4] memory _uintArgs,
    address[2] memory _addressArgs,
    address[] memory _brandAdmins,
    address[] memory _saleAdmins
  ) external returns (address){
    require(isReserveX[computeAddress(_name,_symbol,_brand)] == false, 'ReserveX: Already Exists');

    bytes memory bytecode = abi.encodePacked(type(ShopXReserveNFT).creationCode, abi.encode(
        _name,
        _symbol,
        _brand
    ));

    require(bytecode.length != 0, "Create2: bytecode length is zero");

    address payable reserveX;
    uint256 codeSize;

    assembly {
      reserveX := create2(0, add(bytecode, 0x20), mload(bytecode), 0)
      codeSize := extcodesize(reserveX)
    }
    require(codeSize > 0, "Create2: Contract creation failed (codeSize is 0)");
    require(reserveX != address(0), "Create2: Failed on deploy (address is 0 )");
    IShopXReserveNFT(reserveX).initialize(
      _baseURI,
      _uintArgs,
      _addressArgs,
      _brandAdmins,
      _saleAdmins,
      shopxFee,
      shopxAddress,
      shopxAdmins
    );
    allReserveX.push(reserveX);
    isReserveX[reserveX] = true;
    emit ContractCreated(_name, _symbol, _brand, address(reserveX), allReserveX.length);

    return reserveX;
    }

  /**
  * @dev Returns the address where a contract will be stored if deployed via {createReserveNFT}. Any change in the
  * `bytecodeHash` or `salt` will result in a new destination address.
  */
  function computeAddress(string memory _name, string memory _symbol, string memory _brand) public view returns (address) {
    bytes memory bytecode = abi.encodePacked(type(ShopXReserveNFT).creationCode, abi.encode(
        _name,
        _symbol,
        _brand
    ));
    bytes32 bytecodeHash = keccak256(abi.encodePacked(bytecode));
    bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), bytes32(0), bytecodeHash));
    return address(uint160(uint256(_data)));
  }

  /**
 * @dev Throws if called by any account other than a shopxAdmin
     */
  modifier onlyShopxAdmin() {
    require(isShopxAdmin[msg.sender], "ShopxAdmins: Caller is not a shopxAdmin");
    _;
  }

  function setShopxFee (uint256 _shopxFee) onlyShopxAdmin external {
    shopxFee = _shopxFee;
  }

  function setShopxAddress (address _shopxAddress) onlyShopxAdmin external{
    require(_shopxAddress != address(0), "ReserveX: address zero is not a valid shopxAddress");
    shopxAddress = _shopxAddress;
    emit ShopxAddressUpdate(_shopxAddress);
  }

  function addShopxAdmin (address _shopxAdmin) onlyShopxAdmin external{
    require(_shopxAdmin != address(0), "ReserveX: address zero is not a valid shopxAdmin");
    require( !isShopxAdmin[_shopxAdmin], "ShopxAdmins: Address is already a shopxAdmin");
    shopxAdmins.push(_shopxAdmin);
    isShopxAdmin[_shopxAdmin]=true;
  }

  function removeShopxAdmin(address _shopxAdmin) onlyShopxAdmin external {
    require( shopxAdmins.length > 1, "ShopxAdmins: ShopxAdmins cannot be empty");
    require( isShopxAdmin[_shopxAdmin], "ShopxAdmins: Address is not a shopxAdmin");

    for (uint i=0; i<shopxAdmins.length; i++) {
      if (shopxAdmins[i] == _shopxAdmin) {
        shopxAdmins[i] = shopxAdmins[shopxAdmins.length - 1];
        shopxAdmins.pop();
        isShopxAdmin[_shopxAdmin]=false;
        break;
      }
    }
  }

}

