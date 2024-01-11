//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BrewlabsTokenConstructor is Ownable {
    address public feeAddress = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;
    uint256 public feeAmount = 0.0005 ether;

    constructor() {}

    function _balanceOf(address _token) public view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    function setFeeAddress(address payable _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function setFeeAmount(uint256 _feeAmount) public onlyOwner {
        feeAmount = _feeAmount;
    }

    function constructorTransfer(
        address _token,
        uint256 _amount,
        address _to
    ) external payable {
        require(msg.value >= feeAmount, 'Constructor: fee is not enough');
        payable(feeAddress).transfer(feeAmount);
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        token.transfer(_to, this._balanceOf(_token));
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueToken(address _token) external onlyOwner {
        if(_token == address(0x0)) {
            uint256 _tokenAmount = address(this).balance;
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, _tokenAmount);
        }
    }

    receive() external payable {}
}