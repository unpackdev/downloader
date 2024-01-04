// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";


contract GeneCrossChain is Ownable, Pausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 geneToken;
    mapping(address => uint256) crossAmount;

    event CrossChain(address indexed user, uint256 amount, address receiver);

    constructor(
        IERC20 _geneToken
    ) public {
        geneToken = _geneToken;
    }

    function cross(uint256 amount, address receiver) external whenNotPaused {
        require(receiver != address(0x0));

        geneToken.safeTransferFrom(address(msg.sender), address(this), amount);
        crossAmount[msg.sender] = crossAmount[msg.sender].add(amount);

        emit CrossChain(msg.sender, amount, receiver);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function fetchToken(address receiver) external onlyOwner {
        if (receiver == address(0)) {
            receiver = owner();
        }
        geneToken.transfer(receiver, geneToken.balanceOf(address(this)));
    }
}

