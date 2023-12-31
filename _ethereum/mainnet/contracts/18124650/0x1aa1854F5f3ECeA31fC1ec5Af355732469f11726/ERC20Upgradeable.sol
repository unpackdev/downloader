// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract SSloth is ERC20Upgradeable, OwnableUpgradeable {
    /// fee receiver addresses
    address public ecosystem;
    address public treasury;
    address public liquidity;

    /// fee percentages
    /// If feePc value is 100, fee percentage is 1%
    uint256 public burnFeePc; // Default is 1%
    uint256 public ecosystemFeePc;
    uint256 public treasuryFeePc;
    uint256 public liquidityFeePc;

    uint256 public constant DENOMINATOR = 10000;

    event SetBurn(
        uint256 feePc,
        uint256 changedAt
    );

    event SetEcosystemFee(
        address receiver,
        uint256 feePc,
        uint256 changedAt
    );

    event SetTreasuryFee(
        address receiver,
        uint256 feePc,
        uint256 changedAt
    );

    event SetLiquidityFee(
        address receiver,
        uint256 feePc,
        uint256 changedAt
    );

    event SetFeePercent(
        uint256 burnFeePercent,
        uint256 ecosystemFeePercent,
        uint256 treasuryFeePercent,
        uint256 liquidityFeePercent,
        uint256 changedAt
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint256 amount,
        address newOwner,
        address _ecosystem,
        address _treasury,
        address _liquidity
    ) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);

        if (newOwner == address(0) || _ecosystem == address(0) || _treasury == address(0) || _liquidity == address(0)) {
            revert ZeroAddress();
        }

        _mint(newOwner, amount);

        ecosystem = _ecosystem;
        treasury = _treasury;
        liquidity = _liquidity;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Set burn fee percent by only owner
    /// @param feePc new burn fee percent. If you want to set the fee percentage to 1%, feePc should be 100.
    function setBurnFee(uint256 feePc) external onlyOwner {
        burnFeePc = feePc;

        emit SetBurn(feePc, block.timestamp);
    }

    /// @notice Set Ecosystem fee address and percent by only owner
    /// @dev new fee receiver should be non-zero address
    /// @param receiver new fee receiver address
    /// @param feePc new fee percent. If you want to set the fee percentage to 1%, feePc should be 100.
    function setEcosystemFee(address receiver, uint256 feePc) external onlyOwner {
        if (receiver == address(0)) {
            revert ZeroAddress();
        }
        ecosystem = receiver;
        ecosystemFeePc = feePc;

        emit SetEcosystemFee(receiver, feePc, block.timestamp);
    }

    /// @notice Set Treasury fee address and percent by only owner
    /// @dev new fee receiver should be non-zero address
    /// @param receiver new fee receiver address
    /// @param feePc new fee percent. If you want to set the fee percentage to 1%, feePc should be 100.
    function setTreasuryFee(address receiver, uint256 feePc) external onlyOwner {
        if (receiver == address(0)) {
            revert ZeroAddress();
        }
        treasury = receiver;
        treasuryFeePc = feePc;

        emit SetTreasuryFee(receiver, feePc, block.timestamp);
    }

    /// @notice Set Liquidity fee address and percent by only owner
    /// @dev new fee receiver should be non-zero address
    /// @param receiver new fee receiver address
    /// @param feePc new fee percent. If you want to set the fee percentage to 1%, feePc should be 100.
    function setLiquidityFee(address receiver, uint256 feePc) external onlyOwner {
        if (receiver == address(0)) {
            revert ZeroAddress();
        }
        liquidity = receiver;
        liquidityFeePc = feePc;

        emit SetLiquidityFee(receiver, feePc, block.timestamp);
    }

    /// @notice Set all fee percent
    /// @dev new fee percent. If you want to set the fee percentage to 1%, feePc should be 100.
    /// @param _burnFeePc burn fee percent
    /// @param _ecosystemFeePc ecosystem fee percent
    /// @param _treasuryFeePc treasury fee percent
    /// @param _liquidityFeePc liquidity fee percent
    function setFeePercent(uint256 _burnFeePc, uint256 _ecosystemFeePc, uint256 _treasuryFeePc, uint256 _liquidityFeePc) external onlyOwner {
        burnFeePc = _burnFeePc;
        ecosystemFeePc = _ecosystemFeePc;
        treasuryFeePc = _treasuryFeePc;
        liquidityFeePc = _liquidityFeePc;

        emit SetFeePercent(_burnFeePc, _ecosystemFeePc, _treasuryFeePc, _liquidityFeePc, block.timestamp);
    }

    /// @dev See {IERC20-transfer}.
    /// Transfer fee is charged before token transfer.
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        uint256 _amount = _exchange(msg.sender, amount);
        return super.transfer(to, _amount);
    }

    /// @dev See {IERC20-transferFrom}.
    /// Transfer fee is charged before token transferFrom.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 _amount = _exchange(from, amount);
        return super.transferFrom(from, to, _amount);
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert();
    }

    /// @dev Transfer fee is charged before token transfer.
    /// @param from token transfer from address
    /// @param amount token transfer amount
    function _exchange(address from, uint256 amount) internal returns (uint256) {
        uint256 _denominator = DENOMINATOR;
        _burn(from, amount * burnFeePc / _denominator);

        _transfer(from, ecosystem, amount * ecosystemFeePc / _denominator);
        _transfer(from, treasury, amount * treasuryFeePc / _denominator);
        _transfer(from, liquidity, amount * liquidityFeePc / _denominator);

        return amount * (_denominator - burnFeePc  - ecosystemFeePc - treasuryFeePc - liquidityFeePc) / _denominator;
    }

    /** --------------------- Error --------------------- */
    error ZeroAddress();
}
