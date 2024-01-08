// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
contract NFTABridge is Ownable {
    using SafeMath for uint;
    address public nfta; 
    bool public paused;
    uint public FEE = 10 * 10**18;
    uint public feeCollected;
    mapping (address => bool ) private whiteList;

    modifier whenNotPause() {
        require(!paused, "Paused");
        _;
    }

    modifier whenPause() {
        require(paused, "!Paused");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "Only-whitelist-minter");
        _;
    }

    // from is msg.sender, _to is receiver address on BSC or ETH (based on case)
    event Swap(address indexed _from, address indexed _to, uint indexed _amount);
    
    constructor(address _nfta) public {
        nfta = _nfta;

    }

    function swapNFTA(address _receiver, uint _amount) external whenNotPause() {
        require(_amount > FEE, 'Invalid-amount');
        uint receiveAmount = _amount.sub(FEE);
        feeCollected.add(FEE);
        IERC20(nfta).transferFrom(msg.sender, address(this), _amount);
        emit Swap(msg.sender, _receiver, receiveAmount);
    }

    function unlockNFTA(address _receiver, uint _amount) external onlyWhiteList() {
        IERC20(nfta).transfer(_receiver, _amount);
    }

    /**
    * ADMIN FUNCTION
    */
    function adminWhiteList(address _whitelistAddr, bool _whiteList) onlyOwner public {
        whiteList[_whitelistAddr] = _whiteList;
    }

    function setPause(bool pause) external onlyOwner() {
        paused = pause;
    }

    function setSwapFee(uint _fee) external onlyOwner() {
        FEE = _fee;
    }

    function emergencyWithdraw(address _to) external whenPause() onlyOwner() {
        uint balance = IERC20(nfta).balanceOf(address(this));
        IERC20(nfta).transfer(_to, balance);
    }

    function adminWithdrawFee(address _to) external onlyOwner() {
        uint256 currentFeeCollected = feeCollected;
        IERC20(nfta).transfer(_to, currentFeeCollected);
        feeCollected = 0;
    }
}