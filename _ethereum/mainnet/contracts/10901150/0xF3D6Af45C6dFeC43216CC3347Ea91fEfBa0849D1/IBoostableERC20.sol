// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Token agnostic fuel struct that is passed around when the fuel is burned by a different (token) contract.
// The contract has to explicitely support the desired token that should be burned.
struct TokenFuel {
    // A token alias that must be understood by the target contract
    uint8 tokenAlias;
    uint96 amount;
}

/**
 * @dev Extends the interface of the ERC20 standard as defined in the EIP with
 * `boostedTransferFrom` to perform transfers without having to rely on an allowance.
 */
interface IBoostableERC20 {
    // ERC20
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Extension

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`.
     *
     * If the caller is known by the callee, then the implementation should skip approval checks.
     * Also accepts a data payload, similar to ERC721's `safeTransferFrom` to pass arbitrary data.
     *
     */
    function boostedTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Burns `fuel` from `from`.
     */
    function burnFuel(address from, TokenFuel memory fuel) external;
}
