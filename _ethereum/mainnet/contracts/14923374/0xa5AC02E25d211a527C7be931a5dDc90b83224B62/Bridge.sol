pragma solidity =0.7.6;

import "./Ownable.sol";
import "./IERC20.sol";

contract Bridge is Ownable {

    address public newToken;
    address public oldToken;

    constructor (address _newToken, address _oldToken) {
        newToken = _newToken;
        oldToken = _oldToken;
    }

    function depositNewBLOOM(uint _amount) external onlyOwner {
        IERC20(newToken).transferFrom(msg.sender, address(this), _amount);
    }

    function bridgeBLOOM() external {
        uint _amount = IERC20(oldToken).balanceOf(msg.sender);
        IERC20(oldToken).transferFrom(msg.sender, address(this), _amount);
        IERC20(newToken).transfer(msg.sender, _amount);
    }

    function retreiveToken(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}