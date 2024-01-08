// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";

interface IInterestRateModelClient {
    function updateInterest() external returns (bool);
}

/**
 * @title dForce's Fixed Interest Rate Model Contract
 * @author dForce
 */
contract FixedInterestRateModel is Ownable {
    // ratePerBlock must not exceed this value
    uint256 internal constant ratePerBlockMax = 0.001e18;

    /**
     * @notice The approximate number of Ethereum blocks produced each year
     * @dev This is not used internally, but is expected externally for an interest rate model
     */
    uint256 public constant blocksPerYear = 2425846;

    /**
     * @notice Borrow interest rates per block
     */
    mapping(address => uint256) public borrowRatesPerBlock;

    /**
     * @notice Supply interest rates per block
     */
    mapping(address => uint256) public supplyRatesPerBlock;

    /**
     * @dev Emitted when borrow rate for `target` is set to `rate`.
     */
    event BorrowRateSet(address target, uint256 rate);

    /**
     * @dev Emitted when supply rate for `target` is set to `rate`.
     */
    event SupplyRateSet(address target, uint256 rate);

    constructor() public {
        __Ownable_init();
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is an interest rate model contract.
     */
    function isInterestRateModel() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Get the current borrow rate per block
     * @param cash Not used by this model.
     * @param borrows Not used by this model.
     * @param reserves Not used by this model.
     * @return Current borrow rate per block (as a percentage, and scaled by 1e18).
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public view returns (uint256) {
        cash;
        borrows;
        reserves;
        return borrowRatesPerBlock[msg.sender];
    }

    /**
     * @dev Get the current supply interest rate per block.
     * @param cash Not used by this model.
     * @param borrows Not used by this model.
     * @param reserves Not used by this model.
     * @param reserveRatio Not used by this model.
     * @return The supply rate per block (as a percentage, and scaled by 1e18).
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveRatio
    ) external view returns (uint256) {
        cash;
        borrows;
        reserves;
        reserveRatio;
        return supplyRatesPerBlock[msg.sender];
    }

    /**
     * @notice Admin function to set the current borrow rate per block
     */
    function _setBorrowRate(address _target, uint256 _rate) public onlyOwner {
        require(_rate <= ratePerBlockMax, "Borrow rate invalid");

        // Settle interest before setting new one
        IInterestRateModelClient(_target).updateInterest();

        borrowRatesPerBlock[_target] = _rate;

        emit BorrowRateSet(_target, _rate);
    }

    /**
     * @notice Admin function to set the current supply interest rate per block
     */
    function _setSupplyRate(address _target, uint256 _rate) public onlyOwner {
        require(_rate <= ratePerBlockMax, "Supply rate invalid");

        // Settle interest before setting new one
        IInterestRateModelClient(_target).updateInterest();

        supplyRatesPerBlock[_target] = _rate;

        emit SupplyRateSet(_target, _rate);
    }

    /**
     * @notice Admin function to set the borrow interest rates per block for targets
     */
    function _setBorrowRates(
        address[] calldata _targets,
        uint256[] calldata _rates
    ) external onlyOwner {
        require(
            _targets.length == _rates.length,
            "Targets and rates length mismatch!"
        );

        uint256 _len = _targets.length;
        for (uint256 i = 0; i < _len; i++) {
            _setBorrowRate(_targets[i], _rates[i]);
        }
    }

    /**
     * @notice Admin function to set the supply interest rates per block for the targets
     */
    function _setSupplyRates(
        address[] calldata _targets,
        uint256[] calldata _rates
    ) external onlyOwner {
        require(
            _targets.length == _rates.length,
            "Targets and rates length mismatch!"
        );

        uint256 _len = _targets.length;
        for (uint256 i = 0; i < _len; i++) {
            _setSupplyRate(_targets[i], _rates[i]);
        }
    }
}
