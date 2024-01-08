// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./UniswapV2Library.sol";
import "./TransferHelper.sol";
import "./IProxyManagerAccessControl.sol";
import "./IDelegateCallProxyManager.sol";
import "./IERC20.sol";
import "./IRootChainManager.sol";

contract IndexPoolRecovery {
  uint256 internal constant sideChainDepositAmount = type(uint128).max;
  address internal constant treasury = 0x78a3eF33cF033381FEB43ba4212f2Af5A5A0a2EA;
  IProxyManagerAccessControl internal constant proxyManagerController =
    IProxyManagerAccessControl(0x3D4860d4b7952A3CAD3Accfada61463F15fc0D54);
  IDelegateCallProxyManager internal constant proxyManager =
    IDelegateCallProxyManager(0xD23DeDC599bD56767e42D48484d6Ca96ab01C115);
  IRootChainManager internal constant polygonRootChainManager =
    IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
  address internal constant polygonERC20Predicate = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
  address internal immutable polygonRecipient;

  address internal constant DEFI5 = 0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41;
  address internal constant CC10 = 0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3;
  address internal constant CC10_SELLER = 0xE487F6E45D292BF8D9B883d007d93714f4bFE148;
  address internal constant FFF = 0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413;
  address internal constant DEGEN = 0x126c121f99e1E211dF2e5f8De2d96Fa36647c855;

  address internal immutable recoveryContract;
  bytes32 internal constant slot = bytes32(uint256(keccak256('indexed.recovery.module')) - 1);
  address internal immutable corePoolImplementation;
  bytes32 internal constant corePoolImplementationID = keccak256('IndexPool.sol');
  address internal immutable coreSellerImplementation;
  bytes32 internal constant coreSellerImplementationID = keccak256('UnboundTokenSeller.sol');
  address internal immutable sigmaPoolImplementation;
  bytes32 internal constant sigmaPoolImplementationID = keccak256('SigmaIndexPoolV1.sol');
  address internal immutable coreControllerImplementation;
  address internal constant coreControllerAddress = 0xF00A38376C8668fC1f3Cd3dAeef42E0E44A7Fcdb;
  address internal immutable sigmaControllerImplementation;
  address internal constant sigmaControllerAddress = 0x5B470A8C134D397466A1a603678DadDa678CBC29;

  function getImplementationAddress(bytes32 implementationID) internal view returns (address implementation) {
    address holder = proxyManager.getImplementationHolder(implementationID);
    (bool success, bytes memory data) = holder.staticcall('');
    require(success, string(data));
    implementation = abi.decode((data), (address));
    require(implementation != address(0), 'ERR_NULL_IMPLEMENTATION');
  }

  constructor(
    address _coreControllerImplementation,
    address _sigmaControllerImplementation,
    address _coreIndexPoolImplementation,
    address _sigmaPoolImplementation,
    address _polygonRecipient
  ) public {
    coreControllerImplementation = _coreControllerImplementation;
    sigmaControllerImplementation = _sigmaControllerImplementation;
    corePoolImplementation = _coreIndexPoolImplementation;
    sigmaPoolImplementation = _sigmaPoolImplementation;
    coreSellerImplementation = getImplementationAddress(coreSellerImplementationID);
    recoveryContract = address(this);
    polygonRecipient = _polygonRecipient;
  }

  /**
   * @dev Enables fake deposits to Polygon.
   * Accepts the transferFrom call only if the current contract is
   * DEFI5, CC10 or FFF, the caller is the polygon erc20 predicate,
   * the sender is the recovery contract, the receiver is the polygon
   * erc20 predicate and the amount is 2**128-1.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external view returns (bool) {
    require(
      (
        address(this) == DEFI5 ||
        address(this) == CC10 ||
        address(this) == FFF
      ) &&
      msg.sender == polygonERC20Predicate &&
      from == recoveryContract &&
      to == polygonERC20Predicate &&
      amount == sideChainDepositAmount
    );
    return true;
  }

  /**
   * @dev Enable transfers when the sender is FFF and the receiver is DEGEN.
   * This allows DEGEN to be removed from FFF even while the implementation contract
   * for Sigma pools is set to the recovery contract.
   */
  function transfer(address to, uint256 amount) external onlyFromTo(FFF, DEGEN) returns (bool) {
    _delegate(sigmaPoolImplementation);
  }

  /**
   * @dev If the sender is FFF and the receiver is DEGEN, delegate
   * to the real sigma pool implementation to read the balance;
   * otherwise, return the value stored at the balance slot for `account`.
   */
  function balanceOf(address account) external returns (uint256 bal) {
    if (msg.sender == FFF && address(this) == DEGEN) {
      _delegate(sigmaPoolImplementation);
    }
    uint256 balslot = balanceSlot(account);
    assembly {
      bal := sload(balslot)
    }
  }

  /**
   * @dev Delegate to an implementation contract.
   */
  function _delegate(address implementation) internal virtual {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
        // delegatecall returns 0 on error.
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }

  /**
   * @dev Calculates the slot for temporary balance storage.
   */
  function balanceSlot(address account) internal pure returns (uint256 _slot) {
    _slot = uint256(keccak256(abi.encodePacked(slot, keccak256(abi.encodePacked(account))))) - 1;
  }

  /**
   * @dev Temporarily set a balance value at the balance slot for an account.
   * This is used for draining Uniswap pairs.
   */
  function setContractBal(address account, uint256 bal) internal {
    uint256 balslot = balanceSlot(account);
    assembly {
      sstore(balslot, bal)
    }
  }

  function calculateUniswapPair(
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex'ff',
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
          )
        )
      )
    );
  }


  /**
   * @dev Transfer the full balance held by this contract of a token to the treasury.
   */
  function claimToken(IERC20 token) internal {
    uint256 bal = token.balanceOf(address(this));
    if (bal > 0) TransferHelper.safeTransfer(address(token), treasury, bal);
  }

  /**
   * @dev Transfer all but 1 wei of the paired token from a Uniswap pair
   * to the treasury.
   */
  function claimLiquidity(address pairedToken) internal {
    (address token0, address token1) =
      address(this) < pairedToken ? (address(this), pairedToken) : (pairedToken, address(this));
    address pair = calculateUniswapPair(token0, token1);
    uint256 pairedReserves = IERC20(pairedToken).balanceOf(pair);
    setContractBal(pair, 1);
    IUniswapV2Pair(pair).sync();
    uint256 amountIn = UniswapV2Library.getAmountIn(pairedReserves - 1, 1, pairedReserves);
    setContractBal(pair, amountIn + 1);
    if (token0 == address(this)) {
      IUniswapV2Pair(pair).swap(0, pairedReserves - 1, treasury, '');
    } else {
      IUniswapV2Pair(pair).swap(pairedReserves - 1, 0, treasury, '');
    }
    setContractBal(pair, 0);
  }

  modifier onlyFromTo(address _caller, address _contract) {
    require(msg.sender == _caller && address(this) == _contract);
    _;
  }

  /**
   * @dev Transfer the assets in DEFI5 and its Uniswap pair's WETH to the treasury.
   */
  function defi5() external onlyFromTo(recoveryContract, DEFI5) {
    claimToken(IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2)); // sushi
    claimToken(IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984)); // uni
    claimToken(IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9)); // aave
    claimToken(IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52)); // crv
    claimToken(IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888)); // comp
    claimToken(IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2)); // mkr
    claimToken(IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)); // snx
    claimLiquidity(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address _treasury = treasury;
  }

  /**
   * @dev Transfer the assets in CC10 and its Uniswap pair's WETH to the treasury.
   */
  function cc10() external onlyFromTo(recoveryContract, CC10) {
    claimToken(IERC20(0xd26114cd6EE289AccF82350c8d8487fedB8A0C07)); // omg
    claimToken(IERC20(0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828)); // uma
    claimToken(IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)); // bat
    claimToken(IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888)); // comp
    claimToken(IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2)); // sushi
    claimToken(IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52)); // crv
    claimToken(IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2)); // mkr
    claimToken(IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)); // snx
    claimToken(IERC20(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)); // yfi
    claimToken(IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984)); // uni
    claimLiquidity(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address _treasury = treasury;
  }

  /**
   * @dev Transfer the assets in FFF and its Uniswap pair's WETH to the treasury.
   */
  function fff() external onlyFromTo(recoveryContract, FFF) {
    claimToken(IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)); // weth
    claimToken(IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)); // wbtc
    claimToken(IERC20(DEGEN)); // degen
    claimLiquidity(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address _treasury = treasury;
  }

  /**
   * @dev Transfer the assets in the CC10 token seller to the treasury.
   */
  function cc10Seller() external onlyFromTo(recoveryContract, CC10_SELLER) {
    claimToken(IERC20(0xd26114cd6EE289AccF82350c8d8487fedB8A0C07));
    claimToken(IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498));
    address _treasury = treasury;
    assembly {
      selfdestruct(_treasury)
    }
  }

  /**
   * @dev Execute a deposit to Polygon.
   */
  function sendToPolygon() internal {
    bytes memory encodedAmount = abi.encode(sideChainDepositAmount);

    polygonRootChainManager.depositFor(polygonRecipient, DEFI5, encodedAmount);
    polygonRootChainManager.depositFor(polygonRecipient, CC10, encodedAmount);
    polygonRootChainManager.depositFor(polygonRecipient, FFF, encodedAmount);
  }

  function drainAndRepair() external onlyFromTo(treasury, recoveryContract) {
    proxyManagerController.setImplementationAddressManyToOne(corePoolImplementationID, address(this));
    proxyManagerController.setImplementationAddressManyToOne(coreSellerImplementationID, address(this));
    proxyManagerController.setImplementationAddressManyToOne(sigmaPoolImplementationID, address(this));
    sendToPolygon();
    IndexPoolRecovery(FFF).fff();
    IndexPoolRecovery(DEFI5).defi5();
    IndexPoolRecovery(CC10).cc10();
    IndexPoolRecovery(CC10_SELLER).cc10Seller();

    proxyManagerController.setImplementationAddressManyToOne(corePoolImplementationID, corePoolImplementation);
    proxyManagerController.setImplementationAddressManyToOne(coreSellerImplementationID, coreSellerImplementation);
    proxyManagerController.setImplementationAddressManyToOne(sigmaPoolImplementationID, sigmaPoolImplementation);
    proxyManagerController.setImplementationAddressOneToOne(coreControllerAddress, coreControllerImplementation);
    proxyManagerController.setImplementationAddressOneToOne(sigmaControllerAddress, sigmaControllerImplementation);

    proxyManagerController.transferOwnership(treasury);
  }
}
