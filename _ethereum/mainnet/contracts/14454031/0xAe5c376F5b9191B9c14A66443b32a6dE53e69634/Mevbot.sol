// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IDYDX.sol";
import "./IWETH9.sol";

contract Mevbot is ICallee {
  address private immutable executor;
  uint private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint private constant FLASH_LOAN_FEE = 2;
  
  IWETH9 private constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISoloMargin private constant soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

  modifier onlyExecutor() {
    require(msg.sender == executor);
    _;
  }

  constructor(address _myWallet, address _executor) {
    executor = _executor;
    WETH.approve(address(soloMargin), MAX_INT);
    bool success = WETH.approve(_myWallet, MAX_INT);
    require(success, "approve failed");
  }

  receive() external payable {}

  function flashLoan(uint loanAmount, address[] memory _targets, bytes[] memory _payloads, uint _percentage_to_miner) external onlyExecutor {
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = Actions.ActionArgs({
      actionType: Actions.ActionType.Withdraw,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: loanAmount // Amount to borrow
      }),
      primaryMarketId: 0, // WETH
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: ""
    });
    
    operations[1] = Actions.ActionArgs({
      actionType: Actions.ActionType.Call,
      accountId: 0,
      amount: Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: 0
      }),
      primaryMarketId: 0,
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: abi.encode(
        _targets,
        _payloads,
        loanAmount,
        _percentage_to_miner
      )
    });
    
    operations[2] = Actions.ActionArgs({
      actionType: Actions.ActionType.Deposit,
      accountId: 0,
      amount: Types.AssetAmount({
          sign: true,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: loanAmount + FLASH_LOAN_FEE // Repayment amount with 2 wei fee
      }),
      primaryMarketId: 0, // WETH
      secondaryMarketId: 0,
      otherAddress: address(this),
      otherAccountId: 0,
      data: ""
    });

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = Account.Info({owner: address(this), number: 1});

    soloMargin.operate(accountInfos, operations);
  }

  function resolver(uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) internal {
    require (_targets.length == _payloads.length, "Payload is not equal to target length");
    uint256 _wethBalanceBefore = WETH.balanceOf(address(this));

    for (uint256 i = 0; i < _targets.length; i++) {
      (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
      require(_success); _response;
    }

    uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
    require(_wethBalanceAfter > _wethBalanceBefore, "Operation would loose money");

    uint256 _ethBalance = address(this).balance;

    if (_ethBalance < _ethAmountToCoinbase) {
      WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
    }
    block.coinbase.transfer(_ethAmountToCoinbase);
  }

  // This is the function called by dydx after giving us the loan
  function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external override {
    // Decode the passed variables from the data object
    (
      // This must match the variables defined in the Call object above
      address[] memory _targets,
      bytes[] memory _payloads,
      uint loanAmount,
      uint _percentage_to_miner
    ) = abi.decode(data, (
      address [], bytes [], uint, uint
    ));

    resolver(_percentage_to_miner, _targets, _payloads);
    // It can be useful for debugging to have a verbose error message when
    // the loan can't be paid, since dydx doesn't provide one
    require(WETH.balanceOf(address(this)) > loanAmount + FLASH_LOAN_FEE, "CANNOT REPAY LOAN");
  }
}
