//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IKeys.sol";

/** Burns KEY Tokens Quarterly
*/
contract TokenBurner {
    
    // Last Burn Time
    uint256 lastBurnTime;

    // Data
    address public immutable token;
    uint256 public constant burnWaitTime = 26 * 10**5;
    uint256 public constant amount = 5 * 10**6 * 10**9;
    
    // events
    event Burned(uint256 numTokens);
    
    constructor(
        address _token
        ) {
            token = _token;
        } 
    
    // claim
    function burn() external {
        _burn();
    }
    
    function _burn() internal {
        
        // number of tokens locked
        uint256 tokensToBurn = IERC20(token).balanceOf(address(this));
        
        // number of tokens to unlock
        require(tokensToBurn > 0, 'No Tokens To Burn');
        require(lastBurnTime + burnWaitTime <= block.number, 'Not Time To Burn');
        
        // amount to burn
        uint256 amountToBurn = amount > tokensToBurn ? tokensToBurn : amount;
        // update times
        lastBurnTime = block.number;
        
        // burn tokens
        IKeys(token).burnTokensIncludingDecimals(amountToBurn);
        
        emit Burned(amount);
    }
    
    receive() external payable {
        _burn();
        (bool s,) = payable(msg.sender).call{value: msg.value}("");
        if (s) {}
    }

    function getTimeTillBurn() external view returns (uint256) {
        return block.number >= (lastBurnTime + burnWaitTime) ? 0 : (lastBurnTime + burnWaitTime - block.number);
    }

}
