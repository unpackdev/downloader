pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ICHIToken.sol";
 
abstract contract UseChiToken{    
    using SafeMath for uint256; 
    //ICHIToken  constant private chi = ICHIToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c); 
    
    // frees CHI to reduce gas costs
    // requires that msg.sender has approved this contract to spend its CHI
    modifier useCHI(address chi) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + (16 * msg.data.length);
        ICHIToken(chi).freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }
     
}





