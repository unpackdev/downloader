pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";


/*
 * @title Travel 2 Cash (T2C)
 * @Developer HayTic
 * @notice Implements a basic token ERC20 Travel2cash.
 */

contract Travel2cash is ERC20, ERC20Burnable {
    using SafeMath for uint256;
    uint BURN_FEE = 1;
    uint TAX_FEE = 1;
    uint BASE_DIV = 2000;
    uint LIMIT_BURN = 40000000;
    address public owner;
    address public walletStaking;
    uint256 public taxFeePooling;
    mapping (address=>bool) public excludedFromTax;

    /* ========== CONSTRUCTOR ========== */
    constructor(address OwnerToken,address AccountStakingRewards) ERC20("Travel2cash", "T2C") {
        owner=OwnerToken;
        walletStaking=AccountStakingRewards;
        _mint(owner, 100000000 * 10 ** decimals());
    }
    /* ========== transfer T2C ========== */
    function transfer(address recipient,uint256 amount)public override returns(bool){
      uint taxFee = amount.mul(TAX_FEE).div(BASE_DIV);
      _transfer(_msgSender(),walletStaking,taxFee);

      if (taxFeePooling ==  LIMIT_BURN) {
        _transfer(_msgSender(),recipient,amount.sub(taxFee));
      } else {
        uint burnAmount = amount.mul(BURN_FEE).div(BASE_DIV);
        _burn(_msgSender(),burnAmount);
        _transfer(_msgSender(),recipient,amount.sub(burnAmount).sub(taxFee));
        setAmountTax(taxFee);
      }

    return true;
    }

    function setAmountTax(uint256 tax) public returns(bool success){
      taxFeePooling += tax;
      return true;
    }

    
    function getAmountTax() public view returns (uint256) {
        return taxFeePooling;
    }


}

