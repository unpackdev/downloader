pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./CErc20.sol";
import "./ERC20Interface.sol";
import "./Exponential.sol";

contract Fed {
    using SafeMath for uint;

    CErc20 public ctoken;
    ERC20Interface public underlying;
    address public chair; 
    address public gov;
    uint public supply;

    event Expansion(uint amount);
    event Contraction(uint amount);

    constructor(CErc20 ctoken_, address gov_) public {
        ctoken = ctoken_;
        underlying = ERC20Interface(ctoken_.underlying());
        underlying.approve(address(ctoken), uint(-1));
        chair = msg.sender;
        gov = gov_;
    }

    function changeGov(address newGov_) public {
        require(msg.sender == gov, "Fed: ONLY_GOV");
        gov = newGov_;
    }

    function changeChair(address newChair_) public {
        require(msg.sender == gov, "Fed: ONLY_GOV");
        chair = newChair_;
    }

    function resign() public {
        require(msg.sender == chair, "Fed: ONLY_CHAIR");
        chair = address(0);
    }

    function expansion(uint amount) public {
        require(msg.sender == chair, "Fed: ONLY_CHAIR");
        underlying.mint(address(this), amount);
        require(ctoken.mint(amount) == 0, 'Fed: MINT_FAILED');
        supply = supply.add(amount);
        emit Expansion(amount);
    }

    function contraction(uint amount) public {
        require(msg.sender == chair, "Fed: ONLY_CHAIR");
        require(amount <= supply, "Fed: AMOUNT_TOO_BIG"); // can't burn profits
        require(ctoken.redeemUnderlying(amount) == 0, "Fed: REDEEM_FAILED");
        underlying.burn(amount);
        supply = supply.sub(amount);
        emit Contraction(amount);
    }

    function takeProfit() public {
        uint underlyingBalance = ctoken.balanceOfUnderlying(address(this));
        uint profit = underlyingBalance.sub(supply);
        if(profit > 0) {
            require(ctoken.redeemUnderlying(profit) == 0, "Fed: REDEEM_FAILED");
            underlying.transfer(gov, profit);
        }
    }
    
}