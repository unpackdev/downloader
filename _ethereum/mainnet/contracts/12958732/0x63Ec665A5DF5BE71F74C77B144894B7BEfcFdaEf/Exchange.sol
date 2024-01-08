pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract Exchange is Ownable {
    IERC20 public relayToken;
    IERC20 public zeroToken;
    bool private _paused;
    event Paused(address account);
    event Unpaused(address account);

    constructor(address _relayToken, address _zeroToken) {
        relayToken = IERC20(_relayToken);
        zeroToken = IERC20(_zeroToken);
        _paused = false;
    }

    function swap(uint256 amount) public whenNotPaused {
        zeroToken.transferFrom(msg.sender, address(this), amount);
        relayToken.transfer(msg.sender, amount / 100);
    }

    function adminWithdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function adminWithdrawERC20(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
