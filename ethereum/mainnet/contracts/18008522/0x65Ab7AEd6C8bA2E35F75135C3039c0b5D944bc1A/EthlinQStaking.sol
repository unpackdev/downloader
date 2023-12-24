// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";

import "./BasePool.sol";
import "./IEthlinQStaking.sol";

contract EthlinQStaking is BasePool, IEthlinQStaking {
    using Math for uint256;
    using SafeERC20 for IERC20;

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken
    ) BasePool(_name, _symbol, _depositToken) {}

    event Deposited(
        uint256 amount,
        address indexed receiver,
        address indexed from
    );
    event Withdrawn(
        address indexed receiver,
        address indexed from,
        uint256 amount
    );

    function deposit(uint256 _amount, address _receiver) external override {
        require(_amount > 0, "EthlinQStaking: cannot deposit 0");

        depositToken.safeTransferFrom(_msgSender(), address(this), _amount);

        _mint(_receiver, _amount);
        emit Deposited(_amount, _receiver, _msgSender());
    }

    function withdraw(uint256 _amount, address _receiver) external {
        // burn pool shares
        _burn(_msgSender(), _amount);

        // return tokens
        depositToken.safeTransfer(_receiver, _amount);
        emit Withdrawn(_receiver, _msgSender(), _amount);
    }

    receive() external payable {}

    // disable transfers
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        revert("NON_TRANSFERABLE");
    }
}
