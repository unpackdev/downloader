//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.11;

import "./ERC20.sol";
import "./SafeMath.sol";

interface CreamY {
  function setGovernance(address _governance) external;
  function setNormalizer(address _normalizer) external;
  function removeLiquidityExactOut(IERC20 to, uint maxInput, uint output, uint deadline) external returns (uint);
  function seize(IERC20 token, uint amount) external;
  function balanceOf(address account) external view returns (uint);
  function normalizer() external view returns (address);
  function governance() external view returns (address);
  function getAllCoins() external view returns (IERC20[] memory);
  function calcTotalValue() external view returns (uint);
  function totalSupply() external view returns (uint);
}

interface NonStandardErc20 {
  function transfer(address to, uint value) external;
}

contract Rescuer {
  using SafeMath for uint;

  address public constant creamY = 0x1D09144F3479bb805CB7c92346987420BcbDC10C;
  address public constant evilNormalizer = 0x9c3D763eC99297B2C860658a3b188e5e5120c187;
  address public constant correctNormalizer = 0xFCdeF208ecCB87008B9F2240c8bc9b3591E0295C;
  address payable public constant creamMultisig = 0x6D5a7597896A703Fe8c85775B23395a48f971305;
  IERC20 public constant compAddress = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
  IERC20 public constant creamAddress = IERC20(0x2ba592F78dB6436527729929AAf6c908497cB200);
  address public constant usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  address public admin;

  constructor() public {
    admin = msg.sender;
  }

  function setAdmin(address _admin) external {
    require(msg.sender == admin, "!admin");

    admin = _admin;
  }

  /// @notice In case something went wrong, admin could return the creamY admin back to cream
  /// multisig address.
  function returnCreamYAdmin() external {
    require(msg.sender == admin, "!admin");

    CreamY(creamY).setGovernance(creamMultisig);
  }

  /// @notice In case something went wrong, admin could seize any ERC20 token to cream multisig
  /// address.
  /// @param token The specified ERC20 token or zero for ETH.
  /// @param amount The amount.
  function seize(address token, uint amount) external {
    require(msg.sender == admin, "!admin");

    if (token == usdtAddress) {
      NonStandardErc20(token).transfer(creamMultisig, amount);
    } else {
      IERC20(token).transfer(creamMultisig, amount);
    }
  }

  /// @notice Rescue funds in creamY v1. This function could only be called by admin.
  function rescue() external {
    require(msg.sender == admin, "!admin");

    // In current state, none of the supported coin would cost more than 10 cyUSD (1M USD worth).
    uint MAX = 10e18;
    uint deadline = block.timestamp + 1 hours;

    // Calculate the ratio we want to withdraw for all tokens.
    uint totalValue = CreamY(creamY).calcTotalValue();
    uint totalSupply = CreamY(creamY).totalSupply();
    uint ratio = (totalValue.sub(totalSupply)).mul(1e18).div(totalValue);

    // Get all supported tokens.
    IERC20[] memory tokens = CreamY(creamY).getAllCoins();

    // 1. Change to evil normalizer. (1 cyUSD = 100k USD)
    CreamY(creamY).setNormalizer(evilNormalizer);

    // 2-1. Withdraw.
    for (uint i = 0; i < tokens.length; i++) {
      uint amount = (tokens[i].balanceOf(creamY)).mul(ratio).div(1e18);
      CreamY(creamY).removeLiquidityExactOut(tokens[i], MAX, amount, deadline);

      // USDT is non-standard ERC20 token.
      if (address(tokens[i]) == usdtAddress) {
        NonStandardErc20(address(tokens[i])).transfer(creamMultisig, amount);
      } else {
        tokens[i].transfer(creamMultisig, amount);
      }
    }

    // 2-2. Seize COMP and CREAM.
    uint compBalance = compAddress.balanceOf(creamY);
    CreamY(creamY).seize(compAddress, compBalance);

    uint creamBalance = creamAddress.balanceOf(creamY);
    CreamY(creamY).seize(creamAddress, creamBalance);

    // 3. Change to correct normalizer.
    CreamY(creamY).setNormalizer(correctNormalizer);
    require(CreamY(creamY).normalizer() == correctNormalizer, "incorrect normalizer");

    // 4. Renounce admin.
    CreamY(creamY).setGovernance(creamMultisig);
    require(CreamY(creamY).governance() == creamMultisig, "incorrect admin");
  }
}
