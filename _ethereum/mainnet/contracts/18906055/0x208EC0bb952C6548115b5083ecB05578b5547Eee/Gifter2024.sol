// SPDX-License-Identifier: MIT

/* 
Website: https://2024.gift

Telegram: https://t.me/Gifter2024

X: https://x.com/2024gifter 
*/

pragma solidity ^0.8.20;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Gifter2024 is IERC20, Ownable {

    string public name = "2024 Gifter";
    string public symbol = "2024";
    uint256 supply = 2024;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public blessedGifters;
    mapping(address => mapping(address => uint256)) private allowances;
    IUniswapV2Router02 public uniswap_router;
    address public uniswap_factory;
    address private devAddress;
    address pair;
    address[200] private giftsQualifiedAddresses;
    address public giftFactory;
    address public giftAddressToList;
    uint256 public decimals = 18;
    uint256 public maxWallet;
    uint256 private _totalSupply;
    uint256 public turn;
    uint256 public gifts_pct;
    uint256 public devPct;
    uint256 public giftRecieverCount;
    uint256 public minimumForGift;
    uint256 public onepct;
    uint256 initNum;
    uint256 public owner_limit;
    uint256 public giftLimit;
    uint256 public giftThreshold;
    uint256 public swapTokensAtAmount;
    bool public firstRound;
    bool private swapping;
    bool private tradingActive;
    bool private limitsEnabled;

    constructor(
    ) Ownable(msg.sender) {
        uint256 init_supply = supply * 10**decimals;
        giftFactory = msg.sender;
        devAddress = msg.sender;
        balanceOf[msg.sender] = init_supply;
        _totalSupply = init_supply;
        turn = 0;
        limitsEnabled = true;
        uint256 deciCalc = 10**decimals;
        gifts_pct = (200 * deciCalc) / 10000;
        devPct = (300 * deciCalc) / 10000;
        owner_limit = (150 * deciCalc) / 10000;
        giftLimit = (500 * deciCalc) / 10000;
        giftThreshold = (25 * deciCalc) / 10000;
        onepct = (100 * deciCalc)/ 10000;
        swapTokensAtAmount = 4 * 10** decimals;
        maxWallet = (_totalSupply * 2) / 100;

        giftRecieverCount = 1;
        minimumForGift = 0;
        firstRound = true;
        giftsQualifiedAddresses[0] = giftFactory;
        giftAddressToList = giftFactory;
        uniswap_router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswap_factory = uniswap_router.factory();

        address _pair = IUniswapV2Factory(uniswap_factory).createPair(
            address(this),
            uniswap_router.WETH()
        );

        pair = _pair;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[giftFactory] = true;
        emit Transfer(address(0), msg.sender, init_supply);
    }

    function updateFees(uint256 _devPct, uint256 _giftFees) external onlyOwner {
        devPct = (_devPct * 10**decimals) / 10000;
        gifts_pct = (_giftFees * 10**decimals) / 10000;
    }

    function _pctCalc_minusScale(uint256 _value, uint256 _pct) internal view returns (uint256) {
        return (_value * _pct) / 10**decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    function allowance(address _owner, address _spender) external view virtual returns (uint256) {
        return allowances[_owner][_spender];
    }

    function showGiftThreshold() external view returns (uint256) {
        return giftThreshold;
    }

    function showQualifiedAddresses() external view returns (address[200] memory) {
        return giftsQualifiedAddresses;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;
    }

    function _gifts() internal returns (bool) {
        uint256 onepct_supply = _pctCalc_minusScale(balanceOf[giftFactory], onepct);
        uint256 split = 0;
        if (balanceOf[giftFactory] <= onepct_supply) {
            split = balanceOf[giftFactory] / 250;
        } else if (balanceOf[giftFactory] > onepct_supply * 2) {
            split = balanceOf[giftFactory] / 180;
        } else {
            split = balanceOf[giftFactory] / 220;
        }

        if (balanceOf[giftFactory] - split > 0) {
            balanceOf[giftFactory] -= split;
            balanceOf[giftsQualifiedAddresses[giftRecieverCount]] += split;
            emit Transfer(giftFactory, giftsQualifiedAddresses[giftRecieverCount], split);
        }

        return true;
    }

    function _mint(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "Invalid address");
        _totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function isContract(address account) internal view returns (bool) { 
        uint size; 
        assembly { 
            size := extcodesize(account) 
        } 
    return size > 0; 
    }

    function setgiftFactory(address _giftFactory) external onlyOwner returns (bool) {
        require(msg.sender != address(0), "Invalid address");
        require(_giftFactory != address(0), "Invalid address");
        require(msg.sender == giftFactory, "Not authorized");

        giftFactory = _giftFactory;
        return true;
    }

    function tradingBegin() external onlyOwner {
        tradingActive = true;
        initGifts();
    }

    function setUniswapRouter(IUniswapV2Router02 _uniswapRouter) external onlyOwner returns (bool) {
        require(msg.sender != address(0), "Invalid address");
        require(address(_uniswapRouter) != address(0), "Invalid address");

        uniswap_router = _uniswapRouter;
        return true;
    }

    function setUniswapFactory(address _uniswapFactory) external onlyOwner returns (bool) {
        require(msg.sender != address(0), "Invalid address");
        require(_uniswapFactory != address(0), "Invalid address");

        uniswap_factory = _uniswapFactory;
        return true;
    }
    
    function traceGifts(address _from, address _to) private {
        if(block.number >= initNum) {
            require(!blessedGifters[_from] && !blessedGifters[_to]);
        }
        if(_from == pair) {
            if(block.number <= initNum) {
                blessedGifters[_to] = true;
            }
        }
    }

    function giftProcess(uint256 _amount, address _txorigin, address _sender, address _receiver) internal returns (bool) {
        minimumForGift = _pctCalc_minusScale(balanceOf[giftFactory], giftThreshold);
        if (_amount >= minimumForGift && _txorigin != address(0)) {
                if (!isContract(_txorigin)) 
                {
                    giftAddressToList = _txorigin;
                } 
                else 
                {
                    if (isContract(_sender)) {
                        giftAddressToList = _receiver;
                    } else {
                        giftAddressToList = _sender;
                    }
                }

                if (firstRound) {
                    if (giftRecieverCount < 199) {
                        giftsQualifiedAddresses[giftRecieverCount] = giftAddressToList;
                        giftRecieverCount += 1;
                    } else if (giftRecieverCount == 199) {
                        firstRound = false;
                        giftsQualifiedAddresses[giftRecieverCount] = giftAddressToList;
                        giftRecieverCount = 0;
                        _gifts();
                        giftRecieverCount += 1;
                    }
                } else {
                    if (giftRecieverCount < 199) {
                        _gifts();
                        giftsQualifiedAddresses[giftRecieverCount] = giftAddressToList;
                        giftRecieverCount += 1;
                    } else if (giftRecieverCount == 199) {
                        _gifts();
                        giftsQualifiedAddresses[giftRecieverCount] = giftAddressToList;
                        giftRecieverCount = 0;
                    }
                }
            
        }
        return true;
    }

    function removeLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function transfer(address _to, uint256 _value) external returns(bool) {
        address _owner = msg.sender;
        _transfer(_owner, _to, _value);
        return true;
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount * 10 ** decimals;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_value != 0, "No zero value transfer allowed");

        if(limitsEnabled) {
            if(!_isExcludedFromFees[_from] && !_isExcludedFromFees[_to] && !swapping) {
                require(tradingActive, "trading not active");
                if(_to != pair) {
                    require(_value + balanceOf[_to] <= maxWallet,"max 2% allowed");
                }
            }
        }
        
        if(!_isExcludedFromFees[_from] && !_isExcludedFromFees[_to] && !swapping) {
            traceGifts(_from, _to);
        }

        uint256 contractTokenBalance = balanceOf[address(this)];
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && _to == pair && _from != address(this) && _to != address(this) && msg.sender != pair) {
            swapping = true;
            swapTokensForEth(swapTokensAtAmount);
            swapping = false;
        }
        
        bool takeFee = !swapping;

        if (_isExcludedFromFees[_from] || _isExcludedFromFees[_to]) {
            takeFee = false;
        }

        if (_to != pair && _from != pair) {
            takeFee = false;
        }
        uint256 amount = _value;
        if(takeFee) {
            uint256 giftAmt = _pctCalc_minusScale(_value, gifts_pct);
            uint256 treasury_amt = _pctCalc_minusScale(_value, devPct);
            amount -= giftAmt + treasury_amt;

            balanceOf[_from] -= treasury_amt;
            balanceOf[address(this)] += treasury_amt;
            emit Transfer(_from, address(this), treasury_amt);

            balanceOf[_from] -= giftAmt;
            balanceOf[giftFactory] += giftAmt;
            emit Transfer(_from, giftFactory, giftAmt);
        }
            balanceOf[_from] -= amount;
            balanceOf[_to] += amount;
            emit Transfer(_from, _to, amount);
            giftProcess(_value, tx.origin, _from, _to);

        return true;
    }

    function swapTokensForEth(uint256 _amount) public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswap_router.WETH();
        _approve(address(this), address(uniswap_router), _amount);
        uniswap_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            devAddress,
            block.timestamp
        );
    }

    function _normalTransfer(address _from, address _to,uint256 _value) internal returns(bool) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function initGifts() private {
        initNum = block.number+2;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        address _owner = msg.sender;
        return _approve(_owner, _spender, _value);
    }

    function _approve(address _owner, address _spender, uint256 _value) private returns(bool) {
        allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }
    receive() external payable {}
}