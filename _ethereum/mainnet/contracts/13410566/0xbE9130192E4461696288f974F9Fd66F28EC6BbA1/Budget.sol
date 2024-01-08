// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";

/**
 * @author publius
 * @title Budget
 */

contract Budget is OwnableUpgradeable {

    address public tokenAddress;
    
    event Payment(address indexed payee, uint256 amount);

    function initialize(address _tokenAddress) public initializer {
        tokenAddress = _tokenAddress;
        __Ownable_init();
    }

    function balance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Pay 
     * @param payee the address that is being paid.
     * @param amount the amount that is being paid.
     */
    function pay(address payee, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Budget: Insufficient funds");
        token.transfer(payee, amount);

        emit Payment(payee, amount);
    }
}