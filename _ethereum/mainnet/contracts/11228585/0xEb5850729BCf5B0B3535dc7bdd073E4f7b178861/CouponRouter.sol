// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IESDS {
  function epoch() external view returns (uint256);
  function couponsExpiration(uint256 epoch) external view returns (uint256);
  function transferCoupons(address sender, address recipient, uint256 epoch, uint256 amount) external;
  function balanceOfCoupons(address account, uint256 epoch) external view returns (uint256);
  function approveCoupons(address spender, uint256 amount) external;
}

interface IUniswapV2Router {

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface ICPOOL {
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  function wrap(uint _epoch, uint _couponAmount) external;
  function unwrap(uint _epoch, uint _tokenAmount) external;
}

contract CouponRouter {

  using SafeMath for uint;

  IESDS  public esds  = IESDS(0x443D2f2755DB5942601fa062Cc248aAA153313D3);
  ICPOOL public cpool = ICPOOL(0x989A1B51681110fe01548C83B37258Fc9E5dFd0e);
  IERC20 public esd   = IERC20(0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723);
  IUniswapV2Router public uniswap = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  address public esdCpoolPair = 0x5C7316f167D836efCd06981923249B56C94D255c;
  address public owner;

  uint private lpFee          = 50; // fee going back to Uniswap LPs in addition to the Uniswap fee
  uint private protocolFeeBps = 50; // fee to support the site development

  constructor() public {
      owner = msg.sender;
  }

  function swapCouponToCoupon(
    uint _fromEpoch,
    uint _toEpoch,
    uint _inputAmount,
    uint _minOutputAmount
  ) public {

    require(_fromEpoch != _toEpoch && _fromEpoch > 0 && _toEpoch > 0, "CouponRouter: invalid epochs");
    uint cPoolAmont = _wrapToCpool(_fromEpoch, _inputAmount);

    cpool.unwrap(_toEpoch, cPoolAmont);
    uint couponAmount = esds.balanceOfCoupons(address(this), _toEpoch);
    require(couponAmount > _minOutputAmount, "CouponRouter: couponAmount > _minOutputAmount");

    esds.transferCoupons(address(this), msg.sender, _toEpoch, couponAmount);
  }

  function swapCouponToESD(
    uint _fromEpoch,
    uint _inputAmount,
    uint _minOutputAmount
  ) public {

    uint cPoolAmont = _wrapToCpool(_fromEpoch, _inputAmount);
    uint esdAmount = _swapTokens(address(cpool), address(esd), cPoolAmont, _minOutputAmount);
    esd.transfer(msg.sender, esdAmount);
  }

  function swapESDToCoupon(
    uint _toEpoch,
    uint _inputAmount,
    uint _minOutputAmount
  ) public {

    esd.transferFrom(msg.sender, address(this), _inputAmount);

    uint lpFee = _inputAmount.mul(lpFee).div(10000);
    esd.transfer(address(esdCpoolPair), lpFee);

    uint protocolFee = _inputAmount.mul(protocolFeeBps).div(10000);
    esd.transfer(address(owner), protocolFee);

    uint swapAmount = _inputAmount.sub(lpFee).sub(protocolFee);
    uint cPoolAmount = _swapTokens(address(esd), address(cpool), swapAmount, 0);

    cpool.unwrap(_toEpoch, cPoolAmount);
    uint couponAmount = esds.balanceOfCoupons(address(this), _toEpoch);
    require(couponAmount > _minOutputAmount, "CouponRouter: couponAmount > _minOutputAmount");

    esds.transferCoupons(address(this), msg.sender, _toEpoch, couponAmount);
  }

  function _wrapToCpool(uint _fromEpoch, uint _couponAmount) internal returns(uint) {
    esds.transferCoupons(msg.sender, address(this), _fromEpoch, _couponAmount);

    esds.approveCoupons(address(cpool), uint(-1));
    cpool.wrap(_fromEpoch, _couponAmount);
    uint cpoolBalance = cpool.balanceOf(address(this));

    uint lpFee = cpoolBalance.mul(lpFee).div(10000);
    cpool.transfer(address(esdCpoolPair), lpFee);

    uint protocolFee = cpoolBalance.mul(protocolFeeBps).div(10000);
    cpool.transfer(address(owner), protocolFee);

    return cpoolBalance.sub(lpFee).sub(protocolFee);
  }

  function _swapTokens(
    address _fromToken,
    address _toToken,
    uint _inputAmount,
    uint _minOutputAmount
  ) internal returns(uint) {

    address[] memory path = new address[](2);
    path[0] = address(_fromToken);
    path[1] = address(_toToken);

    IERC20(_fromToken).approve(address(uniswap), uint(-1));

    uint[] memory returnAmounts = uniswap.swapExactTokensForTokens(
      _inputAmount,
      _minOutputAmount,
      path,
      address(this),
      block.timestamp.add(1000)
    );

    return returnAmounts[1];
  }
}