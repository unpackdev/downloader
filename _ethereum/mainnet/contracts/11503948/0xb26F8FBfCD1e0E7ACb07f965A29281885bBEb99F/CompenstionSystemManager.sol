// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import "./IBPool.sol";
import "./IReserve.sol";

import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title CompensationSystemManager
 * @author Ethichub
 */
contract CompensationSystemManager is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable public ethix;
    IERC20Upgradeable public dai;

    IReserve public compensationReserve;

    IBPool public pool;

    uint256 public maxCompensation;
    uint256 public maxEthixTolerance;

    event GetCompensation(uint256 swapAmount, uint256 spotPriceAfter);
    event StoreInReserve(uint256 amount, uint256 spotPriceAfter);

    function initialize(
        IERC20Upgradeable _ethix,
        IERC20Upgradeable _dai,
        IReserve _compensationReserve,
        IBPool _pool
    ) public initializer {
        __Ownable_init();
        ethix = _ethix;
        dai = _dai;
        compensationReserve = _compensationReserve;
        pool = _pool;
        maxCompensation = 3000 * 10**18;
        maxEthixTolerance = 10 * 10**18;
        dai.approve(address(pool), type(uint256).max - 1);
    }

    /**
     * Takes {amount} DAIs from user and swaps for ETHIX and
     * stores result in CompensationReseve
     */
    function storeInReserve(uint256 _daiAmount, uint256 _maxPrice) external {
        require(_daiAmount > 0, 'CompensationSystemManager: Amount cannot be 0');

        if (dai.allowance(address(this), address(pool)) < _daiAmount) {
            dai.approve(address(pool), _daiAmount);
        }

        require(
            dai.transferFrom(msg.sender, address(this), _daiAmount),
            'CompensationSystemManager: Error transferring DAIs'
        );

        (uint256 ethixOut, uint256 spotPriceAfter) =
            pool.swapExactAmountIn(address(dai), _daiAmount, address(ethix), 1, _maxPrice);

        require(
            ethix.transfer(address(compensationReserve), ethixOut),
            'CompensationSystemManager: Error transferring ETHIX to CompensationReserve'
        );

        emit StoreInReserve(ethixOut, spotPriceAfter);
    }

    /**
     * Take {amount} ETHIX from reserve, swap for DAIs and transfer tokens
     * to function caller and return leftovers to the CompensationManager
     */
    function getCompensation(uint256 _daiAmount, uint256 _maxPrice) external onlyOwner {
        require(_daiAmount > 0, 'CompensationSystemManager: Amount cannot be 0');
        require(
            _daiAmount <= maxCompensation,
            'CompensationSystemManager: Amount cannot be superior to maxCompensation'
        );
        uint256 ethixIn =
            pool.calcInGivenOut(
                pool.getBalance(address(ethix)),
                pool.getDenormalizedWeight(address(ethix)),
                pool.getBalance(address(dai)),
                pool.getDenormalizedWeight(address(dai)),
                _daiAmount,
                pool.getSwapFee()
            );
        uint256 maxEthixIn = ethixIn.add(ethixIn.mul(maxEthixTolerance).div(100 * 10**18));

        if (ethix.allowance(address(this), address(pool)) < maxEthixIn) {
            ethix.approve(address(pool), maxEthixIn);
        }

        require(
            compensationReserve.transfer(payable(address(this)), maxEthixIn),
            'CompensationSystemManager: Error transfering from compensation reserve'
        );

        (uint256 tokenAmountIn, uint256 spotPriceAfter) =
            pool.swapExactAmountOut(
                address(ethix),
                maxEthixIn,
                address(dai),
                _daiAmount,
                _maxPrice
            );

        require(
            dai.transfer(msg.sender, _daiAmount),
            'CompensationSystemManager: Error transferring DAIs'
        );

        if (ethix.balanceOf(address(this)) > 0) {
            require(
                ethix.transfer(address(compensationReserve), ethix.balanceOf(address(this))),
                'CompensationSystemManager: Error transferring leftover ETHIX'
            );
        }

        emit GetCompensation(tokenAmountIn, spotPriceAfter);
    }

    /**
    @dev sets a hard limit for DAI amount to ask for in getCompensation
    @param _maxCompensation amount in wei
    */
    function setMaxCompensation(uint256 _maxCompensation) external onlyOwner {
        // NOTE: we don't check for min max compensation as a way of voluntarily disabling compensations in emergencies 
        maxCompensation = _maxCompensation;
    }

    /**
    @dev sets a percentage that will the define the max amount of ETHIX allowed to be exchanged in getCompensation
    @param _maxEthixTolerance percentage amount in wei
    */
    function setMaxEthixTolerance(uint256 _maxEthixTolerance) external onlyOwner {
        require(
            _maxEthixTolerance >= 10**17,
            'CompensationSystemManager: wrong value for _maxEthixTolerance'
        );
        maxEthixTolerance = _maxEthixTolerance;
    }
}
