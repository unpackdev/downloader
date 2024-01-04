pragma solidity ^0.4.24;
    
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {
        /**
        * @dev Multiplies two numbers, throws on overflow.
        */
        function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
            if (a == 0) {
                return 0;
            }
            c = a * b;
            assert(c / a == b);
            return c;
        }
    
        /**
        * @dev Integer division of two numbers, truncating the quotient.
        */
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            // assert(b > 0); // Solidity automatically throws when dividing by 0
            // uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold
            return a / b;
        }
    
        /**
        * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
        */
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b;
        }
    
        /**
        * @dev Adds two numbers, throws on overflow.
        */
        function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
            c = a + b;
            assert(c >= a);
            return c;
        }
    }
    
    /**
     * @title ERC20Basic
     * @dev Simpler version of ERC20 interface
     * @dev see https://github.com/ethereum/EIPs/issues/179
     */
    contract ERC20Basic {
        uint256 public totalSupply;
    
        function balanceOf(address who) public view returns (uint256);
    
        function _transfer(address to, uint256 value) internal returns (bool);
    
        event Transfer(address indexed from, address indexed to, uint256 value);
    }
    
    /**
     * @title Basic token
     * @dev Basic version of StandardToken, with no allowances.
     */
    contract BasicToken is ERC20Basic {
        using SafeMath for uint256;
    
        mapping(address => uint256) balances;
    
        /**
        * @dev transfer token for a specified address
        * @param _to The address to transfer to.
        * @param _value The amount to be transferred.
        */
        function _transfer(address _to, uint256 _value) internal returns (bool) {
            require(_to != address(0));
    
            // SafeMath.sub will throw if there is not enough balance.
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
    
        /**
        * @dev Gets the balance of the specified address.
        * @param _owner The address to query the the balance of.
        * @return An uint256 representing the amount owned by the passed address.
        */
        function balanceOf(address _owner) public view returns (uint256 balance) {
            return balances[_owner];
        }
    }
    
    /**
     * @title ERC20 interface
     * @dev see https://github.com/ethereum/EIPs/issues/20
     */
    contract ERC20 is ERC20Basic {
        function allowance(address owner, address spender) public view returns (uint256);
    
        function _transferFrom(address from, address to, uint256 value) internal returns (bool);
    
        function approve(address spender, uint256 value) public returns (bool);
    
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
    /**
     * @title Standard ERC20 token
     *
     * @dev Implementation of the basic standard token.
     * @dev https://github.com/ethereum/EIPs/issues/20
     * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
     */
    contract StandardToken is ERC20, BasicToken {
        mapping(address => mapping(address => uint256)) allowed;
    
        /**
         * @dev Transfer tokens from one address to another
         * @param _from address The address which you want to send tokens from
         * @param _to address The address which you want to transfer to
         * @param _value uint256 the amount of tokens to be transferred
         */
        function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
            require(_to != address(0));
    
            uint256 _allowance = allowed[_from][msg.sender];
    
            // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
            // require (_value <= _allowance);
    
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            allowed[_from][msg.sender] = _allowance.sub(_value);
           emit Transfer(_from, _to, _value);
            return true;
        }
    
        /**
         * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         *
         * Beware that changing an allowance with this method brings the risk that someone may use both the old
         * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
         * @param _spender The address which will spend the funds.
         * @param _value The amount of tokens to be spent.
         */
        function approve(address _spender, uint256 _value) public returns (bool) {
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
    
        /**
         * @dev Function to check the amount of tokens that an owner allowed to a spender.
         * @param _owner address The address which owns the funds.
         * @param _spender address The address which will spend the funds.
         * @return A uint256 specifying the amount of tokens still available for the spender.
         */
        function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
            return allowed[_owner][_spender];
        }
    
        /**
         * approve should be called when allowed[_spender] == 0. To increment
         * allowed value is better to use this function to avoid 2 calls (and wait until
         * the first transaction is mined)
         * From MonolithDAO Token.sol
         */
        function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
           emit  Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
        }
    
        function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
            uint oldValue = allowed[msg.sender][_spender];
            if (_subtractedValue > oldValue) {
                allowed[msg.sender][_spender] = 0;
            } else {
                allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
            }
            emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
        }
    }
    /**
     * @title Ownable
     * @dev The Ownable contract has an owner address, and provides basic authorization control
     * functions, this simplifies the implementation of "user permissions".
     */
    contract Ownable {
        address internal owner;
    
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
        /**
         * @dev The Ownable constructor sets the original `owner` of the contract to the sender
         * account.
         */
        constructor() public {
            owner = msg.sender;
        }
    
        /**
         * @dev Throws if called by any account other than the owner.
         */
        modifier onlyOwner() {
            require(msg.sender == owner);
            _;
        }
    
        /**
         * @dev Allows the current owner to transfer control of the contract to a newOwner.
         * @param newOwner The address to transfer ownership to.
         */
        function transferOwnership(address newOwner) onlyOwner public returns (bool) {
            require(newOwner != address(0x0));
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
    
            return true;
        }
    }
    

    /**
     * @title Mintable token
     * @dev Simple ERC20 Token example, with mintable token creation
     * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
     * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
     */
    contract MintableToken is StandardToken, Ownable {
        event Mint(address indexed to, uint256 amount);
    
        /**
         * @dev Function to mint tokens
         * @param _to The address that will receive the minted tokens.
         * @param _amount The amount of tokens to mint.
         * @return A boolean that indicates if the operation was successful.
         */
    
        function _mint(address _to, uint256 _amount)  internal returns (bool) {
            totalSupply = SafeMath.add(totalSupply, _amount);
            balances[_to] = balances[_to].add(_amount);
            emit Mint(_to, _amount);
            emit Transfer(0x0000000000000000000000000000000000000000, _to, _amount);
            return true;
        }
    }

    contract FWTV is MintableToken {
        string public name =  "Fashion World TV";
        string public symbol = "FWTV";
        uint8 public decimals =  8;
        
        uint256 public totalSupply;
        
        uint256 public ownerLockedValue;
        
        uint256 public partner1LockedValue;
        uint256 public partner2LockedValue;
        uint256 public partner3LockedValue;

        uint256 public developmentLockedValue;
        uint256 public marketingLockedValue;

        uint256 public generalLockedValue;

        address public ownerWallet= 0xD89777431f652f1Be225Ff3c3E4FDD8d8B22d57C;
        address public partner1Wallet = 0x2944D6B7421B391032565e12622bCb18d4f214F3;
        address public partner2Wallet= 0x2a3b92acBcb81e9A3B019D9b1A74745F0aa41B73;
        address public partner3Wallet = 0xE3820e184375931318761632a2bDB480a6ac76c4;
        
        address public developmentWallet = 0xD08E3C4Df70b2480Fb1EC010Eb8d32E27B45B453;
        address public marketingWallet= 0x72099dB38D842565c1E5B0996BEC88eAB3474551;

        uint256 public ownerTimeLock;
        uint256 public partner1TimeLock;
        uint256 public generalTimeLock;
        
        uint256 public startTime;

        constructor() public {

           totalSupply =  1000000000 * (10 ** 8) ;
           
           startTime = now;
           
           ownerLockedValue =  SafeMath.div(SafeMath.mul(totalSupply,5),100);
           partner1LockedValue =  SafeMath.div(SafeMath.mul(totalSupply,10),100);
           partner2LockedValue =  SafeMath.div(SafeMath.mul(totalSupply,10),100);
           partner3LockedValue =  SafeMath.div(SafeMath.mul(totalSupply,10),100);

           developmentLockedValue =  SafeMath.div(SafeMath.mul(totalSupply,10),100);
           marketingLockedValue =  SafeMath.div(SafeMath.mul(totalSupply,10),100);

           generalLockedValue =  SafeMath.div(SafeMath.mul(totalSupply,45),100);
           
           generalTimeLock = startTime + 1 years;
           ownerTimeLock = startTime +  5 years;
           partner1TimeLock = startTime +  3 years;
           
            
            super._mint(owner, generalLockedValue);
            super._mint(ownerWallet, ownerLockedValue);
            super._mint(partner1Wallet, partner1LockedValue);
            super._mint(partner2Wallet, partner2LockedValue);
            super._mint(partner3Wallet, partner3LockedValue);
            super._mint(developmentWallet, developmentLockedValue);
            super._mint(marketingWallet, marketingLockedValue);

        }

        function transfer(address _to, uint256 _amount) public returns (bool) {
         address fromAddress = msg.sender;
         
          if (fromAddress == owner || fromAddress == marketingWallet || fromAddress == developmentWallet) {
                return super._transfer(_to, _amount);
            } else if (fromAddress == ownerWallet) {
                 require(now >= ownerTimeLock, "Owner Time Lock is not open");
                 return super._transfer(_to, _amount);
            } else if (fromAddress == partner1Wallet || fromAddress == partner2Wallet || fromAddress == partner3Wallet) {
                 require(now >= partner1TimeLock, "Partners Time Lock is not open");
                 return super._transfer(_to, _amount);
            } else {
                 require(now >= generalTimeLock, "General Time Lock is not open");
                 return super._transfer(_to, _amount);
            }
            
        }
            
    
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

          if (_from == owner || _from == marketingWallet || _from == developmentWallet) {
                return super._transferFrom(_from, _to, _value);
            } else if (_from == ownerWallet) {
                 require(now >= ownerTimeLock, "Owner Time Lock is not open");
                return super._transferFrom(_from, _to, _value);
            } else if (_from == partner1Wallet || _from == partner2Wallet || _from == partner3Wallet) {
                 require(now >= partner1TimeLock, "Partners Time Lock is not open");
                 return super._transferFrom(_from, _to, _value);
            } else {
                 require(now >= generalTimeLock, "General Time Lock is not open");
                 return super._transferFrom(_from, _to, _value);
            }
        
        }
      
    }