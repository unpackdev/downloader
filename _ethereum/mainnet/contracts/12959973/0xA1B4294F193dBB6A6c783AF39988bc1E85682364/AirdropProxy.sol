// contracts/AirdropProxy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/**
 *       _   _                         _     _             _ _             _
 *      | | | |                       | |   | |           | (_)           (_)
 *   ___| |_| |__   ___ _ __ ___  __ _| |___| |_ _   _  __| |_  ___  ___   _  ___
 *  / _ \ __| '_ \ / _ \ '__/ _ \/ _` | / __| __| | | |/ _` | |/ _ \/ __| | |/ _ \
 * |  __/ |_| | | |  __/ | |  __/ (_| | \__ \ |_| |_| | (_| | | (_) \__ \_| | (_) |
 *  \___|\__|_| |_|\___|_|  \___|\__,_|_|___/\__|\__,_|\__,_|_|\___/|___(_)_|\___/
 *
 *
 * @title AirdropProxy
 * @dev Simple proxy to airdrop ERC20 tokens to a list of recipients.
 * ERC20 tokens can be also withdraw from the owner.
 *
 * Authors: s.imo(at)etherealstudios(dot)io
 * Created: 03.08.2021
 */
contract AirdropProxy is Ownable {
    using SafeMath for uint256;

    function airdrop(address[] calldata _recipients, uint256 _values, address _tokenAddress) public onlyOwner() {
        require(_recipients.length > 0,       "empty recipients list");
        require(_values > 0,                  "value per address not valid");
        require(_tokenAddress != address (0), "tokenAddress not valid");

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _values.mul(_recipients.length), "not enough tokens on this proxy");

        for(uint i = 0; i < _recipients.length; i++){
            token.transfer(_recipients[i], _values);
        }
    }

    function withdraw(address _tokenAddress) public onlyOwner() {
        require(_tokenAddress != address (0), "tokenAddress not valid");

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) > 0, "empty balance, nothing to withdraw");

        token.transfer(_msgSender(), token.balanceOf(address(this)));
    }

}