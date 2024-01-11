//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

// 1. A -> depositStableToken
// Wait 1 hour
// If no wbtc in contract -> A call function refundStableTokenIfWbtcNotDepositedInOneHour
// 2. B -> depositWBTC 
// 3. B -> getStableTokenByWBTCOwner
// 4. B -> sendStableToken
// 5. A -> getStableTokenByStableOwner
// .. A -> badFinishEscrow

contract Escrow {

    using SafeERC20 for IERC20;
    uint public constant TIMER = 20 minutes;
    uint public startDate;
    uint public immutable wbtcAmount;
    uint public immutable stableTokenAmount;
    uint public sumStableToken;
    uint public rate;
    uint public preStart; // time of first deposit (before start deal)
    IERC20 public immutable wbtc;
    IERC20 public immutable stableToken;
    mapping(address => bool) public wbtcOwner;
    mapping(address => bool) public stableTokenOwner;
    bool public wbtcDeposited;
    bool public stableTokenDeposited;
    bool public getStable;

    modifier onlyWbtcOwner() {
        require(wbtcOwner[msg.sender], "only wbtc owner");
        _;
    }

    modifier onlyStableTokenOwner() {
        require(stableTokenOwner[msg.sender], "only stableToken owner");
        _;
    }

    modifier ifWbtcDeposited() {
        require(wbtcDeposited, "wbtc not deposited");
        _;
    }

    modifier ifStableTokenDeposited() {
        require(stableTokenDeposited, "stable token not deposited");
        _;
    }

    modifier ifWbtcNOTDeposited() {
        require(!wbtcDeposited, "wbtc deposited");
        _;
    }

    modifier ifStableTokenNOTDeposited() {
        require(!stableTokenDeposited, "stable token deposited");
        _;
    }

    constructor(
        address _wbtc,
        address _stableToken,
        address[] memory _wbtcOwner,
        address[] memory  _stableTokenOwner,
        uint _wbtcAmount,
        uint _stableTokenAmount
    ) {
        wbtc = IERC20(_wbtc);
        stableToken = IERC20(_stableToken);
        for(uint i=0; i<_wbtcOwner.length; i++) {
            wbtcOwner[_wbtcOwner[i]] = true;
        }
        for(uint i=0; i<_stableTokenOwner.length; i++) {
            stableTokenOwner[_stableTokenOwner[i]] = true;
        }
        wbtcAmount = _wbtcAmount;
        stableTokenAmount = _stableTokenAmount;
        rate = _stableTokenAmount * 1e8 / _wbtcAmount;
    }

    function depositWBTC() external onlyWbtcOwner ifWbtcNOTDeposited {
        wbtcDeposited = true;
        wbtc.safeTransferFrom(msg.sender, address(this), wbtcAmount);
        _check();
    }

    function depositStableToken() external onlyStableTokenOwner ifStableTokenNOTDeposited {
        stableTokenDeposited = true;
        stableToken.safeTransferFrom(msg.sender, address(this), stableTokenAmount);
        _check();
    }

    function refundNotDepositedInOneHour() external  {
        require((block.timestamp - preStart) >= 1 hours, "wait 1 hour");
        require(!stableTokenDeposited || !wbtcDeposited, "all tokens have been deposited");
        if(wbtcOwner[msg.sender]) {
            wbtc.safeTransfer(msg.sender, wbtcAmount);        
        }
        else if(stableTokenOwner[msg.sender]) {
            stableToken.safeTransfer(msg.sender, stableTokenAmount);
        }
        else {
            revert("who are you?");
        }
    }

    function sendStableToken(uint _amount) external onlyWbtcOwner {
        require((block.timestamp - startDate) <= TIMER, "time is out");
        sumStableToken += _amount;
        stableToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint wbtcAmountTemp = _amount * 1e8 / rate;
        wbtc.safeTransfer(msg.sender, wbtcAmountTemp);
    }

    function getStableTokenByWBTCOwner() external onlyWbtcOwner {
        require(startDate != 0, "escrow hasnt start yet");
        stableToken.safeTransfer(msg.sender, stableTokenAmount);
        getStable = true;
    }

    function getStableTokenByStableOwner() external onlyStableTokenOwner {
        require(getStable, "wbtc owner hasnt get stables");
        stableToken.safeTransfer(msg.sender, stableToken.balanceOf(address(this)));
    }

    function badFinishEscrow() external onlyStableTokenOwner {
        require((block.timestamp - startDate) > TIMER, "time is not out yet");
        wbtc.safeTransfer(msg.sender, wbtc.balanceOf(address(this)));
    }

    function _check() internal {
        if(preStart == 0) {
            // first function call
            preStart = block.timestamp;
        }
        require((block.timestamp - preStart) < 1 hours, "too late");
        if(wbtcDeposited && stableTokenDeposited) {
            startDate = block.timestamp;
        }
    }

    
}