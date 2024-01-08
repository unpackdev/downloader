// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./draft-ERC20Permit.sol";
import "./TimelockController.sol";
import "./Math.sol";


/// @notice name = LUNAR Token
/// @notice symbol = LUNAR
/// @notice total supply = 20 mil
contract LunarToken is ERC20, ERC20Permit, ERC20Burnable {
    using SafeERC20 for IERC20;

    uint256 internal constant _CAP = 20_000_000e18; // TOTAL_AMOUNT
    address public governance;
    address public minter;

    constructor(
        address _governance,
        address _minter,
        address _treasury,
        address _initialOffering
    ) ERC20("Lunar Token", "LUNAR") ERC20Permit("LUNAR Token") {
        governance = _governance;
        minter = _minter;
        _mint(_initialOffering, 800_000e18); // 4% from TOTAL_AMOUNT
        _mint(_treasury, 800_000e18); // 4% from TOTAL_AMOUNT
    }

    modifier onlyGovernance() {
        require(_msgSender() == governance, "LunarToken: only governance can perform this action");
        _;
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, "LunarToken: only minter can perform this action");
        _;
    }

    function setMinter(address _minter) external onlyGovernance {
        minter = _minter;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function cap() public pure returns (uint256) {
        return _CAP;
    }

    /// @notice Method to claim junk and accidentally sent tokens
    function rescueTokens(
        IERC20 _token,
        address payable _to,
        uint256 _balance
    ) external onlyGovernance {
        require(_to != address(0), "LunarToken: can not send to zero address");

        if (_token == IERC20(address(0))) {
            // for Ether
            uint256 totalBalance = address(this).balance;
            uint256 balance = _balance == 0 ? totalBalance : Math.min(totalBalance, _balance);
            require(balance > 0, "LunarToken: trying to send 0 ethers");
            _to.transfer(balance);
        } else {
            // for any ERC20
            uint256 totalBalance = _token.balanceOf(address(this));
            uint256 balance = _balance == 0 ? totalBalance : Math.min(totalBalance, _balance);
            require(balance > 0, "LunarToken: trying to send 0 tokens");
            _token.safeTransfer(_to, balance);
        }
    }
}
