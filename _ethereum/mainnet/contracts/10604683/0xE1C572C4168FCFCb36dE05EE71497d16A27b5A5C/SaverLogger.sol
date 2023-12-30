pragma solidity ^0.6.0;

contract SaverLogger {
    event Repay(
        uint256 indexed cdpId,
        address indexed owner,
        uint256 collateralAmount,
        uint256 daiAmount
    );
    event Boost(
        uint256 indexed cdpId,
        address indexed owner,
        uint256 daiAmount,
        uint256 collateralAmount
    );

    // solhint-disable-next-line func-name-mixedcase
    function LogRepay(uint256 _cdpId, address _owner, uint256 _collateralAmount, uint256 _daiAmount)
        public
    {
        emit Repay(_cdpId, _owner, _collateralAmount, _daiAmount);
    }

    // solhint-disable-next-line func-name-mixedcase
    function LogBoost(uint256 _cdpId, address _owner, uint256 _daiAmount, uint256 _collateralAmount)
        public
    {
        emit Boost(_cdpId, _owner, _daiAmount, _collateralAmount);
    }
}
