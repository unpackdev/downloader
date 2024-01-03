// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface IERC20Mintable is IERC20 {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     */
    function mint(address to, uint256 value) external;
}

/**
 * @dev Multisender without the fees
 */
contract Multisend is Ownable {
    using SafeMath for uint256;

    event Multiminted(uint256 total, address tokenAddress);
    event Multisended(uint256 total, address tokenAddress);
    
    uint256 public arrayLimit;
    
    /**
     * @dev Multisender uses _arrayLimit=200 by default
     */
    constructor(uint256 _arrayLimit) {
        arrayLimit = _arrayLimit;
    }

    function multimintToken(address token, address[] calldata _contributors, uint256[] calldata _balances) external onlyOwner {
        uint256 total = 0;
        require(_contributors.length <= arrayLimit);
        IERC20Mintable mintableToken = IERC20Mintable(token);
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            mintableToken.mint(_contributors[i], _balances[i]);
            total += _balances[i];
        }
        emit Multiminted(total, token);
    }

    function multisendToken(address token, address payable[] calldata _contributors, uint256[] calldata _balances) external payable onlyOwner {
        if (token == 0x000000000000000000000000000000000000bEEF){
            multisendEther(_contributors, _balances);
        } else {
            uint256 total = 0;
            require(_contributors.length <= arrayLimit);
            IERC20 erc20token = IERC20(token);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
                total += _balances[i];
            }
            emit Multisended(total, token);
        }
    }

    function multisendEther(address payable[] calldata _contributors, uint256[] calldata _balances) public payable onlyOwner {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }
}
