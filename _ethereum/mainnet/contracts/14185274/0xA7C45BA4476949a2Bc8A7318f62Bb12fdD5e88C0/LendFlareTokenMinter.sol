// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

interface ILiquidityGauge {
    function updateReward(address _for) external;

    function totalAccrued(address _for) external view returns (uint256);
}

interface ILendFlareToken {
    function mint(address _for, uint256 amount) external;
}

contract LendFlareTokenMinter is ReentrancyGuard {
    using SafeMath for uint256;

    address public token;
    address public supplyPoolExtraRewardFactory;
    uint256 public launchTime;

    mapping(address => mapping(address => uint256)) public minted; // user -> gauge -> value

    event Minted(address user, address gauge, uint256 amount);

    constructor(
        address _token,
        address _supplyPoolExtraRewardFactory,
        uint256 _launchTime
    ) public {
        require(_launchTime > block.timestamp, "!_launchTime");
        launchTime = _launchTime;
        token = _token;
        supplyPoolExtraRewardFactory = _supplyPoolExtraRewardFactory;
    }

    function _mintFor(address gauge_addr, address _for) internal {
        if (block.timestamp >= launchTime) {
            ILiquidityGauge(gauge_addr).updateReward(_for);

            uint256 total_mint = ILiquidityGauge(gauge_addr).totalAccrued(_for);
            uint256 to_mint = total_mint.sub(minted[_for][gauge_addr]);

            if (to_mint > 0) {
                ILendFlareToken(token).mint(_for, to_mint);
                minted[_for][gauge_addr] = total_mint;

                emit Minted(_for, gauge_addr, total_mint);
            }
        }
    }

    function mintFor(address gauge_addr, address _for) public nonReentrant {
        require(
            msg.sender == supplyPoolExtraRewardFactory,
            "LendFlareTokenMinter: !authorized mintFor"
        );

        _mintFor(gauge_addr, _for);
    }
}
