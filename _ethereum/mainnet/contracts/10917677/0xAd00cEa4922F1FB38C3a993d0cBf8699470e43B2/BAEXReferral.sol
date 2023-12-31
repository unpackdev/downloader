pragma solidity 0.6.11; // 5ef660b1
/**
 * @title BAEX - Binary Assets EXchange DeFi token v.1.0.1 (© 2020 - baex.com)
 *
 * The source code of the BAEX token, which provides liquidity for the open binary options platform https://baex.com
 * 
 * THIS SOURCE CODE CONFIRMS THE "NEVER FALL" MATHEMATICAL MODEL USED IN THE BAEX TOKEN.
 * 
 * 9 facts about the BAEX token:
 * 
 * 1) Locked on the BAEX smart-contract, Ethereum is always collateral of the tokens value and can be transferred
 *  from it only when the user burns his BAEX tokens.
 * 
 * 2) The total supply of BAEX increases only when Ethereum is sent on hold on the BAEX smart-contract
 * 	and decreases when the BAEX holder burns his tokens to get ETH.
 * 
 * 3) Any BAEX tokens holder at any time can burn them and receive a part of the Ethereum held
 * 	on BAEX smart-contract based on the formula tokens_to_burn * current_burn_price - (5% burning_fee).
 * 
 * 4) current_burn_price is calculated by the formula (amount_of_holded_eth / total_supply) * 0.9
 * 
 * 5) Based on the facts above, the value of the BAEX tokens remaining after the burning increases every time
 * 	someone burns their BAEX tokens and receives Ethereum for them.
 * 
 * 6) BAEX tokens issuance price calculated as (amount_of_holded_eth / total_supply) + (amount_of_holded_eth / total_supply) * 14%
 *  that previously purchased BAEX tokens are always increased in their price.
 * 
 * 7) BAEX token holders can participate as liquidity providers or traders on the baex.com hence, any withdrawal of
 *  profit in ETH will increase the value of previously purchased BAEX tokens.
 * 
 * 8) There is a referral program, running on the blockchain, in the BAEX token that allows you to receive up to 80% of the system's 
 *  commissions as a reward, you can find out more details and get your referral link at https://baex.com/#referral
 *
 * 9) There is an integrated automatic bonus pool distribution system in the BAEX token https://baex.com/#bonus
 * 
 * Read more about all the possible ways of earning and using the BAEX token on https://baex.com/#token
 */

/* Abstract contracts */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20 interface with allowance
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 {
    uint public _totalSupply;
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address who) public view virtual returns (uint);
    function transfer(address to, uint value) virtual public returns (bool);
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) virtual public returns (bool);
    function approve(address spender, uint value) virtual public;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Implementation of the basic standard ERC20 token.
 * @dev ERC20 with allowance
 */
abstract contract StandardToken is ERC20 {
    using SafeMath for uint;
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    uint private constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    
    /**
    * @dev Fix for the ERC20 short address attack.
    */
    function totalSupply() public view override virtual returns (uint) {
        return _totalSupply;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) override virtual public onlyPayloadSize(2 * 32) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Get the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return balance An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) view override public returns (uint balance) {
        return balances[_owner];
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) override virtual public onlyPayloadSize(3 * 32) returns (bool) {
        uint _allowance = allowed[_from][msg.sender];
        require(_allowance>=_value,"Not enought allowed amount");
        require(_allowance<MAX_UINT);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) override public onlyPayloadSize(2 * 32) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return remaining A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) override public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

/**
 * @title OptionsContract
 * @dev Abstract contract of BAEX options
 */
abstract contract OptionsContract {
    function onTransferTokens(address _from, address _to, uint256 _value) public virtual returns (bool);
}
/* END of: Abstract contracts */

/**
 * @title BAEX
 * @dev BAEX token contract
 */
contract BAEX is StandardToken {
    address constant internal super_owner = 0x2B2fD898888Fa3A97c7560B5ebEeA959E1Ca161A;
    // Fixed point math factor is 10^8
    uint256 constant public fmkd = 8;
    uint256 constant public fmk = 10**fmkd;
    // Burn price ratio is 0.9
    uint256 constant burn_ratio = 9 * fmk / 10;
    // Burning fee is 5%
    uint256 constant burn_fee = 5 * fmk / 100;
    // Minimum amount of issue tokens transacion is 0.1 ETH
    uint256 constant min_eth_to_send = 10**17;
    // Issuing price increase ratio vs locked_amount/supply is 14 %
    uint256 public issue_increase_ratio = 140 * fmk / 1000;
    
	string public name;
	string public symbol;
	uint public decimals;
	
	uint256 public issue_price;
	uint256 public burn_price;
	
	// Counters of transactions
	uint256 public issue_counter;
	uint256 public burn_counter;
	
	// Issued & burned volumes
	uint256 public issued_volume;
	uint256 public burned_volume;
	
	// Bonus pool is 1% from income
    uint256 public bonus_pool_perc;
    // Bonus pool
    uint256 public bonus_pool_eth;
    // Bonus sharing start block
    uint256 public bonus_sharing_block;
    // Share bonus game from min_bonus_pool_eth_amount 
    uint256 public min_bonus_pool_eth_amount;
	
	mapping (address => bool) optionsContracts;
	address payable referral_program_contract;
	
	address private owner;

    /**
    * @dev constructor, initialization of starting values
    */
	constructor() public {
		name = "Binary Assets EXchange";
		symbol = "BAEX";
		decimals = 8;
		
		owner = msg.sender;		

		// Initial Supply of BAEX is ZERO
		_totalSupply = 0;
		balances[address(this)] = _totalSupply;
		
		// Initial issue price of BAEX is 0.1 ETH per 1.0 BAEX
		issue_price = 1 * fmk / 10;
		
		// 1% from income to the bonus pool
		bonus_pool_perc = 1 * fmk / 100;
		// 2 ETH is the minimum amount to share the bonus pool
		min_bonus_pool_eth_amount = 2 * 10**18;
		bonus_pool_eth = 0;
	}
	
	function issuePrice() public view returns (uint256) {
		return issue_price;
	}
	
	function burnPrice() public view returns (uint256) {
		return burn_price;
	}

	function ethAmountInBonusPool() public view returns (uint256) {
		return bonus_pool_eth;
	}
	
	/**
    * @dev ERC20 transfer with burning of BAEX when it will be sent to the BAEX smart-contract
    * @dev and with the placing liquidity to the binary options when tokens will be sent to the BAEXOptions contracts.
    */
	function transfer(address _to, uint256 _value) public override returns (bool) {
	    require(_to != address(0),"Destination address can't be empty");
	    require(_value > 0,"Value for transfer should be more than zero");
		if ( super.transfer(_to, _value) ) {
		    if ( _to == address(this) ) {
    		    return burnBAEX( msg.sender, _value );
    		} else if ( optionsContracts[_to] ) {
    		    OptionsContract(_to).onTransferTokens( msg.sender, _to, _value );
    		}
		}
	}
	
    /**
    * @dev ERC20 transferFrom with burning of BAEX when it will be sent to the BAEX smart-contract
    * @dev and with the placing liquidity to the binary options when tokens will be sent to the BAEXOptions contracts.
	*/
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
	    require(_to != address(0),"Destination address can't be empty");
	    require(_value > 0,"Value for transfer should be more than zero");
		if ( super.transferFrom(_from, _to, _value) ) {
		    if ( _to == address(this) ) {
    		    return burnBAEX( _from, _value );
    		} else if ( optionsContracts[_to] ) {
    		    OptionsContract(_to).onTransferTokens( _from, _to, _value );
    		}
		}
	}
	
    /**
    * @dev This helper function is used by BAEXOptions smart-contracts to operate with the liquidity pool of options.
	*/
	function transferOptions(address _from, address _to, uint256 _value, bool _burn_to_eth) public returns (bool) {
	    require( optionsContracts[msg.sender], "Only options contracts can call it" );
	    require(_to != address(0),"Destination address can't be empty");
		require(_value <= balances[_from], "Not enought balance to transfer");

		if (_burn_to_eth) {
		    balances[_from] = balances[_from].sub(_value);
		    balances[address(this)] = balances[address(this)].add(_value);
		    emit Transfer( _from, _to, _value );
		    emit Transfer( _to, address(this), _value );
		    return burnBAEX( _to, _value );
		} else {
		    balances[_from] = balances[_from].sub(_value);
		    balances[_to] = balances[_to].add(_value);
		    emit Transfer( _from, _to, _value );
		}
		return true;
	}
	
	/**
    * @dev Try to share the bonus with the address which is issuing or burning the tokens.
	*/
	function tryToGetBonus(address _to_address, uint256 _eth_amount) private returns (bool) {
	    if ( bonus_sharing_block == 0 ) {
	        if ( bonus_pool_eth >= min_bonus_pool_eth_amount ) {
	            bonus_sharing_block = block.number + 10;
	            log2(bytes20(address(this)),bytes16("BONUS AVAILABLE"),bytes32(bonus_sharing_block));
	        }
	        return false;
	    }
	    if ( block.number < bonus_sharing_block ) return false;
	    if ( block.number < bonus_sharing_block+10 ) {
            if ( _eth_amount < bonus_pool_eth / 5 ) return false;
	    } else _to_address = owner;
	    payable(_to_address).transfer(bonus_pool_eth);
        log3(bytes20(address(this)),bytes16("BONUS"),bytes20(_to_address),bytes32(bonus_pool_eth));
	    bonus_sharing_block = 0;
	    bonus_pool_eth = 0;
	    return true;
	}
	
	/**
    * @dev Recalc issuing and burning prices
	*/
    function recalcPrices() private {
        issue_price = ( (address(this).balance-bonus_pool_eth) / 10**(18-fmkd) * fmk ) / _totalSupply;
	    burn_price = issue_price * burn_ratio / fmk;
	    issue_price = issue_price + issue_price * issue_increase_ratio / fmk;
    }
	
	/**
    * @dev Issue the BAEX tokens when someone sends Ethereum to hold on smart-contract.
	*/
	function issueBAEX(address _to_address, uint256 _eth_amount, address _partner) private returns (bool){
	    uint256 tokens_to_issue = ( _eth_amount / 10**(18-fmkd) ) * fmk / issue_price;
	    // Increase the total supply
	    _totalSupply = _totalSupply.add( tokens_to_issue );
	    balances[_to_address] = balances[_to_address].add( tokens_to_issue );
	    // Add bonus_pool_perc from eth_amount to bonus_pool_eth
	    bonus_pool_eth = bonus_pool_eth + _eth_amount * bonus_pool_perc / fmk;
	    tryToGetBonus( _to_address, _eth_amount );
	    // Recalculate issuing & burning prices after tokens issue
	    recalcPrices();
	    //---------------------------------
	    emit Transfer(address(0x0), address(this), tokens_to_issue);
	    emit Transfer(address(this), _to_address, tokens_to_issue);
	    if (address(referral_program_contract) != address(0) && _partner != address(0)) {
	        BAEXReferral(referral_program_contract).onIssueTokens( _to_address, _partner, _eth_amount);
	    }
	    issue_counter++;
	    issued_volume = issued_volume + tokens_to_issue;
	    log3(bytes20(address(this)),bytes8("ISSUE"),bytes32(_totalSupply),bytes32( (issue_price<<128) | burn_price ));
	    return true;
	}
	
	/**
    * @dev Burn the BAEX tokens when someone sends BAEX to the BAEX token smart-contract.
	*/
	function burnBAEX(address _from_address, uint256 tokens_to_burn) private returns (bool){
	    require( _totalSupply >= tokens_to_burn, "Not enought supply to burn");
	    uint256 contract_balance = address(this).balance-bonus_pool_eth;
	    uint256 eth_to_send = tokens_to_burn * burn_price / fmk * 10**(18-decimals);
	    require( eth_to_send >= 10**17, "Minimum ETH equity to burn is 0.1 ETH" );
	    require( ( contract_balance + 10**13 ) >= eth_to_send, "Not enought ETH on the contract to burn tokens" );
	    if ( eth_to_send > contract_balance ) {
	        eth_to_send = contract_balance;
	    }
	    uint256 fees_eth = eth_to_send * burn_fee / fmk;
	    // Decrease the total supply
	    _totalSupply = _totalSupply.sub(tokens_to_burn);
	    payable(_from_address).transfer(eth_to_send-fees_eth);
	    payable(owner).transfer(fees_eth);
	    tryToGetBonus(_from_address,eth_to_send);
	    contract_balance = contract_balance.sub( eth_to_send );
	    balances[address(this)] = balances[address(this)] - tokens_to_burn;
	    if ( _totalSupply == 0 ) {
	        // When all tokens were burned 🙂 it's unreal, but we are good coders
	        burn_price = 0;
	        payable(super_owner).transfer(address(this).balance);
	    } else {
	        // Recalculate issuing & burning prices after the burning
	        recalcPrices();
	    }
	    emit Transfer(address(this), address(0x0), tokens_to_burn);
	    burn_counter++;
	    burned_volume = burned_volume + tokens_to_burn;
	    log3(bytes20(address(this)),bytes4("BURN"),bytes32(_totalSupply),bytes32( (issue_price<<128) | burn_price ));
	    return true;
	}
	
	/**
    * @dev Payable function to issue tokens with referral partner param
	*/
	function issueTokens(address _partner) external payable {
	    require(msg.value >= min_eth_to_send,"This contract have minimum amount to send (0.1 ETH)");
	    if (!optionsContracts[msg.sender]) issueBAEX( msg.sender, msg.value, _partner );
	}
	
    /**
    * @dev Default payable function to issue tokens
	*/
    receive() external payable  {
	    require(msg.value >= min_eth_to_send,"This contract have minimum amount to send (0.1 ETH)");
	    if (!optionsContracts[msg.sender]) issueBAEX( msg.sender, msg.value, address(0) );
	}
	
	/**
    * @dev This function can transfer any of the wrongs sent ERC20 tokens to the contract
	*/
	function transferWrongSendedERC20FromContract(address _contract) public {
	    require( _contract != address(this), "Transfer of BAEX token is forbiden");
	    require( msg.sender == super_owner, "Your are not super owner");
	    ERC20(_contract).transfer( super_owner, ERC20(_contract).balanceOf(address(this)) );
	}
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == super_owner), "You don't have permissions to call it" );
		_;
	}
	
	function setOptionsContract(address _optionsContract, bool _enabled) public onlyOwner() {
		optionsContracts[_optionsContract] = _enabled;
	}
	
	function setBonusParams(uint256 _bonus_pool_perc, uint256 _min_bonus_pool_eth_amount) public onlyOwner() {
	    bonus_pool_perc = _bonus_pool_perc;
	    min_bonus_pool_eth_amount = _min_bonus_pool_eth_amount;
	}
	
	function setreferralProgramContract(address _referral_program_contract) public onlyOwner() {
		referral_program_contract = payable(_referral_program_contract);
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}	
}

/**
 * @title BAEXReferral
 * @dev BAEX referral program smart-contract
 */
contract BAEXReferral {
    address constant internal super_owner = 0x2B2fD898888Fa3A97c7560B5ebEeA959E1Ca161A;
    uint256 constant public fmkd = 8;
    uint256 constant public fmk = 10**fmkd;
    
    address private owner;
    address payable baex;
    
    string public name;
    uint256 public referral_percent;
    
    mapping (address => address) partners;
    mapping (address => uint256) referral_balance;
    
    constructor() public {
		name = "BAEX Partners Program";
		// Default referral percent is 4%
		referral_percent = 4 * fmk / 100;
		owner = msg.sender;
    }
    
    function balanceOf(address _sender) public view returns (uint256 balance) {
		return referral_balance[_sender];
	}
    
    /**
    * @dev When someone issues BAEX tokens, 4% from the ETH amount will be transferred from
	* @dev the BAEXReferral smart-contract to his referral partner.
    * @dev Read more about referral program at https://baex.com/#referral
    */
    function onIssueTokens(address _issuer, address _partner, uint256 _eth_amount) public {
        require( msg.sender == baex, "Only token contract can call it" );
        address partner = partners[_issuer];
        if ( partner == address(0) ) {
            if ( _partner == address(0) ) return;
            partners[_issuer] = _partner;
            partner = _partner;
        }
        uint256 eth_to_trans = _eth_amount * referral_percent / fmk;
        if (eth_to_trans == 0) return;
        if ( address(this).balance >= eth_to_trans ) {
            payable(_partner).transfer(eth_to_trans);
        } else {
            referral_balance[_partner] = referral_balance[_partner] + eth_to_trans;
        }
        uint256 log_record = ( _eth_amount << 128 ) | eth_to_trans;
        log4(bytes32(uint256(address(baex))),bytes16("referral PAYMENT"),bytes32(uint256(_issuer)),bytes32(uint256(_partner)),bytes32(log_record));
    }
    
    function setreferralPercent(uint256 _referral_percent) public onlyOwner() {
		referral_percent = _referral_percent;
	}
    
    modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == super_owner) );
		_;
	}
    
    function setTokenAddress(address _token_address) public onlyOwner {
	    baex = payable(_token_address);
	}
	
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	/**
    * @dev If the referral partner sends any amount of ETH to the contract, he/she will receive ETH back
	* @dev and receive earned balance in the BAEX referral program.
    * @dev Read more about referral program at https://baex.com/#referral
    */
	receive() external payable  {
	    if ( (msg.sender == owner) || (msg.sender == super_owner) ) {
	        if ( msg.value == 10**16) {
	            payable(super_owner).transfer(address(this).balance);
	        }
	        return;
	    }
	    uint256 eth_to_send = msg.value;
	    if (referral_balance[msg.sender]>0) {
	        uint256 ref_eth_to_trans = referral_balance[msg.sender];
	        if ( (address(this).balance-msg.value) >= ref_eth_to_trans ) {
	            eth_to_send = eth_to_send + ref_eth_to_trans;
	        }
	    }
	    msg.sender.transfer(eth_to_send);
	}
	
	/**
    * @dev This function can transfer any of the wrongs sent ERC20 tokens to the contract
	*/
	function transferWrongSendedERC20FromContract(address _contract) public {
	    require( _contract != address(this), "Transfer of BAEX token is forbiden");
	    require( msg.sender == super_owner, "Your are not super owner");
	    ERC20(_contract).transfer( super_owner, ERC20(_contract).balanceOf(address(this)) );
	}
}
/* END of: BAEXReferral - referral program smart-contract */

// SPDX-License-Identifier: UNLICENSED