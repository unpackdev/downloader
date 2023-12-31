// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./IWETH.sol";

// solhint-disable reason-string, not-rely-on-time

contract TokenSale is Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  event Buy(address indexed sender, address _token, uint256 _amountIn, uint256 _refundAmount, uint256 _amountOut);
  event Claim(address indexed _recipient, uint256 _claimAmount);
  event UpdatePrice(uint256 _initialPrice, uint256 _upRatio, uint256 _variation);
  event UpdateSaleTime(uint256 _whitelistSaleTime, uint256 _publicSaleTime, uint256 _publicSaleDuration);
  event UpdateSupportedToken(address indexed _token, bool _status);
  event UpdateCap(uint128 _cap, uint256 _whitelistSaleCap);

  uint256 private constant PRICE_PRECISION = 1e18;
  uint256 private constant RATIO_PRECISION = 1e9;

  address public immutable weth;
  address public immutable base;
  address public quota;
  address public signer;

  struct PriceData {
    uint96 initialPrice;
    uint32 upRatio;
    uint128 variation;
  }

  struct SaleTimeData {
    uint64 whitelistSaleTime;
    uint64 publicSaleTime;
    uint64 saleDuration;
  }

  SaleTimeData public saleTimeData;
  PriceData public priceData;

  uint128 public cap;
  uint128 public whitelistSaleCap;
  uint128 public totalSold;
  uint128 public whitelistSold;

  mapping(address => bool) public isSupported;
  mapping(address => uint256) public shares;
  mapping(address => bool) public claimed;

  constructor(
    address _weth,
    address _base,
    address _signer,
    uint128 _cap,
    uint128 _whitelistSaleCap,
    uint64 _whitelistSaleTime,
    uint64 _publicSaleTime,
    uint64 _publicSaleDuration,
    uint96 _initialPrice,
    uint32 _upRatio,
    uint128 _variation,
    address[] memory _tokens
  ) {
    weth = _weth;
    base = _base;
    updateSigner(_signer);
    updateCap(_cap, _whitelistSaleCap);
    updateSupportedTokens(_tokens, true);
    updatePrice(_initialPrice, _upRatio, _variation);
    updateSaleTime(_whitelistSaleTime, _publicSaleTime, _publicSaleDuration);
  }

  /********************************** View Functions **********************************/

  /// @notice Return current price (base/quota) of quota token.
  /// @dev                                                  / totalSold \
  ///      CurrenetPrice = InitPrice * (1 + UpRatio * floor|  ---------  |)
  ///                                                       \ Variation /
  function getPrice() public view returns (uint256) {
    PriceData memory _data = priceData;
    uint256 _totalSold = totalSold;
    uint256 _level = _totalSold / _data.variation;

    return RATIO_PRECISION.add(_level.mul(_data.upRatio)).mul(_data.initialPrice).div(RATIO_PRECISION);
  }

  /********************************** Mutated Functions **********************************/

  /// @notice Purchase some quota in contract using supported base token.
  ///
  /// @dev The contract will refund `_token` back to caller if the sale cap is not enough.
  ///
  /// @param _token The address of token used to buy quota token.
  /// @param _amountIn The amount of `_token` to use.
  /// @param _minOut The minimum recieved quota token.
  function buy(
    address _token,
    uint256 _amountIn,
    uint256 _minOut,
    bytes calldata signature
  ) external payable nonReentrant returns (uint256) {
    require(_amountIn > 0, "TokenSale: zero input amount");

    // 1. check supported token
    require(isSupported[_token], "TokenSale: token not support");

    // 2. check sale time and whitelist
    SaleTimeData memory _saleTime = saleTimeData;
    require(block.timestamp >= _saleTime.whitelistSaleTime, "TokenSale: sale not start");
    require(block.timestamp <= _saleTime.publicSaleTime + _saleTime.saleDuration, "TokenSale: sale ended");
    require(block.timestamp >= _saleTime.publicSaleTime || _isValidSignature(signature), "TokenSale: only whitelist");

    // 3. determine account sale cap
    uint256 _cap = 0;
    if (block.timestamp < _saleTime.publicSaleTime) {
      _cap = whitelistSaleCap;
    } else {
      _cap = cap;
    }
    uint256 _totalSold = totalSold;
    uint256 _whitelistSold = whitelistSold;
    uint256 _saleCap = _cap.sub(_totalSold);
    require(_saleCap > 0, "TokenSale: sold out");

    // 4. transfer token in contract
    if (_token == address(0)) {
      require(_amountIn == msg.value, "TokenSale: msg.value mismatch");
      _token = weth;
      IWETH(_token).deposit{ value: _amountIn }();
    } else {
      require(0 == msg.value, "TokenSale: nonzero msg.value");
      uint256 _before = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amountIn);
      _amountIn = IERC20(_token).balanceOf(address(this)) - _before;
    }

    // 5. buy and update storage
    uint256 _price = getPrice();
    uint256 _amountOut = _amountIn.mul(PRICE_PRECISION).div(_price);
    uint256 _refundAmount;
    if (_saleCap < _amountOut) {
      _refundAmount = (_amountOut - _saleCap).mul(_price).div(PRICE_PRECISION);
      _amountOut = _saleCap;
    }
    require(_amountOut >= _minOut, "TokenSale: insufficient output");
    shares[msg.sender] += _amountOut;

    _totalSold += _amountOut;
    require(_totalSold <= uint128(-1), "TokenSale: overflow");
    totalSold = uint128(_totalSold);
  
    if (block.timestamp < _saleTime.publicSaleTime) {
      _whitelistSold += _amountOut;
      require(_whitelistSold <= uint128(-1), "TokenSale: whitelist overflow");
      whitelistSold = uint128(_whitelistSold);
    }

    // 6. refund extra token
    if (_refundAmount > 0) {
      _refundAmount = _refund(_token, _refundAmount);
    }

    emit Buy(msg.sender, msg.value > 0 ? address(0) : _token, _amountIn, _refundAmount, _amountOut);

    return _amountOut;
  }

  /// @notice Claim purchased quota token.
  function claim() external nonReentrant {
    // 1. check timestamp and claimed.
    SaleTimeData memory _saleTime = saleTimeData;
    require(block.timestamp > _saleTime.publicSaleTime + _saleTime.saleDuration, "TokenSale: sale not end");
    require(!claimed[msg.sender], "TokenSale: already claimed");

    // 2. check claiming amount
    uint256 _claimAmount = shares[msg.sender];
    require(_claimAmount > 0, "TokenSale: no share to claim");
    claimed[msg.sender] = true;

    address _quota = quota;

    // 3. transfer
    if (_claimAmount > 0) {
      IERC20(_quota).safeTransfer(msg.sender, _claimAmount);
    }

    emit Claim(msg.sender, _claimAmount);
  }

  /********************************** Restricted Functions **********************************/

  function updateCap(uint128 _cap, uint128 _whitelistSaleCap) public onlyOwner {
    cap = _cap;
    whitelistSaleCap = _whitelistSaleCap;

    emit UpdateCap(_cap, _whitelistSaleCap);
  }

  /// @notice Update supported tokens.
  /// @param _tokens The list of addresses of token to update.
  /// @param _status The status to update.
  function updateSupportedTokens(address[] memory _tokens, bool _status) public onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      isSupported[_tokens[i]] = _status;
      emit UpdateSupportedToken(_tokens[i], _status);
    }
  }

  /// @notice Update signer
  /// @param _signer The address of signer to update.
  function updateSigner(address _signer) public onlyOwner() {
    signer = _signer;
  }

  /// @notice Update quota token
  /// @param _quota The address of quota token to update.
  function updateQuotaToken(address _quota) external onlyOwner {
    quota = _quota;
  }

  /// @notice Update sale start time, including whitelist/public sale start time and duration.
  ///
  /// @param _whitelistSaleTime The timestamp when whitelist sale started.
  /// @param _publicSaleTime The timestamp when public sale started.
  /// @param _publicSaleDuration The durarion of public sale in seconds.
  function updateSaleTime(
    uint64 _whitelistSaleTime,
    uint64 _publicSaleTime,
    uint64 _publicSaleDuration
  ) public onlyOwner {
    require(_whitelistSaleTime >= block.timestamp, "TokenSale: start time too small");
    require(_whitelistSaleTime <= _publicSaleTime, "TokenSale: whitelist after public");

    SaleTimeData memory _saleTime = saleTimeData;
    require(
      _saleTime.whitelistSaleTime == 0 || block.timestamp < _saleTime.whitelistSaleTime,
      "TokenSale: sale started"
    );

    saleTimeData = SaleTimeData(_whitelistSaleTime, _publicSaleTime, _publicSaleDuration);

    emit UpdateSaleTime(_whitelistSaleTime, _publicSaleTime, _publicSaleDuration);
  }

  /// @notice Update token sale price info.
  /// @dev See comments in function `getPrice()` for the usage of each parameters.
  ///
  /// @param _initialPrice The initial price for the sale, with precision 1e18.
  /// @param _upRatio The up ratio for the token sale, with precision 1e9.
  /// @param _variation The variation for price change base on the amount of quota token sold.
  function updatePrice(
    uint96 _initialPrice,
    uint32 _upRatio,
    uint128 _variation
  ) public onlyOwner {
    require(_upRatio <= RATIO_PRECISION, "TokenSale: ratio too large");
    require(_variation > 0, "TokenSale: zero variation");

    SaleTimeData memory _saleTime = saleTimeData;
    require(
      _saleTime.whitelistSaleTime == 0 || block.timestamp < _saleTime.whitelistSaleTime,
      "TokenSale: sale started"
    );

    priceData = PriceData(_initialPrice, _upRatio, _variation);

    emit UpdatePrice(_initialPrice, _upRatio, _variation);
  }

  function withdrawFund(address[] memory _tokens, address _recipient) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i] == address(0)) {
        uint256 _balance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _recipient.call{ value: _balance }("");
        require(success, "TokenSale: failed to withdraw ETH");
      } else {
        uint256 _balance = IERC20(_tokens[i]).balanceOf(address(this));
        IERC20(_tokens[i]).safeTransfer(_recipient, _balance);
      }
    }
  }

  /********************************** Internal Functions **********************************/

  /// @dev Refund extra token back to sender.
  /// @param _token The address of token to refund.
  /// @param _amount The amount of base token to refund.
  function _refund(address _token, uint256 _amount) internal returns (uint256) {
    if (msg.value > 0) {
      IWETH(_token).withdraw(_amount);
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = msg.sender.call{ value: _amount }("");
      require(success, "TokenSale: failed to refund ETH");
    } else {
      IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    return _amount;
  }

  function _isValidSignature(bytes memory signature) view internal returns (bool) {
    bytes32 data = keccak256(abi.encodePacked(address(this), _msgSender()));
    return signer == data.toEthSignedMessageHash().recover(signature);
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}