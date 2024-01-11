// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./PowerIndexNaiveRouterInterface.sol";
import "./PowerIndexRouterInterface.sol";
import "./WrappedPiErc20Interface.sol";
import "./IERC20Permit.sol";

contract WrappedPiErc20 is ERC20, ReentrancyGuard, WrappedPiErc20Interface {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Permit;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes public constant EIP712_REVISION = bytes("1");
  bytes32 internal constant EIP712_DOMAIN =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  IERC20Permit public immutable underlying;
  bytes32 public immutable override DOMAIN_SEPARATOR;
  address public router;
  bool public routerCallbackEnabled;
  uint256 public ethFee;
  mapping(address => bool) public noFeeWhitelist;
  mapping(address => uint256) public override nonces;

  event Deposit(address indexed account, uint256 undelyingDeposited, uint256 piMinted);
  event Withdraw(address indexed account, uint256 underlyingWithdrawn, uint256 piBurned);
  event Approve(address indexed to, uint256 amount);
  event ChangeRouter(address indexed newRouter);
  event EnableRouterCallback(bool indexed enabled);
  event SetEthFee(uint256 newEthFee);
  event SetNoFee(address indexed addr, bool noFee);
  event WithdrawEthFee(uint256 value);
  event CallExternal(address indexed destination, bytes4 indexed inputSig, bytes inputData, bytes outputData);

  modifier onlyRouter() {
    require(router == msg.sender, "ONLY_ROUTER");
    _;
  }

  constructor(
    address _token,
    address _router,
    string memory _name,
    string memory _symbol
  ) public ERC20(_name, _symbol) {
    underlying = IERC20Permit(_token);
    router = _router;

    uint256 chainId;

    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(EIP712_DOMAIN, keccak256(bytes(_name)), keccak256(EIP712_REVISION), chainId, address(this))
    );
  }

  /**
   * @notice Deposits underlying ERC20 token to the piToken(piERC20) with permit params
   * @param _amount The amount to deposit in underlying ERC20 tokens.
   * @param _deadline Deadline timestamp of permit
   * @param _v param of permit
   * @param _r param of permit
   * @param _s param of permit
   */
  function depositWithPermit(
    uint256 _amount,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public virtual {
    underlying.permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
    deposit(_amount);
  }

  /**
   * @notice Deposits underlying ERC20 token to the piToken(piERC20).
   * @param _depositAmount The amount to deposit in underlying ERC20 tokens.
   */
  function deposit(uint256 _depositAmount) public payable override nonReentrant returns (uint256) {
    if (noFeeWhitelist[msg.sender]) {
      require(msg.value == 0, "NO_FEE_FOR_WL");
    } else {
      require(msg.value >= ethFee, "FEE");
    }

    require(_depositAmount > 0, "ZERO_DEPOSIT");

    uint256 mintAmount = getPiEquivalentForUnderlying(_depositAmount);
    require(mintAmount > 0, "ZERO_PI_FOR_MINT");

    underlying.safeTransferFrom(msg.sender, address(this), _depositAmount);
    _mint(msg.sender, mintAmount);

    emit Deposit(msg.sender, _depositAmount, mintAmount);

    if (routerCallbackEnabled) {
      PowerIndexNaiveRouterInterface(router).piTokenCallback{ value: msg.value }(msg.sender, 0);
    }

    return mintAmount;
  }

  /**
   * @notice Withdraws underlying ERC20 token from the piToken (piERC20).
   * @param _withdrawAmount The amount to withdraw in underlying ERC20 tokens.
   * @return The amount of the burned shares.
   */
  function withdraw(uint256 _withdrawAmount) external payable override nonReentrant returns (uint256) {
    if (noFeeWhitelist[msg.sender]) {
      require(msg.value == 0, "NO_FEE_FOR_WL");
    } else {
      require(msg.value >= ethFee, "FEE");
    }

    require(_withdrawAmount > 0, "ZERO_WITHDRAWAL");

    if (routerCallbackEnabled) {
      PowerIndexNaiveRouterInterface(router).piTokenCallback{ value: msg.value }(msg.sender, _withdrawAmount);
    }

    uint256 burnAmount = getPiEquivalentForUnderlying(_withdrawAmount);
    require(burnAmount > 0, "ZERO_PI_FOR_BURN");

    _burn(msg.sender, burnAmount);
    underlying.safeTransfer(msg.sender, _withdrawAmount);

    emit Withdraw(msg.sender, _withdrawAmount, burnAmount);

    return burnAmount;
  }

  /**
   * @notice Withdraws underlying ERC20 token from the piToken(piERC20).
   * @param _burnAmount The amount of shares to burn.
   * @return The amount of the withdrawn underlying ERC20 token.
   */
  function withdrawShares(uint256 _burnAmount) external payable override nonReentrant returns (uint256) {
    if (noFeeWhitelist[msg.sender]) {
      require(msg.value == 0, "NO_FEE_FOR_WL");
    } else {
      require(msg.value >= ethFee, "FEE");
    }

    require(_burnAmount > 0, "ZERO_WITHDRAWAL");

    uint256 withdrawAmount = getUnderlyingEquivalentForPi(_burnAmount);
    require(withdrawAmount > 0, "ZERO_UNDERLYING_TO_WITHDRAW");

    if (routerCallbackEnabled) {
      PowerIndexNaiveRouterInterface(router).piTokenCallback{ value: msg.value }(msg.sender, withdrawAmount);
    }

    _burn(msg.sender, _burnAmount);
    underlying.safeTransfer(msg.sender, withdrawAmount);

    emit Withdraw(msg.sender, withdrawAmount, _burnAmount);

    return withdrawAmount;
  }

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount) public view override returns (uint256) {
    return PowerIndexRouterInterface(router).getPiEquivalentForUnderlying(_underlyingAmount, totalSupply());
  }

  function getUnderlyingEquivalentForPi(uint256 _piAmount) public view override returns (uint256) {
    return PowerIndexRouterInterface(router).getUnderlyingEquivalentForPi(_piAmount, totalSupply());
  }

  function balanceOfUnderlying(address account) external view override returns (uint256) {
    return getUnderlyingEquivalentForPi(balanceOf(account));
  }

  function totalSupplyUnderlying() external view returns (uint256) {
    return getUnderlyingEquivalentForPi(totalSupply());
  }

  function changeRouter(address _newRouter) external override onlyRouter {
    router = _newRouter;
    emit ChangeRouter(router);
  }

  function enableRouterCallback(bool _enable) external override onlyRouter {
    routerCallbackEnabled = _enable;
    emit EnableRouterCallback(_enable);
  }

  function setNoFee(address _for, bool _noFee) external override onlyRouter {
    noFeeWhitelist[_for] = _noFee;
    emit SetNoFee(_for, _noFee);
  }

  function setEthFee(uint256 _ethFee) external override onlyRouter {
    ethFee = _ethFee;
    emit SetEthFee(_ethFee);
  }

  function withdrawEthFee(address payable _receiver) external override onlyRouter {
    emit WithdrawEthFee(address(this).balance);
    _receiver.transfer(address(this).balance);
  }

  function approveUnderlying(address _to, uint256 _amount) external override onlyRouter {
    underlying.approve(_to, _amount);
    emit Approve(_to, _amount);
  }

  function callExternal(
    address _destination,
    bytes4 _signature,
    bytes calldata _args,
    uint256 _value
  ) external payable override onlyRouter returns (bytes memory) {
    return _callExternal(_destination, _signature, _args, _value);
  }

  function callExternalMultiple(ExternalCallData[] calldata _calls)
    external
    payable
    override
    onlyRouter
    returns (bytes[] memory results)
  {
    uint256 len = _calls.length;
    results = new bytes[](len);
    for (uint256 i = 0; i < len; i++) {
      results[i] = _callExternal(_calls[i].destination, _calls[i].signature, _calls[i].args, _calls[i].value);
    }
  }

  function getUnderlyingBalance() external view override returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  /**
   * @dev implements the permit function as for
   *      https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(owner != address(0), "INVALID_OWNER");
    require(block.timestamp <= deadline, "INVALID_EXPIRATION");
    uint256 currentValidNonce = nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
    nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }

  function _callExternal(
    address _destination,
    bytes4 _signature,
    bytes calldata _args,
    uint256 _value
  ) internal returns (bytes memory) {
    (bool success, bytes memory data) = _destination.call{ value: _value }(abi.encodePacked(_signature, _args));

    if (!success) {
      assembly {
        let output := mload(0x40)
        let size := returndatasize()
        switch size
        case 0 {
          // If there is no revert reason string, revert with the default `REVERTED_WITH_NO_REASON_STRING`
          mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000) // error identifier
          mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // offset
          mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // length
          mstore(add(output, 0x44), 0x52455645525445445f574954485f4e4f5f524541534f4e5f535452494e470000) // reason
          revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
        }
        default {
          // If there is a revert reason string hijacked, revert with it
          revert(add(data, 32), size)
        }
      }
    }

    emit CallExternal(_destination, _signature, _args, data);

    return data;
  }
}
