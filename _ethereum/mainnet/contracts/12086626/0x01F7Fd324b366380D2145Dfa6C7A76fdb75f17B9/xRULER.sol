// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IxRULER.sol";
import "./IERC20Permit.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./SafeERC20.sol";

contract xRULER is ERC20("xRULER", "xRULER"), ERC20Permit("xRULER"), IxRULER, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable ruler;

    constructor(IERC20 _ruler) {
        ruler = _ruler;
    }

    function getShareValue() external view override returns (uint256) {
        return totalSupply() > 0
            ? 1e18 * ruler.balanceOf(address(this)) / totalSupply()
            : 1e18;
    }

    function deposit(uint256 _amount) public override {
        uint256 totalRuler = ruler.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        // if user is first depositer, mint _amount of xRULER
        if (totalShares == 0 || totalRuler == 0) {
            _mint(msg.sender, _amount);
        } else {
            // loss of precision if totalRuler is significantly greater than totalShares
            // seeding the pool with decent amount of RULER prevents this
            uint256 myShare = _amount * totalShares / totalRuler;
            _mint(msg.sender, myShare);
        }
        ruler.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function depositWithPermit(uint256 _amount, Permit calldata permit) external override {
        IERC20Permit(address(ruler)).permit(
            permit.owner,
            permit.spender,
            permit.amount,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        deposit(_amount);
    }

    function withdraw(uint256 _share) external override {
        uint256 totalShares = totalSupply();
        uint256 shareInRuler = _share * ruler.balanceOf(address(this)) / totalShares;
        _burn(msg.sender, _share);
        ruler.safeTransfer(msg.sender, shareInRuler);
        emit Withdraw(msg.sender, _share, shareInRuler);
    }

    /// @notice Tokens that are accidentally sent to this contract can be recovered
    function collect(IERC20 _token) external override onlyOwner {
        if (totalSupply() > 0) {
            require(_token != ruler, "xRULER: cannot collect RULER");
        }
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "xRULER: _token balance is 0");
        _token.safeTransfer(msg.sender, balance);
    }
}