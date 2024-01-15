pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Napoleon is Ownable,Pausable{
  using SafeMath for uint;

    struct Entry {
      address main_token;
      address sub_token;
      uint decimal;

      uint token_usdt_price;
      uint eth_usdt_price;

      uint  amountRequired;
    }
    struct Coin {
      uint decimal;
      address coin_address;
      uint price;
    }

    mapping(string=>Coin) coin_map;
    mapping(address=>Entry) entry_map;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'TokenSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    
  constructor(address main_token_,address sub_token_,uint decimal_, uint token_usdt_price_,uint eth_usdt_price_, uint amountRequired_) payable{
    Entry memory entry = Entry({
      main_token : main_token_,
      sub_token : sub_token_,
      decimal : decimal_,
      token_usdt_price : token_usdt_price_,
      eth_usdt_price : eth_usdt_price_,
      amountRequired : amountRequired_
    });

    entry_map[tx.origin] = entry;

    coin_map["DAI"] = Coin({
      decimal : 18,
      coin_address : address(0x6B175474E89094C44Da98b954EedeAC495271d0F),
      price: 1
    });
  }

  function updateEntry(address main_token_,address sub_token_,uint decimal_, uint token_usdt_price_,uint eth_usdt_price_, uint amountRequired_) public onlyOwner {
    require(decimal_ > 0, "error2");
    require(token_usdt_price_ > 0, "error3");

	  entry_map[owner()].main_token = main_token_;
    entry_map[owner()].sub_token = sub_token_;
    entry_map[owner()].decimal=decimal_;

    entry_map[owner()].token_usdt_price = token_usdt_price_;
    entry_map[owner()].eth_usdt_price = eth_usdt_price_;

	  entry_map[owner()].amountRequired = amountRequired_;
  }

  function pause() onlyOwner whenNotPaused external {
    _pause();
  }
  function unpause() onlyOwner whenPaused external {
    _unpause();
  }
  
  function exChangeByETH(uint amount) lock payable whenNotPaused external {
    require(amount % entry_map[owner()].amountRequired == 0, "amount valid");
    uint money_ = SafeMath.mul(SafeMath.div(SafeMath.mul(amount,entry_map[owner()].token_usdt_price),entry_map[owner()].eth_usdt_price) ,10 ** 18);

    require(money_ <= msg.value,"eth not enough");	

    IERC20 main_token_ = IERC20(entry_map[owner()].main_token);
    IERC20 sub_token_ = IERC20(entry_map[owner()].sub_token);
	
    require(entry_map[owner()].main_token != address(0x0),"main_token is not exists");
    require(entry_map[owner()].sub_token != address(0x0),"sub_token is not exists");

    uint128 main_token_balance_ = uint128(main_token_.balanceOf(address(this)));
    uint128 sub_token_balance_ = uint128(sub_token_.balanceOf(address(this)));
	
    uint256 amount_tmp = SafeMath.mul(amount, 10 ** entry_map[owner()].decimal);
    require(amount_tmp <= main_token_balance_,"less token balance");

    payable(owner()).transfer(money_);

    main_token_.transfer(tx.origin,amount_tmp);
	
	  if (sub_token_balance_ >= amount_tmp){
       sub_token_.transfer(tx.origin,amount_tmp);   	
    }
  }

  function exChangeByERC20(uint amount,string memory coin_symbol) lock whenNotPaused external {
    require(amount % entry_map[owner()].amountRequired == 0, "amount valid");
    uint token_nd_pay = SafeMath.mul(SafeMath.div(SafeMath.mul(amount,entry_map[owner()].token_usdt_price),coin_map[coin_symbol].price) ,10 ** coin_map[coin_symbol].decimal);

    IERC20 coin = IERC20(coin_map[coin_symbol].coin_address);
    IERC20 main_token_ = IERC20(entry_map[owner()].main_token);
    IERC20 sub_token_ = IERC20(entry_map[owner()].sub_token);
	
    require(token_nd_pay <= coin.balanceOf(tx.origin),"coin not enough");

    require(entry_map[owner()].main_token != address(0x0),"main_token is not exists");
    require(entry_map[owner()].sub_token != address(0x0),"sub_token is not exists");

    uint128 main_token_balance_ = uint128(main_token_.balanceOf(address(this)));
    uint128 sub_token_balance_ = uint128(sub_token_.balanceOf(address(this)));
	
    uint256 amount_tmp = SafeMath.mul(amount, 10 ** entry_map[owner()].decimal);
    require(amount_tmp <= main_token_balance_,"less token balance");

    coin.transferFrom(tx.origin,address(this),token_nd_pay);
    main_token_.transfer(tx.origin,amount_tmp);
	
	if (sub_token_balance_ >= amount_tmp){
       sub_token_.transfer(tx.origin,amount_tmp);   	
    }
  }

  function withdraw(address main_token_, uint amount,uint decimal) external onlyOwner{
    IERC20 _main_token = IERC20(main_token_);

    uint256 amount_ = SafeMath.mul(amount,10 ** decimal);

    _main_token.transfer(tx.origin,amount_); 
    payable(tx.origin).transfer(address(this).balance);  
  }

  fallback () payable external {}
  receive () payable external {}

}
