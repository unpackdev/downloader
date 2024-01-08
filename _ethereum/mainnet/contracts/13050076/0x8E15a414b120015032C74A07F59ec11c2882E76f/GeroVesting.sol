pragma solidity ^0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

contract GeroVesting is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IERC20 _token;
    bool public paused;
    mapping (address => uint256) public _amounts;
    mapping (address => uint256) public _balances;
    uint256 _cliff = 1629298800;
    uint256 _lasts = 1652886000;
    mapping (address => uint256) public _lastClaim;

    event Claim(address indexed account, uint256 timestamp, uint256 amount);

    constructor(address _tokenAdd) public {
        _token = IERC20(_tokenAdd);
    }

    function vestedTokens(address account) public view returns (uint256) {
        uint256 totTime = _lasts.sub(_cliff);
        uint accTime;
        if (_balances[account] == 0 || _lastClaim[account] >= now) { return 0; }
        else {
            if (_lastClaim[account] <= _cliff && now <= _cliff) {
                return 0;
            } else if (_lastClaim[account] <= _cliff && _cliff < now && _lasts > now) {
                accTime = now.sub(_cliff);
                return (_amounts[account].mul(accTime).div(totTime));
            } else if (_lasts <= now) {
                return _balances[account];
            } else if (_lastClaim[account] > _cliff && _lasts > now) {
                accTime = now.sub(_lastClaim[account]);
                return (_amounts[account].mul(accTime).div(totTime));
            } else {
                return 0;
            }
        }
    }

    function addVesters(address [] memory owners, uint256 [] memory amounts) external onlyOwner() {
        require(amounts.length == owners.length, "Vesting: Incorrect vesting data");
        uint256 totalTokens = 0;
        for(uint i=0; i < owners.length; i++) {
            _amounts[owners[i]] = amounts[i];
            _balances[owners[i]] = amounts[i];
            totalTokens += amounts[i];
        }
        _token.transferFrom(_msgSender(), address(this), totalTokens);
    }

    function emergencyPause(bool _state) external onlyOwner() {
        paused = _state;
    }

    function emergencyWithdraw() external onlyOwner() {
        uint256 tokenBal = _token.balanceOf(address(this));
        _token.transfer(_msgSender(), tokenBal);
    }

    function claimVestedTokens() external notPaused {
        require(_lastClaim[_msgSender()] < now, "Vesting: not enough time");
        uint256 vested = vestedTokens(_msgSender());
        require(vested > 0 && _balances[_msgSender()] > 0, "Vesting: No vested tokens");
        _lastClaim[_msgSender()] = now;
        if (_balances[_msgSender()] < vested) {
            vested = _balances[_msgSender()];
        }
        _balances[_msgSender()] = _balances[_msgSender()].sub(vested);
        _token.transfer(_msgSender(), vested);
        emit Claim(_msgSender(),now,vested);       
    }

    modifier notPaused() {
        require(!paused, "Vesting: claims paused");
        _;
    }
}