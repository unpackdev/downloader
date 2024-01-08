pragma solidity 0.7.6;

import "./IERC20Metadata.sol";
import "./ILiquidityMining.sol";

//import "./console.sol";

contract ProxyActionsLiquidityMining {

    /// @notice Direct liquidity mining method deposit
    function deposit(
        address _liquidityMining,
        address _token,
        uint256 _tokenAmount
    ) external {

        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);
        require(liquidityMining.isTokenAdded(_token), "TOKEN_NOT_ADDED");

        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _tokenAmount),
            "TOKEN_IN"
        );

        IERC20(_token).approve(_liquidityMining, _tokenAmount);

        uint256 pid = liquidityMining.poolPidByAddress(_token);
        liquidityMining.deposit(pid, _tokenAmount);
    }

    /// @notice Direct liquidity mining method withdraw
    function withdraw(
        address _liquidityMining,
        address _token,
        uint256 _tokenAmount
    ) external {

        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);
        require(liquidityMining.isTokenAdded(_token), "TOKEN_NOT_ADDED");

        uint256 pid = liquidityMining.poolPidByAddress(_token);
        liquidityMining.withdraw(pid, _tokenAmount);

        uint tokenBalance = IERC20(_token).balanceOf(address(this));
        if(tokenBalance > 0) {
            require(
                IERC20(_token).transfer(msg.sender, tokenBalance),
                "TOKEN_OUT"
            );
        }
    }

    /// @notice Direct liquidity mining method claim
    function claim(
        address _liquidityMining
    ) external {

        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);
        liquidityMining.claim();

        uint rewardClaimedBalance = IERC20(liquidityMining.rewardToken()).balanceOf(address(this));
        if(rewardClaimedBalance > 0) {
            require(
                IERC20(liquidityMining.rewardToken()).transfer(msg.sender, rewardClaimedBalance),
                "REWARD_OUT"
            );
        }
    }
}
