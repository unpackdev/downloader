// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./IMasterChefV3.sol";

contract FarmBooster {
    IMasterChefV3 public immutable MasterChefV3;

    /// @notice Basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;

    /// @notice Checks if the msg.sender is the MasterChef V3.
    modifier onlyMasterChefV3() {
        require(msg.sender == address(MasterChefV3), "Not MasterChef V3");
        _;
    }

    /// @param _masterChefV3 The MasterChefV3 contract address.
    constructor(IMasterChefV3 _masterChefV3) {
        MasterChefV3 = _masterChefV3;
    }

    function getUserMultiplier(uint256 _tokenId) external pure returns (uint256) {
        return BOOST_PRECISION;
    }

    function updatePositionBoostMultiplier(uint256 _tokenId) external onlyMasterChefV3 returns (uint256 _multiplier) {
        (, uint128 boostLiquidity, , , , , , , uint256 boostMultiplier) = MasterChefV3.userPositionInfos(_tokenId);
        if (boostLiquidity == 0 && boostMultiplier > 0) {
            revert();
        }
        _multiplier = BOOST_PRECISION;
    }

    function removeBoostMultiplier(address _user, uint256 _tokenId, uint256 _pid) external {}
}
