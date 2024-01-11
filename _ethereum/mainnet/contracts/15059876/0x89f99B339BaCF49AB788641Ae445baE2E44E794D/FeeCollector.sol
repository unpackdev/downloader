// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Percent.sol";
import "./IFeeHandler.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract FeeCollector {
    /// Handler that this collector transfers fees to
    IFeeHandler public feeHandler;

    /// Determines the fee percent taken by this collector
    uint256 public collectorPercent;

    /// Number of decimals of precision
    uint256 public decimals;

    // Emitted when a new _feeHandler address is set by the owner
    event SetFeeHandler(address indexed setter, address feeHandler);

    // Emitted when a new collector percent is set by the owner
    event SetCollectorPercentAndDecimals(
        address indexed setter, 
        uint256 collectorPercent,
        uint256 decimals
    );

    /// Return true if the feeHandler address is set and false otherwise
    function isFeeHandlerSet() public view returns (bool) {
        return address(feeHandler) != address(0);
    }

    /// Return the collector fee computed from the _amount and the collectorPercent
    function getCollectorFee(uint256 _amount) public view returns (uint256 collectorFee) {
        collectorFee = Percent.getPercentage(_amount, collectorPercent, decimals);
    }

    /// Split _amount based on collectorPercent and return the collectorFee and the remainder
    /// where remainder == _amount - collectorFee
    function getCollectorFeeSplit(uint256 _amount) 
        public 
        view 
        returns (uint256 collectorFee, uint256 remainder) 
    {
        (collectorFee, remainder) = Percent.splitByPercent(_amount, collectorPercent, decimals);
    }

    // Delegate feeHandler to transfer _fee amount of _token from _from
    function _delegateTransfer(IERC20 _token, address _from, uint256 _fee) internal virtual {
        require(address(feeHandler) != address(0), "FeeCollector: handler not set");
        if (_fee > 0) {
            _token.approve(address(feeHandler), _fee);
            feeHandler.transferFee(_token, _from, msg.sender, _fee);
        }
    }

    /// Called by the owner to set a new _feeHandler address
    function _setFeeHandler(address _feeHandler) internal virtual { 
        require(_feeHandler != address(0), "FeeCollector: zero address");
        feeHandler = IFeeHandler(_feeHandler);
        emit SetFeeHandler(msg.sender, address(_feeHandler));
    }

    // Called by the owner to set the _collectorPercent and the number of _decimals of precision 
    // used when calculating percents collected from transactions
    function _setCollectorPercentAndDecimals(uint256 _collectorPercent, uint256 _decimals) 
        internal 
        virtual 
    {
        require(
            Percent.isValidPercent(_collectorPercent, _decimals), 
            "FeeCollector: percent exceeds max"
        );
        collectorPercent = _collectorPercent;
        decimals = _decimals;
        emit SetCollectorPercentAndDecimals(msg.sender, _collectorPercent, decimals);
    }
}
