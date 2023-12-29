// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./WETH.sol";
import "./Index.sol";
import "./LightningBolt.sol";

import "./IUniswapV2Router.sol";
import "./ISwapRouter.sol";

//
//       .____.
//    xuu$``$$$uuu.
//  . $``$  $$$`$$$
// dP*$  $  $$$ $$$
// ?k $  $  $$$ $$$
//  $ $  $  $$$ $$$
//  ":$  $  $$$ $$$
//   N$  $  $$$ $$$
//   $$  $  $$$ $$$
//    $  $  $$$ $$$
//    $  $  $$$ $$$
//    $  $  $$$ $$$
//    $  $  $$$ $$$
//    $  $  $$$ $$$
//    $$#$  $$$ $$$
//    $$'$  $$$ $$$±
//    $$`R  $$$ $$$
//    $$$&  $$$ $$$
//    $#*$  $$$ $$$
//    $  $  $$$ @$$
//    $  $  $$$ $$$
//    $  $  $$$ $$$
//    $  $  $B$ $$&.
//    $  $  $D$ $$$$$muL.
//    $  $  $Q$ $$$$$  `"**mu..
//    $  $  $R$ $$$$$    k  `$$*t
//    $  @  $$$ $$$$$    k   $$!4
//    $ x$uu@B8u$NB@$uuuu6...$$X?
//    $ $(`RF`$`````R$ $$5`"""#"R
//    $ $" M$ $     $$ $$$      ?
//    $ $  ?$ $     T$ $$$      $
//    $ $F H$ $     M$ $$K      $  ..
//    $ $L $$ $     $$ $$R.     "d$$$$Ns.
//    $ $~ $$ $     N$ $$X      ."    "%2h
//    $ 4k f  $     *$ $$&      R       "iN
//    $ $$ %uz!     tuuR$$:     Buu      ?`:
//    $ $F          $??$8B      | '*Ned*$~L$
//    $ $k          $'@$$$      |$.suu+!' !$
//    $ ?N          $'$$@$      $*`      d:"
//    $ dL..........M.$&$$      5       d"P
//  ..$.^"*I$RR*$C""??77*?      "nu...n*L*
// '$C"R   ``""!$*@#""` .uor    bu8BUU+!`
// '*@m@.       *d"     *$Rouxxd"```$
//      R*@mu.           "#$R *$    !
//      *%x. "*L               $     %.
//         "N  `%.      ...u.d!` ..ue$$$o..
//          @    ".    $*"""" .u$$$$$$$$$$$$beu...
//         8  .mL %  :R`     x$$$$$$$$$$$$$$$$$$$$$$$$$$WmeemeeWc
//        |$e!" "s:k 4      d$N"`"#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//        $$      "N @      $?$    F$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//        $@       ^%Uu..   R#8buu$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                   ```""*u$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                          #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                           "5$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                             `*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                               ^#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                                  "*$$$$$$$$$$$$$$$$$$$$$$$$$$>
//                                    `"*$$$$$$$$$$$$$$$$$$$$$$$>
//                                        ^!$$$$$$$$$$$$$$$$$$$$>
//                                            `"#+$$$$$$$$$$$$$$>
//                                                  ""**$$$$$$$$>
//                                                         ```""
//
// CHAD                   STAYS                     THUNDERCOCKED
//
contract Thundercock is Owned {
  using SafeTransferLib for ERC20;
  struct SellOrder {
    address token;
    uint256 amount;
    Index.UniswapVersion version;
    uint24 fee;
  }

  event IndexComponentUpdated(address indexed token, uint8 weight);
  event TokenPurchased(address indexed token, uint256 amount);
  event TokenRedeemed(address indexed token, uint256 amount);
  event TokenSold(address indexed token, uint256 amount);
  event TokenReturned(address indexed token, uint256 amount);

  IUniswapV2Router public immutable uniswapV2Router;
  ISwapRouter public immutable uniswapV3Router;
  address public immutable wethAddress;

  Index public immutable index;
  address public immutable timelock;
  address public immutable chad;

  constructor(address timelockAddress) Owned(msg.sender) {
    index = Index(payable(0xdCe46b2D2193b5fab04b3129eA9498c9B601A140));
    timelock = timelockAddress;
    chad = 0xB777eb033557490abb7Fb8F3948000826423Ea07;
    uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    wethAddress = uniswapV2Router.WETH();
  }

  receive() external payable {
    WETH(payable(wethAddress)).deposit{value: msg.value}();
  }

  function _requireIsOwner() internal view {
    require(msg.sender == owner, "!owner");
  }

  function reclaimIndexOwnership() external {
    _requireIsOwner();
    index.transferOwnership(owner);
  }

  function liquidateTokens(SellOrder[] calldata orders) external {
    _requireIsOwner();
    _redeemIndex();

    uint256 saleAmount;
    uint256 tokenBalance;
    address token;
    uint24 fee;
    Index.UniswapVersion version;

    for (uint256 i; i < orders.length; ) {
      token = orders[i].token;
      saleAmount = orders[i].amount;
      fee = orders[i].fee;
      version = orders[i].version;
      tokenBalance = ERC20(token).balanceOf(address(this));
      if (saleAmount > tokenBalance) {
        saleAmount = tokenBalance;
      }
      if (version == Index.UniswapVersion.V2) {
        _sellToV2(token, saleAmount);
      } else {
        _sellToV3(token, saleAmount, fee);
      }
      unchecked {
        i++;
      }
    }

    ERC20(wethAddress).safeTransfer(address(index), ERC20(wethAddress).balanceOf(address(this)));
    _returnAssets();
  }

  function enterNewParadigm() external {
    _requireIsOwner();
    uint256 priorWethBalance = ERC20(wethAddress).balanceOf(address(this));
    index.enterNewParadigm();
    ERC20(wethAddress).safeTransfer(msg.sender, ERC20(wethAddress).balanceOf(address(this)) - priorWethBalance);
  }

  function enterNewParadigmAndBurn() external {
    _requireIsOwner();
    _redeemIndex();

    uint256 etherBalance = address(this).balance;
    if (etherBalance > 0) {
      WETH(payable(wethAddress)).deposit{value: etherBalance}();
    }
    uint256 wethBalance = ERC20(wethAddress).balanceOf(address(this));

    if (wethBalance == 0) {
      return;
    }

    uint256 managementFee = (wethBalance * 2) / 100;
    uint256 purchaseAmount = (wethBalance * 98) / 100;

    WETH(payable(wethAddress)).withdraw(managementFee);
    (bool success, ) = address(owner).call{value: managementFee}("");
    require(success);

    address token;
    uint256 ethAmount;
    uint8 weight;
    uint24 fee;
    Index.UniswapVersion version;

    for (uint8 i = 0; i < index.currentTokenCount(); ) {
      token = index.tokens(i);
      (, weight, fee, version) = index.components(token);
      ethAmount = (weight * purchaseAmount) / 100;
      if (version == Index.UniswapVersion.V2) {
        _purchaseFromV2(token, ethAmount);
      } else {
        _purchaseFromV3(token, ethAmount, fee);
      }
      unchecked {
        i++;
      }
    }

    _returnAssets();
  }

  function burnChad() external {
    _requireIsOwner();
    require(ERC20(chad).balanceOf(address(index)) > 0, "!chad");
    _redeemIndex();
    _returnAssets();
  }

  function setChad() external {
    _requireIsOwner();
    index.setChad(chad);
  }

  function _redeemIndex() internal {
    ERC20 redemptionToken = new LightningBolt();
    index.setChad(address(redemptionToken));
    index.redeem(redemptionToken.balanceOf(address(this)));
    index.setChad(chad);
    uint256 chadBalance = ERC20(chad).balanceOf(address(this));
    if (chadBalance > 0) {
      index.redeem(chadBalance);
    }
  }

  function _returnAssets() internal {
    Index.TokenAmount[] memory tokenAmounts = index.redemptionAmounts();
    for (uint i; i < tokenAmounts.length; ) {
      address token = tokenAmounts[i].token;
      uint256 balance = ERC20(token).balanceOf(address(this));
      if (balance > 0) {
        ERC20(token).safeTransfer(address(index), balance);
        emit TokenReturned(token, balance);
      }
      unchecked {
        i++;
      }
    }
  }

  function _purchaseFromV2(address token, uint256 amount) internal {
    address[] memory path = new address[](2);
    path[0] = wethAddress;
    path[1] = token;
    uint256 balanceBefore = ERC20(token).balanceOf(address(this));
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      address(this),
      block.timestamp
    );
    uint256 balanceAfter = ERC20(token).balanceOf(address(this));
    emit TokenPurchased(token, balanceAfter - balanceBefore);
  }

  function _purchaseFromV3(address token, uint256 amount, uint24 fee) internal {
    uint256 balanceBefore = ERC20(token).balanceOf(address(this));
    uniswapV3Router.exactInput(
      ISwapRouter.ExactInputParams({
        path: abi.encodePacked(wethAddress, fee, token),
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amount,
        amountOutMinimum: 0
      })
    );
    uint256 balanceAfter = ERC20(token).balanceOf(address(this));
    emit TokenPurchased(token, balanceAfter - balanceBefore);
  }

  function _sellToV2(address token, uint256 amount) internal {
    ERC20(token).approve(address(uniswapV2Router), type(uint256).max);
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = wethAddress;
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      address(this),
      block.timestamp
    );
    emit TokenSold(token, amount);
  }

  function _sellToV3(address token, uint256 amount, uint24 fee) internal {
    ERC20(token).approve(address(uniswapV3Router), type(uint256).max);
    uniswapV3Router.exactInput(
      ISwapRouter.ExactInputParams({
        path: abi.encodePacked(token, fee, wethAddress),
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amount,
        amountOutMinimum: 0
      })
    );
    emit TokenSold(token, amount);
  }

  // Emergency Function

  function executeAssembly(address _target, bytes memory _data) public payable returns (bytes memory response) {
    require(msg.sender == timelock, "!timelock");
    require(_target != address(0), "!target");

    // call contract in current context
    assembly {
      let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
      let size := returndatasize()

      response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      switch iszero(succeeded)
      case 1 {
        // throw if delegatecall failed
        revert(add(response, 0x20), size)
      }
    }
  }

  function execute(address _target, bytes calldata _data) external {
    require(msg.sender == timelock, "!timelock");
    require(_target != address(0), "!target");

    (bool success, ) = _target.call(_data);
    require(success);
  }
}
