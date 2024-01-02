// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  function functionCall(
      address target,
      bytes memory data,
      string memory errorMessage
  ) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
      address target,
      bytes memory data,
      uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    if (returndata.length > 0) {
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function nonces(address owner) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

interface ILQDX is IERC20 {
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}

contract LCBridgev2LQDX is Ownable {
  using SafeERC20 for IERC20;
  using SafeERC20 for ILQDX;

  address public poolToken;
  uint256 public chainId;
  address public treasury;

  mapping (address => bool) public noFeeWallets;
  mapping (address => bool) public managers;

  bool public enableFee = false;
  uint256 public swapFee = 5000;
  uint256 private constant coreDecimal = 1000000;

  struct SwapVoucher {
    uint256 amount;
    uint256 outChain;
    address toAccount;
    address refundAccount;
  }

  uint256 private swapIndex = 1;
  mapping (uint256 => SwapVoucher) public voucherLists;

  modifier onlyManager() {
    require(managers[msg.sender], "LCBridgev2: !manager");
    _;
  }

  event Swap(address operator, address receiver, address refund, uint256 amount, uint256 srcChainId, uint256 desChainId, uint256 swapIndex);
  event Redeem(address operator, address account, uint256 amount, uint256 srcChainId, uint256 swapIndex);
  event Refund(address operator, address account, uint256 index, uint256 amount);
  event CutFee(address treasury, uint256 treasuryFee);

  constructor(
    address _poolToken,
    uint256 _chainId,
    address _treasury
  )
  {
    require(_poolToken != address(0), "LCBridgev2: Treasury");
    require(_treasury != address(0), "LCBridgev2: Treasury");
    
    poolToken = _poolToken;
    chainId = _chainId;
    treasury = _treasury;
    managers[msg.sender] = true;
  }

  function swap(address _to, uint256 _amount, address _refund, uint256 _outChainID) public payable returns(uint256) {
    uint256 amount = IERC20(poolToken).balanceOf(address(this));
    IERC20(poolToken).safeTransferFrom(msg.sender, address(this), _amount);
    amount = IERC20(poolToken).balanceOf(address(this)) - amount;
    if (enableFee && noFeeWallets[msg.sender] == false) {
      amount = _cutFee(amount);
    }
    voucherLists[swapIndex] = SwapVoucher(amount, _outChainID, _to, _refund);
    emit Swap(msg.sender, _to, _refund, amount, chainId, _outChainID, swapIndex);
    swapIndex ++;
    return amount;
  }

  function redeem(address account, uint256 amount, uint256 srcChainId, uint256 _swapIndex, uint256 operatorFee) public onlyManager returns(uint256) {
    require(amount >= operatorFee, "LCBridgev2: Few redeem liquidity");

    amount -= operatorFee;
    if (amount > 0) {
      uint256 balance = ILQDX(poolToken).balanceOf(address(this));
      if (balance < amount) {
        ILQDX(poolToken).mint(address(this), amount - balance);
      }
      ILQDX(poolToken).safeTransfer(account, amount);
      emit Redeem(msg.sender, account, amount, srcChainId, _swapIndex);
    }

    return amount;
  }

  function refund(uint256 _index) public onlyManager returns(uint256) {
    uint256 amount = voucherLists[_index].amount;
    uint256 balance = ILQDX(poolToken).balanceOf(address(this));
    if (balance < amount) {
      ILQDX(poolToken).mint(address(this), amount - balance);
    }
    ILQDX(poolToken).mint(voucherLists[_index].refundAccount, amount);
    emit Refund(msg.sender, voucherLists[_index].refundAccount, _index, amount);
    return amount;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setNoFeeWallets(address account, bool access) public onlyManager {
    noFeeWallets[account] = access;
  }

  function setSwapFee(uint256 _swapFee) public onlyManager {
    swapFee = _swapFee;
  }

  function setEnableFee(bool _enableFee) public onlyManager {
    enableFee = _enableFee;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }

  function _cutFee(uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * swapFee / coreDecimal;
      if (fee > 0) {
        IERC20(poolToken).safeTransfer(treasury, fee);
      }
      emit CutFee(treasury, fee);
      return _amount - fee;
    }
    return 0;
  }
}