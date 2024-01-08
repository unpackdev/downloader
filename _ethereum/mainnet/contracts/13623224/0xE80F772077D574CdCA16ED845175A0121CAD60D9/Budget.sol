// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./IBeanstalk.sol";

/**
 * @author publius
 * @title Budget
 */

contract Budget is OwnableUpgradeable {

    address public tokenAddress;
    address public beanstalkAddress;

    uint256 constant UINT256_MAX = 2**255+1;
    
    event Payment(address indexed payee, uint256 amount);

    function initialize(address _tokenAddress, address _beanstalkAddress) public initializer {
        tokenAddress = _tokenAddress;
        beanstalkAddress = _beanstalkAddress;
        IERC20(tokenAddress).approve(beanstalkAddress, UINT256_MAX);
        __Ownable_init();
    }

    function setBeanstalk(address _beanstalkAddress) public onlyOwner {
        beanstalkAddress = _beanstalkAddress;
        IERC20(tokenAddress).approve(beanstalkAddress, UINT256_MAX);
    }

    function balance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Pay Beans to a payee.
     * @param payee the address that is being paid.
     * @param amount the amount that is being paid.
     */
    function pay(address payee, uint256 amount) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Budget: Insufficient funds");
        token.transfer(payee, amount);
        emit Payment(payee, amount);
    }

    /**
     * @dev Sow Beans on the behalf of a payee.
     * @param amount the amount of Beans to sow.
     */
    function sow(uint256 amount) public onlyOwner {
        IBeanstalk(beanstalkAddress).sowBeans(amount);
    }

    /**
     * @dev Pay a plot to a payee.
     * @param payee the address that is being paid.
     * @param id the id of the plot being paid.
     * @param start the start index of the plot being paid.
     * @param end the end index of the plot being paid.
     */
    function payPlot(address payee, uint256 id, uint256 start, uint256 end) public onlyOwner {
        IBeanstalk(beanstalkAddress).transferPlot(address(this), payee, id, start, end);
    }
}