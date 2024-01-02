// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IElevatedMinterBurner.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title ElevatedMinterBurner
/// @notice ElevatedMinterBurner is a periphery contract for releasing, storing tokens and executing arbitrary calls.
contract ElevatedMinterBurner is ReentrancyGuard, IElevatedMinterBurner, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public token;
    
    //mapping(uint16=>uint256) public allowedOut;

    //mapping(uint16=>uint256) public allowedIn;

    mapping(address => bool) public ofts;

    constructor(IERC20 token_) {
        token = token_;
    }

    modifier onlyOwnerOrOperators() {
        require(msg.sender == owner() || ofts[msg.sender], "unauth");
        _;
    }

    function burn(uint16 dstChain, address from, uint256 amount) external override nonReentrant onlyOwnerOrOperators {
        // custom things can be added here
    }

    function mint(uint16 srcChain, address to, uint256 amount) external override nonReentrant onlyOwnerOrOperators {
        require(token.balanceOf(address(this)) > amount, "no IN liq");
        token.safeTransfer(to, amount);
    }

    function setOFT(address _who, bool _val) external onlyOwner {
        ofts[_who] = _val;
    }

    /*function setAllowedOut(uint16 chainId, uint256 _amount) external onlyOwner {
        allowedOut[chainId] = _amount;
    }

    function setAllowedIn(uint16 chainId, uint256 _amount) external onlyOwner {
        allowedIn[chainId] = _amount;
    }*/

    function withdrawArbitrary(address _asset, uint256 amount) external onlyOwner {
        IERC20(_asset).safeTransfer(owner(), amount);
    }

    function exec(address target, bytes calldata data) external onlyOwner {
        (bool success, bytes memory result) = target.call(data);
        if (!success) {
            if (result.length == 0) revert();
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }
}