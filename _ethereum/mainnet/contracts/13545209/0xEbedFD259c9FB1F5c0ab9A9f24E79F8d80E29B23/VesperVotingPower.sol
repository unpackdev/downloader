// SPDX-License-Identifier: MIT

//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./ICToken.sol";
import "./IUniswapV2Pair.sol";
import "./IVesperPool.sol";

/**
 * @title Calculate voting power for VSP holders
 */
contract VesperVotingPower {
    address public constant VSP = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421;
    address public constant vVSP = 0xbA4cFE5741b357FA371b506e5db0774aBFeCf8Fc;
    address public constant fVVSP_23 = 0x63475Ab76E578Ec27ae2494d29E1df288817d931; // RariFuse#23
    address public constant fVSP_23 = 0x0879DbeE0614cc3516c464522e9B2e10eB2D415A; // RariFuse#23
    address public constant fVVSP_110 = 0xCbB25B8E3c899C9CAFd9b60C40490aa51282d476; // RariFuse#110
    address public constant uniswapV2 = 0x6D7B6DaD6abeD1DFA5eBa37a6667bA9DCFD49077; // VSP-ETH pair
    address public constant sushiswap = 0x132eEb05d5CB6829Bd34F552cDe0b6b708eF5014; // VSP-ETH pair

    uint256 public constant MINIMUM_VOTING_POWER = 1e18;

    modifier onlyIfAddressIsValid(address wallet) {
        require(wallet != address(0), "holder-address-is-zero");
        _;
    }

    /// @notice Convert vVSP to VSP amount
    function _toVSP(uint256 _vvspAmount) internal view returns (uint256) {
        return (IVesperPool(vVSP).getPricePerShare() * _vvspAmount) / 1e18;
    }

    /// @notice Get VSP amount deposited in the vVSP pool
    function _inVSPPool(address _holder) internal view returns (uint256) {
        return _toVSP(IVesperPool(vVSP).balanceOf(_holder));
    }

    /// @notice Get underlying amount from cToken-Like (e.g. fToken, crToken, etc)
    function _depositedInCTokenLike(address _cTokenLike, address _holder) internal view returns (uint256) {
        ICToken cTokenLike = ICToken(_cTokenLike);
        uint256 _balance = ((cTokenLike.balanceOf(_holder) * cTokenLike.exchangeRateStored()) / 1e18);
        uint256 _borrowed = cTokenLike.borrowBalanceStored(_holder);
        if (_balance > _borrowed) {
            return _balance - _borrowed;
        } else {
            return 0;
        }
    }

    /// @notice Get the VSP amount converted from the RariFuse's fVSP and fVVSP pools
    function _inFusePools(address _holder) internal view returns (uint256) {
        uint256 _vspBalance = _depositedInCTokenLike(fVSP_23, _holder);
        uint256 _vvspBalance = _depositedInCTokenLike(fVVSP_23, _holder) + _depositedInCTokenLike(fVVSP_110, _holder);
        return _vspBalance + _toVSP(_vvspBalance);
    }

    /// @notice Get the amout of VSP tokens deposited in UniswapV2-Like pair pool
    function _inUniswapV2Like(address _pairAddress, address _holder) internal view returns (uint256) {
        IUniswapV2Pair _pair = IUniswapV2Pair(_pairAddress);
        require(_pair.token0() == VSP, "token0-is-not-vsp");
        uint256 staked = _pair.balanceOf(_holder);
        if (staked == 0) {
            return 0;
        }
        uint256 lpTotalSupply = _pair.totalSupply();
        (uint112 _reserve0, , ) = _pair.getReserves();

        return (_reserve0 * staked) / lpTotalSupply;
    }

    /// @notice Get the voting power for an account
    function balanceOf(address _holder) public view virtual onlyIfAddressIsValid(_holder) returns (uint256) {
        uint256 votingPower = IERC20(VSP).balanceOf(_holder) + // VSP
            _inVSPPool(_holder) + // vVSP
            _inFusePools(_holder) + // fTokens (fVSP and fVVSP)
            _inUniswapV2Like(uniswapV2, _holder) + // UniswapV2 VSP/ETH
            _inUniswapV2Like(sushiswap, _holder); // Sushiswap VSP/ETH

        return votingPower >= MINIMUM_VOTING_POWER ? votingPower : 0;
    }
}
