//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./IRewardsPool.sol";
import "./Boardroom.sol";

/// Boardroom distributes token emission among shareholders that stake Klon and lock Klon in lpPool
contract UniswapBoardroom is Boardroom {
    /// Address of lpPool
    IRewardsPool public lpPool;

    /// Creates new Boardroom
    /// @param _stakingToken address of the base token
    /// @param _tokenManager address of the TokenManager
    /// @param _emissionManager address of the EmissionManager
    /// @param _start start of the boardroom date
    constructor(
        address _stakingToken,
        address _tokenManager,
        address _emissionManager,
        uint256 _start
    )
        public
        Boardroom(_stakingToken, _tokenManager, _emissionManager, _start)
    {}

    /// Update lpPool
    /// @param _lpPool new lp pool
    function setLpPool(address _lpPool) public onlyOwner {
        lpPool = IRewardsPool(_lpPool);
        emit LpPoolChanged(msg.sender, _lpPool);
    }

    /// Shows the balance of the virtual token that participates in reward calculation
    /// @param owner the owner of the share tokens
    function shareTokenBalance(address owner)
        public
        view
        override
        returns (uint256)
    {
        return stakingTokenBalances[owner].add(lpPool.balanceOf(owner));
    }

    /// Shows the supply of the virtual token that participates in reward calculation
    function shareTokenSupply() public view override returns (uint256) {
        return stakingTokenSupply.add(lpPool.totalSupply());
    }

    event LpPoolChanged(address indexed operator, address newLpPool);
}
