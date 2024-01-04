// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";


contract ConditionUniswapV2Rate is GelatoConditionsStandard {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniRouter;

    constructor(
        IUniswapV2Router02 _uniswapV2Router
    ) {
        uniRouter = _uniswapV2Router;
    }

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(
        address[] memory _path,
        uint256 _sellAmount,
        uint256 _desiredRate,
        bool _greaterElseSmaller
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.checkRefRateUniswap.selector,
            _path,
            _sellAmount,
            _desiredRate,
            _greaterElseSmaller
        );
    }

    // STANDARD Interface
    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (address[] memory path,
         uint256 sellAmount,
         uint256 desiredRate,
         bool greaterElseSmaller
        ) = abi.decode(
             _conditionData[4:],  // slice out selector & taskReceiptId
             (address[],uint256,uint256,bool)
         );
        return checkRefRateUniswap(
            path, sellAmount, desiredRate, greaterElseSmaller
        );
    }

    // Specific Implementation
    function checkRefRateUniswap(
        address[] memory _path,
        uint256 _sellAmount,
        uint256 _desiredRate,
        bool _greaterElseSmaller
    )
        public
        view
        virtual
        returns(string memory)
    {
        uint256 currentRate = getUniswapRate(_path, _sellAmount);

        if (_greaterElseSmaller) {  // greaterThan
            if (currentRate >= _desiredRate) return OK;
            else return "ExpectedRateIsNotGreaterThanRefRate";
        } else {  // smallerThan
            if (currentRate <= _desiredRate) return OK;
            else return "ExpectedRateIsNotSmallerThanRefRate";
        }

    }

    function getUniswapRate(address[] memory _path, uint256 _sellAmount)
        public
        view
        returns(uint256 currentRate)
    {
        try uniRouter.getAmountsOut(_sellAmount, _path)
            returns (uint[] memory expectedRates) {
            currentRate = expectedRates[expectedRates.length - 1];
        } catch {
            revert("UniswapV2GetExpectedRateError");
        }
    }
}