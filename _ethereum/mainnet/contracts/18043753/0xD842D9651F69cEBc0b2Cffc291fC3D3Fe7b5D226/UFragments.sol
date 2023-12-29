// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20Metadata.sol";

// @title uFragments ERC20 token
// @notice USDA uses the uFragments concept from the Ideal Money project to play interest
//      Implementation is shamelessly borrowed from Ampleforth project
//      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
//      combining tokens proportionally across all wallets.
//
//
//      uFragment balances are internally represented with a hidden denomination, 'gons'.
//      We support splitting the currency in expansion and combining the currency on contraction by
//      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
contract UFragments is Ownable, IERC20Metadata {
  // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
  // Anytime there is division, there is a risk of numerical instability from rounding errors. In
  // order to minimize this risk, we adhere to the following guidelines:
  // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
  //    The inverse rate must not be used--_totalGons is always the numerator and _totalSupply is
  //    always the denominator. (i.e. If you want to convert gons to fragments instead of
  //    multiplying by the inverse rate, you should divide by the normal rate)
  // 2) Gon balances converted into Fragments are always rounded down (truncated).
  //
  // We make the following guarantees:
  // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
  //   be decreased by precisely x Fragments, and B's external balance will be precisely
  //   increased by x Fragments.
  //
  // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
  // This is because, for any conversion function 'f()' that has non-zero rounding error,
  // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).

  event LogRebase(uint256 indexed epoch, uint256 totalSupply);
  event LogMonetaryPolicyUpdated(address monetaryPolicy);

  /// @notice Thrown when the signature is invalid
  error UFragments_InvalidSignature();

  /// @notice Thrown when the recipient is invalid
  error UFragments_InvalidRecipient();

  // Used for authentication
  address public monetaryPolicy;

  modifier onlyMonetaryPolicy() {
    require(msg.sender == monetaryPolicy);
    _;
  }

  modifier validRecipient(address _to) {
    if (_to == address(0) || _to == address(this)) revert UFragments_InvalidRecipient();
    _;
  }

  uint256 private constant DECIMALS = 18;
  uint256 private constant MAX_UINT256 = 2 ** 256 - 1;
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10 ** DECIMALS;

  // _totalGons is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
  // Use the highest value that fits in a uint256 for max granularity.
  uint256 public _totalGons; // = INITIAL_FRAGMENTS_SUPPLY * 10**48;

  // MAX_SUPPLY = maximum integer < (sqrt(4*_totalGons + 1) - 1) / 2
  uint256 public MAX_SUPPLY; // = type(uint128).max; // (2^128) - 1

  uint256 public _totalSupply;
  uint256 public _gonsPerFragment;
  mapping(address => uint256) public _gonBalances;

  string public name;
  string public symbol;
  uint8 public constant decimals = uint8(DECIMALS);

  // This is denominated in Fragments, because the gons-fragments conversion might change before
  // it's fully paid.
  mapping(address => mapping(address => uint256)) private _allowedFragments;

  // EIP-2612: permit – 712-signed approvals
  // https://eips.ethereum.org/EIPS/eip-2612
  string public constant EIP712_REVISION = '1';
  bytes32 public constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  // EIP-2612: keeps track of number of permits per address
  mapping(address => uint256) private _nonces;

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;

    //set og initial values
    _totalGons = INITIAL_FRAGMENTS_SUPPLY * 10 ** 48;
    MAX_SUPPLY = 2 ** 128 - 1;
    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonBalances[address(0x0)] = _totalGons; //send starting supply to a burner address so _totalSupply is never 0
    _gonsPerFragment = _totalGons / _totalSupply;
    emit Transfer(address(this), address(0x0), _totalSupply);
  }

  // @param _monetaryPolicy The address of the monetary policy contract to use for authentication.
  function setMonetaryPolicy(address _monetaryPolicy) external onlyOwner {
    monetaryPolicy = _monetaryPolicy;
    emit LogMonetaryPolicyUpdated(_monetaryPolicy);
  }

  // @notice returns the total supply
  // @return __totalSupply The total number of fragments.
  function totalSupply() external view override returns (uint256 __totalSupply) {
    return _totalSupply;
  }

  // @param _who The address to query.
  // @return _balance The balance of the specified address.
  function balanceOf(address _who) external view override returns (uint256 _balance) {
    return _gonBalances[_who] / _gonsPerFragment;
  }

  // @param _who The address to query.
  // @return _balance The gon balance of the specified address.
  function scaledBalanceOf(address _who) external view returns (uint256 _balance) {
    return _gonBalances[_who];
  }

  // @notice Returns the scaled total supply
  // @return __totalGons the total number of gons.
  function scaledTotalSupply() external view returns (uint256 __totalGons) {
    return _totalGons;
  }

  // @notice Returns the nonces of a given address
  // @param _who The address to query.
  // @return _addressNonces The number of successful permits by the specified address.
  function nonces(address _who) public view returns (uint256 _addressNonces) {
    return _nonces[_who];
  }

  // @notice Returns the EIP712 domain separator
  // @return _domainSeparator The computed DOMAIN_SEPARATOR to be used off-chain services
  //         which implement EIP-712.
  //         https://eips.ethereum.org/EIPS/eip-2612
  function DOMAIN_SEPARATOR() public view returns (bytes32 _domainSeparator) {
    uint256 _chainId;
    assembly {
      _chainId := chainid()
    }
    return keccak256(
      abi.encode(EIP712_DOMAIN, keccak256(bytes(name)), keccak256(bytes(EIP712_REVISION)), _chainId, address(this))
    );
  }

  // @notice Transfer tokens to a specified address.
  // @param _to The address to transfer to.
  // @param _value The amount to be transferred.
  // @return _success True on success, false otherwise.
  function transfer(address _to, uint256 _value) external override validRecipient(_to) returns (bool _success) {
    uint256 _gonValue = _value * _gonsPerFragment;

    _gonBalances[msg.sender] = _gonBalances[msg.sender] - _gonValue;
    _gonBalances[_to] = _gonBalances[_to] + _gonValue;

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // @notice Transfer all of the sender's wallet balance to a specified address.
  // @param _to The address to transfer to.
  // @return _success True on success, false otherwise.
  function transferAll(address _to) external validRecipient(_to) returns (bool _success) {
    uint256 _gonValue = _gonBalances[msg.sender];
    uint256 _value = _gonValue / _gonsPerFragment;

    delete _gonBalances[msg.sender];
    _gonBalances[_to] = _gonBalances[_to] + _gonValue;

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // @notice Function to check the amount of tokens that an owner has allowed to a spender.
  // @param _owner The address which owns the funds.
  // @param _spender The address which will spend the funds.
  // @return _remaining The number of tokens still available for the _spender.
  function allowance(address _owner, address _spender) external view override returns (uint256 _remaining) {
    return _allowedFragments[_owner][_spender];
  }

  // @notice Transfer tokens from one address to another.
  // @param _from The address you want to send tokens from.
  // @param _to The address you want to transfer to.
  // @param _value The amount of tokens to be transferred.
  // @return _success True on success, false otherwise.
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external override validRecipient(_to) returns (bool _success) {
    _allowedFragments[_from][msg.sender] = _allowedFragments[_from][msg.sender] - _value;

    uint256 _gonValue = _value * _gonsPerFragment;
    _gonBalances[_from] = _gonBalances[_from] - _gonValue;
    _gonBalances[_to] = _gonBalances[_to] + _gonValue;

    emit Transfer(_from, _to, _value);
    return true;
  }

  // @notice Transfer all balance tokens from one address to another.
  // @param _from The address you want to send tokens from.
  // @param _to The address you want to transfer to.
  // @return _success True on success, false otherwise.
  function transferAllFrom(address _from, address _to) external validRecipient(_to) returns (bool _success) {
    uint256 _gonValue = _gonBalances[_from];
    uint256 _value = _gonValue / _gonsPerFragment;

    _allowedFragments[_from][msg.sender] = _allowedFragments[_from][msg.sender] - _value;

    delete _gonBalances[_from];
    _gonBalances[_to] = _gonBalances[_to] + _gonValue;

    emit Transfer(_from, _to, _value);
    return true;
  }

  // @notice Approve the passed address to spend the specified amount of tokens on behalf of
  // msg.sender. This method is included for ERC20 compatibility.
  // increaseAllowance and decreaseAllowance should be used instead.
  // Changing an allowance with this method brings the risk that someone may transfer both
  // the old and the new allowance - if they are both greater than zero - if a transfer
  // transaction is mined before the later approve() call is mined.
  //
  // @param _spender The address which will spend the funds.
  // @param _value The amount of tokens to be spent.
  // @return _success True on success, false otherwise.
  function approve(address _spender, uint256 _value) external override returns (bool _success) {
    _allowedFragments[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // @notice Increase the amount of tokens that an owner has allowed to a spender.
  // This method should be used instead of approve() to avoid the double approval vulnerability
  // described above.
  // @param _spender The address which will spend the funds.
  // @param _addedValue The amount of tokens to increase the allowance by.
  // @return _success True on success, false otherwise.
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool _success) {
    _allowedFragments[msg.sender][_spender] = _allowedFragments[msg.sender][_spender] + _addedValue;

    emit Approval(msg.sender, _spender, _allowedFragments[msg.sender][_spender]);
    return true;
  }

  // @notice Decrease the amount of tokens that an owner has allowed to a spender.
  // @param _spender The address which will spend the funds.
  // @param _subtractedValue The amount of tokens to decrease the allowance by.
  // @return _success True on success, false otherwise.
  function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool _success) {
    uint256 _oldValue = _allowedFragments[msg.sender][_spender];
    _allowedFragments[msg.sender][_spender] = (_subtractedValue >= _oldValue) ? 0 : _oldValue - _subtractedValue;

    emit Approval(msg.sender, _spender, _allowedFragments[msg.sender][_spender]);
    return true;
  }

  // @notice Allows for approvals to be made via secp256k1 signatures.
  // @param _owner The owner of the funds
  // @param _spender The _spender
  // @param _value The amount
  // @param _deadline The deadline timestamp, type(uint256).max for max deadline
  // @param _v Signature param
  // @param _s Signature param
  // @param _r Signature param
  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public {
    require(block.timestamp <= _deadline);

    uint256 _ownerNonce = _nonces[_owner];
    bytes32 _permitDataDigest = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, _ownerNonce, _deadline));
    bytes32 _digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), _permitDataDigest));

    if (uint256(_s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert UFragments_InvalidSignature();
    }
    require(_owner == ecrecover(_digest, _v, _r, _s));
    if (_owner == address(0x0)) revert UFragments_InvalidSignature();

    _nonces[_owner] = _ownerNonce + 1;

    _allowedFragments[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }
}
