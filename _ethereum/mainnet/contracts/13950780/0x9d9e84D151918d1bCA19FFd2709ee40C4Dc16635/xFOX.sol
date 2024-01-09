// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IFoxRewardsIssuance.sol";
import "./IFoxLock.sol";


contract xFOX is ERC20, Ownable {

    IERC20  public foxToken;
    address public foxLock;
    address public foxRewardsIssuance;

    // --- Events ---
    event Enter(address account, uint256 foxAmountIn, uint256 xfoxAmountOut);
    event Leave(address account, uint256 xfoxAmountIn, uint256 foxAmountOut);

    // --- Modifier ---
    modifier initialized() {
        require(owner() == address(0), "xFOX: not initialized");
        _;
    }

    // --- Constructor ---
    constructor(address _foxToken) public ERC20("xFOX", "xFOX") {
        foxToken = IERC20(_foxToken);
    }

    // --- Functions ---
    function initialize(address _foxLock, address _foxRewardsIssuance) external onlyOwner {
        foxLock = _foxLock;
        foxRewardsIssuance = _foxRewardsIssuance;
        IFoxRewardsIssuance(_foxRewardsIssuance).initialize();
        renounceOwnership();
    }

    function exchangeRate() external view returns (uint256) {
        uint256 totalShare = totalSupply();
        if (totalShare == 0) {
            return 0;
        }

        (, uint256 unIssued) = IFoxRewardsIssuance(foxRewardsIssuance).calculateRewards();
        uint256 totalFox = foxToken.balanceOf(address(this)).add(unIssued);
        uint256 rate = totalFox.mul(1e18).div(totalShare);
        return rate;
    }

    function enter(address _account, uint256 _amount) external initialized {
        if (msg.sender != foxLock) {
            require(msg.sender == _account, "xFOX: need enter by yourself");
        }
        require(_amount > 0, "xFOX: need non-zero amount");

        uint256 totalShares = totalSupply();
        uint256 share = _amount;
        if (totalShares > 0) {
            IFoxRewardsIssuance(foxRewardsIssuance).issueRewards();

            uint256 totalFOX = foxToken.balanceOf(address(this));
            share = _amount.mul(totalShares).div(totalFOX);
        }

        _mint(_account, share);
        foxToken.transferFrom(msg.sender, address(this), _amount);

        emit Enter(_account, _amount, share);
    }

    function leave(uint256 _share) external {
        require(_share > 0, "xFOX: need non-zero share");

        IFoxRewardsIssuance(foxRewardsIssuance).issueRewards();

        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(foxToken.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, _share);

        foxToken.transfer(foxLock, what);
        IFoxLock(foxLock).lock(msg.sender, what);

        emit Leave(msg.sender, _share, what);
    }
}