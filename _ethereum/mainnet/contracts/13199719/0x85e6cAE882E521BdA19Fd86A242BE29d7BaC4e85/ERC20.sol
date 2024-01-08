// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

// import "./ERC20Storage.sol";
import "./IERC20.sol";

/**
 * @title ERC20 Implementation.
 * @author MirrorXYZ
 */
contract ERC20 is IERC20, IERC20Events {
    // ============ ERC20 Attributes ============
    /// @notice EIP-20 token name for this token
    string public override name;

    /// @notice EIP-20 token symbol for this token
    string public override symbol;

    /// @notice EIP-20 token decimals for this token
    uint8 public constant override decimals = 18;

    // ============ Mutable ERC20 Storage ============
    /// @notice EIP-20 total number of tokens in circulation
    uint256 public override totalSupply;

    /// @notice EIP-20 official record of token balances for each account
    mapping(address => uint256) public override balanceOf;

    /// @notice EIP-20 allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) public override allowance;

    /**
     * @notice Initialize and assign total supply when using
     * proxy pattern. Only callable during contract deployment.
     * @param totalSupply_ is the initial token supply
     * @param to_ is the address that will hold the initial token supply
     */
    function initialize(uint256 totalSupply_, address to_) external {
        // Ensure that this function is only callable during contract construction.
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }

        totalSupply = totalSupply_;
        balanceOf[to_] = totalSupply_;
        emit Transfer(address(0), to_, totalSupply_);
    }

    // ============ ERC20 Spec ============

    /**
     * @dev Function to increase allowance of tokens.
     * @param spender The address that will receive an allowance increase.
     * @param value The amount of tokens to increase allowance.
     */
    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Function to transfer tokens.
     * @param to The address that will receive the tokens.
     * @param value The amount of tokens to transfer.
     */
    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to transfer an accounts tokens. Sender of txn must be approved.
     * @param from The address that will transfer tokens.
     * @param to The address that will receive the tokens.
     * @param value The amount of tokens to transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            allowance[from][msg.sender] >= value,
            "transfer amount exceeds spender allowance"
        );

        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }

    // ============ Private Utils ============

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(balanceOf[from] >= value, "transfer amount exceeds balance");

        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;

        emit Transfer(from, to, value);
    }
}
