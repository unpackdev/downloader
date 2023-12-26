// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.3;

//  _  ___      _       ___   __  __ 
//  | |/ (_) ___| | __  / _ \ / _|/ _|
//  | ' /| |/ __| |/ / | | | | |_| |_ 
//  | . \| | (__|   <  | |_| |  _|  _|
//  |_|\_\_|\___|_|\_\  \___/|_| |_|  
//

// 2023

// www.0xKickOff.com
                                 
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ItokenRecipient { 
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external returns (bool); 
}

interface Token {
    
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract KickOff is Token {
    
    using SafeMath for uint256;
    
    string public name = "Kick Off Token";
    uint8 public decimals = 18;
    string public symbol = "0XKO";
    uint256 public _totalSupply;
    address public owner;
    address payable public wallet;
    uint public ratio = 0x2710;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    mapping(address => bool) private _isExcludedFromTransfer;
    address[] private _excludedTransfer;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event ChangeWallet(address indexed oldWallet, address indexed newWallet);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed from, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    

    constructor()  {
        owner = msg.sender;
        wallet = payable(owner);
        emit OwnerSet(address(0), owner);
        _totalSupply = 10000000 * (10**18);
        balances[owner] = _totalSupply;
        emit Transfer(address(0x0), owner, balances[owner]);
    }
    
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough balance");
		require(_value >= 0, "Invalid amount"); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function mint(uint256 _value) public onlyOwner returns (bool) {
        _totalSupply = _totalSupply.add(_value);
        balances[owner] = balances[owner].add(_value);
        emit Mint(msg.sender, _value);
        return true;
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function changeWallet(address newWallet) external onlyOwner {
        emit ChangeWallet(wallet, newWallet);
        wallet = payable(newWallet);
    }
    
    function getWallet() external view returns (address) {
        return wallet;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function excludeFromTransfer(address account) public onlyOwner {
        require(!_isExcludedFromTransfer[account],"Account is already excluded");
        _isExcludedFromTransfer[account] = true;
        _excludedTransfer.push(account);
    }

    function includeFromTransfer(address account) external onlyOwner {
        require(_isExcludedFromTransfer[account],"Account is already excluded");
        _isExcludedFromTransfer[account] = false;
        _excludedTransfer.pop();
    }    

    function isExcludedFromTransfer(address account) public view returns (bool)
    {
        return _isExcludedFromTransfer[account];
    }
    
    function transfer(address _to, uint256 _value) override virtual public returns (bool success) {
        require(_isExcludedFromTransfer[msg.sender] != true, "Transfer blocked from this address");
        require(_to != address(0x0), "Use burn function instead");                              
		require(_value >= 0, "Invalid amount"); 
		require(balances[msg.sender] >= _value, "Not enough balance");
		balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 tFee = calculateTaxFee(_value);
		balances[wallet] = balances[wallet].add(tFee);
		balances[_to] = balances[_to].add(_value-tFee);
		emit Transfer(msg.sender, wallet, tFee);
		emit Transfer(msg.sender, _to, _value-tFee);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        require(_isExcludedFromTransfer[_from] != true, "Transfer blocked from this address");
        require(_to != address(0x0), "Use burn function instead");                               
		require(_value >= 0, "Invalid amount"); 
		require(balances[_from] >= _value, "Not enough balance");
		require(allowed[_from][msg.sender] >= _value, "You need to increase allowance");
		balances[_from] = balances[_from].sub(_value);
        uint256 tFee = calculateTaxFee(_value);
        balances[wallet] = balances[wallet].add(tFee);
		balances[_to] = balances[_to].add(_value-tFee);
		emit Transfer(_from, _to, _value);
        emit Transfer(_from, wallet, tFee);
		emit Transfer(_from, _to, _value-tFee);
        return true;
    }
        
    function withdraw(address _address,uint256 _value) public onlyOwner returns (bool) {
        require(address(this).balance >= _value);
        payable(_address).transfer(_value);
        return true;
    }

    function withdrawToken(address tokenAddress,address _address,uint256 _value) public onlyOwner returns (bool success) {
        return Token(tokenAddress).transfer(_address, _value);
    }
    
    function totalSupply() override public view returns (uint256 supply) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function getRatio() public view returns (uint) {
        return ratio;
    } 
    
    function changerRatio(uint _ratio) public onlyOwner {
        ratio = _ratio;
    }
    
    fallback () external payable {}
    
    receive() external payable {
        if(ratio > 0) {
            uint _value = msg.value * ratio;
            balances[msg.sender] = balances[msg.sender].add(_value);
            _totalSupply = _totalSupply.add(_value);
            Transfer(address(0),  msg.sender, _value);
        }
        wallet.transfer(msg.value);
    }
}