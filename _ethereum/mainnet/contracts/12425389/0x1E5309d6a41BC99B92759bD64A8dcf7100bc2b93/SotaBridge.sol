// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SotaBridge is Ownable {
    using SafeMath for uint256;
    address public sota;
    bool public paused;
    uint256 public FEE = 10;
    uint256 public feeCollected;
    mapping(address => bool) private whiteList;

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
    event Swap(
        address indexed _from,
        address indexed _to,
        uint256 indexed _amount
    );

    constructor(address _sota) public {
        sota = _sota;
    }

    function swapSota(address _receiver, uint256 _amount) public whenNotPause {
        require(_amount > FEE, "Invalid-amount");
        uint256 receiveAmount = _amount.sub(FEE);
        feeCollected.add(FEE);
        IERC20(sota).transferFrom(msg.sender, address(this), _amount);
        emit Swap(msg.sender, _receiver, receiveAmount);
    }

    function unlockSota(address _receiver, uint256 _amount)
        public
        onlyWhiteList
    {
        IERC20(sota).transfer(_receiver, _amount);
    }

    /**
     * ADMIN FUNCTION
     */
    function adminWhiteList(address _whitelistAddr, bool _whiteList)
        public
        onlyOwner
    {
        whiteList[_whitelistAddr] = _whiteList;
    }

    function setPause(bool pause) public onlyOwner {
        paused = pause;
    }

    function setSwapFee(uint256 _fee) public onlyOwner {
        FEE = _fee;
    }

    function emergencyWithdraw(address _to) public whenPause onlyOwner {
        uint256 balance = IERC20(sota).balanceOf(address(this));
        IERC20(sota).transfer(_to, balance);
    }

    function adminWithdrawFee(address _to) public onlyOwner {
        IERC20(sota).transfer(_to, feeCollected);
    }
}
