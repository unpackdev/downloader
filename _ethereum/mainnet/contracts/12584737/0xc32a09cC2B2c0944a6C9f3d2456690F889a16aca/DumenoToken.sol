// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";

/// @title DumenoToken
/// @author Dumeno Team
contract DumenoToken is ERC20 {
    using SafeMath for uint256;

    uint256 internal constant BASE_UNITS = 1000000000000000000;
    uint256 internal constant INITIAL_MINT = 100000000 * BASE_UNITS;

    /// @notice The treasury address that controls the initial supply.
    address public treasury;

    /// @notice This is true if the initial supply is minted.
    bool public isInitialSupplyMinted;

    /// @notice MintInitialSupply is emmited when the initial supply is emitted to the treasury.
    event MintInitialSupply();

    /// @dev Can only be called by treasury.
    modifier onlyTreasury() {
        require(msg.sender == treasury, "DumenoToken::onlyTreasury: MUST_TREASURY");
        _;
    }

    constructor() ERC20("Dumeno", "DMN") {
        treasury = msg.sender;
    }

    /// @notice Mint the initial supply (10 % of the Dumeno tokens) to the Treasury.
    /// @param _mints The addresses that receive intial mints.
    /// @param _amounts The amount each mint receives.
    /// @param _cnt The number of mint and amount parameters (must match).
    function mintInitialSupply(
        address[] calldata _mints,
        uint256[] calldata _amounts,
        uint256 _cnt
    ) external onlyTreasury {
        // Ensure that the mint can only be executed once.
        require(isInitialSupplyMinted == false, "DumenoToken::mintInitialSupply: ALREADY_EXECUTED");
        // Ensure the integrity of the mints.
        require(_mints.length == _cnt, "DumenoToken::mintIntialSupply: BAD_MINT_CNT");
        require(_amounts.length == _cnt, "DumenoToken::mintIntialSupply: BAD_AMOUNTS_CNT");

        uint256 sum = 0;

        // Issue tokens to every mint.
        for (uint256 i = 0; i < _cnt; i++) {
            _mint(_mints[i], _amounts[i]);
            sum = sum.add(_amounts[i]);
        }

        // If there are any remaining, issue to the Treasury.
        if (sum < INITIAL_MINT) {
            _mint(treasury, INITIAL_MINT.sub(sum));
        }

        isInitialSupplyMinted = true;

        emit MintInitialSupply();
    }
}
