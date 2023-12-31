pragma solidity ^0.8.4;

import "./IERC20.sol";

interface ICurvePool {
    function balances(uint256 _idx) external view returns (uint256);
}

contract CurveLPVotes {

    ICurvePool public constant JPEG_PETH = ICurvePool(0x69f23488e0f5789238F101d976B852C129e682dC);
    IERC20 public constant LP_TOKEN = IERC20(0xDA68f66fC0f10Ee61048E70106Df4BDB26bAF595);
    IERC20 public constant GAUGE_TOKEN = IERC20(0x839d92046F1e62A51A2b5705ecaE41DF152545ec);
    IERC20 public constant REWARD_POOL = IERC20(0x6bf9762014336cf87CfA8bb93B50efeD73c96FD5);

    function getVotingPower(address _account) external view returns (uint256) {
        uint256 _balance = LP_TOKEN.balanceOf(_account) + GAUGE_TOKEN.balanceOf(_account) + REWARD_POOL.balanceOf(_account);
        uint256 _totalSupply = LP_TOKEN.totalSupply();

        uint256 _jpegReserves = JPEG_PETH.balances(0);
        
        return _jpegReserves * _balance / _totalSupply;
    }

}