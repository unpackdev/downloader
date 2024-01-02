// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
 Send tokens to multiple addresses at once with a reduced complexity
*/
contract Cryptosender is Context, Ownable {

    constructor() {}

    // @dev Utility method to sum array of uints
    function _sumAmounts(uint256[] memory amounts) internal pure returns (uint256){
        uint sum = 0;
        uint length = amounts.length;
        for (uint i = 0; i < length; i++) {
            sum += amounts[i];
        }
        return sum;
    }

    // @notice Distribute ERC-20 tokens. Needs approval
    function distribute(
        address token,
        address[] memory destinations,
        uint256[] memory amounts
    ) public payable onlyOwner {
        require(amounts.length == destinations.length, "invalid input");
        uint length = destinations.length;
        for (uint i = 0; i < length; i++) {
            IERC20(token).transferFrom(msg.sender, destinations[i], amounts[i]);
        }
    }

    // @notice Distribute Ether
    function distributeEther(
        address[] memory destinations,
        uint256[] memory amounts
    ) public payable onlyOwner {
        require(amounts.length == destinations.length, "invalid input");
        uint length = destinations.length;
        for (uint i = 0; i < length; i++) {
            _sendEther(destinations[i], amounts[i]);
        }
    }

    // @notice Distribute multiple ERC20 tokens to one address. Need previous approve of all tokens
    function distributeMultipleERC20ToOneAddress(
        address[] memory tokens,
        uint256[] memory amounts,
        address destiny
    ) public payable onlyOwner {
        require(tokens.length == amounts.length, "invalid lengths");
        uint length = tokens.length;
        for (uint i = 0; i < length; i++) {
            IERC20(tokens[i]).transferFrom(msg.sender, destiny, amounts[i]);
        }
    }

    // @notice Distribute multiple ERC20 tokens to multiple addresses. Need previous approve of all tokens
    function distributeMultipleERC20ToMultipleAddress(
        address[] memory tokens,
        uint256[] memory amounts,
        address[] memory destinations
    ) public payable onlyOwner {
        require(tokens.length == amounts.length, "invalid lengths");
        require(tokens.length == destinations.length, "invalid input");
        uint length = tokens.length;
        for (uint i = 0; i < length; i++) {
            IERC20(tokens[i]).transferFrom(msg.sender, destinations[i], amounts[i]);
        }
    }

    // @dev Utility method for send native chain token
    function _sendEther(address to, uint256 amount) internal {
        (bool sent,) = payable(to).call{value: amount}("");
        require(sent == true);
    }

}
