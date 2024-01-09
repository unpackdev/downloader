//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract Presale is Ownable {
    using SafeMath for uint256;


    address private _token = address(0);

    uint8 private _tokenDecimals = 18;

    uint256 private _rate = 0;

    address private beneficiary;

    bool private active = false;

    constructor(address beneficiary_) {
        beneficiary = beneficiary_;
    }

    function getTokenDecimals() public view returns(uint8) {
        return _tokenDecimals;
    }

    function setTokenDecimals(uint8 newDecimals) public onlyOwner {
        _tokenDecimals = newDecimals;
    }

    function setPresaleActive() public onlyOwner {
        active = !active;
    }

    function getPresaleStatus() public view returns (bool) {
        return active;
    }

    function setPresaleToken(address token_) public onlyOwner {
        _token = token_;
    }

    function presaleToken() public view returns (address) {
        return _token;
    }

    function setRate(uint256 rate_) public onlyOwner {
        _rate = rate_;
    }

    function removeERC20(address tokenAddress) public onlyOwner {
        require(
            IERC20(tokenAddress).transfer(
                msg.sender,
                IERC20(tokenAddress).balanceOf(address(this))
            ),
            "FAIL"
        );
    }

    function removeETH() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "FAIL");
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function tokensLeft() public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function buyTokens(uint256 payableAmount, address buyer) public {
        IERC20 tokenToSale = IERC20(_token);

        uint256 tokensToReceive = payableAmount.mul(_rate);
        // uint256 tokensToReceive = ((payableAmount / 10 ** 18) * _rate) * 10 ** _tokenDecimals;


        require(
            tokenToSale.balanceOf(address(this)) >= tokensToReceive,
            "Not enough tokens to sale"
        );

        require(
            tokenToSale.transfer(buyer, tokensToReceive),
            "Failed to transfer tokens"
        );

        (bool success,) = payable(beneficiary).call{value: payableAmount}(""); 
        require(success, "send eth error");
    }

    receive() external payable {
        require(msg.value > 0, "You sent 0 ETH");
        require(active, "Presale is stopped");
        require(address(0) != _token, "Token not set");
        require(_rate > 0, "Rate could not be 0");
        buyTokens(msg.value, msg.sender);
    }
}
