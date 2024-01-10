// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

interface IPool {
    function queueNewRewards(uint _rewards) external;

    function withdrawToken(address[] calldata tokens) external;

    function claimCrv(address receiver) external;
}

interface IcvxCrvDepositor {
    function deposit(uint amount) external;

    function getRewardFromConvex(address[] calldata tokens, address[] calldata receivers) external;
}

contract RewardDistributor is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public cvx;
    IERC20 public crv;
    IERC20 public triCrv;

    address public multiSig;

    IPool public cCRVLpPool;
    IPool public cvxLpPool;

    IPool public cCRVPool;
    IPool public cvxPool;

    IcvxCrvDepositor public cxvCrvDepositor;

    event RewardDistributed(address indexed operator, uint crvToLp, uint cvxToLp, uint crvToSingle, uint cvxToSingle, bool claim);

    constructor() initializer {}

    function initialize(
        IERC20 _crv,
        IERC20 _cvx,
        IERC20 _triCrv,
        IPool _cCRVLpPool,
        IPool _cvxLpPool,
        IPool _cCRVPool,
        IPool _cvxPool,
        IcvxCrvDepositor _depositor
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        crv = _crv;
        cvx = _cvx;
        triCrv = _triCrv;
        cCRVLpPool = _cCRVLpPool;
        cvxLpPool = _cvxLpPool;
        cCRVPool = _cCRVPool;
        cvxPool = _cvxPool;
        cxvCrvDepositor = _depositor;
    }

    function claimRewards() public {
        cCRVLpPool.claimCrv(address(this));
        address[] memory tokens = new address[](3);
        tokens[0] = address(cvx);
        tokens[1] = address(crv);
        tokens[2] = address(triCrv);

        address[] memory receivers = new address[](3);
        receivers[0] = address(this);
        receivers[1] = address(this);
        receivers[2] = owner();
        cxvCrvDepositor.getRewardFromConvex(tokens, receivers);
    }

    function distribute(uint crvToLp, uint cvxToLp, uint crvToSingle, uint cvxToSingle, bool claim) external onlyOwner {
        if (claim) {
            claimRewards();
        }

        crv.safeTransfer(address(cCRVLpPool), crvToLp);
        cCRVLpPool.queueNewRewards(crvToLp);

        cvx.safeTransfer(address(cvxLpPool), cvxToLp);
        cvxLpPool.queueNewRewards(cvxToLp);

        crv.safeTransfer(address(cCRVPool), crvToSingle);
        cCRVPool.queueNewRewards(crvToSingle);

        cvx.safeTransfer(address(cvxPool), cvxToSingle);
        cvxPool.queueNewRewards(cvxToSingle);

        emit RewardDistributed(msg.sender, crvToLp, cvxToLp, crvToSingle, cvxToSingle, claim);
    }

    function withdrawToken(address[] calldata tokens) external onlyOwner {
        for (uint i; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
        }
    }

    function withdrawTokenFromPool(address[] calldata tokens) external onlyOwner {
        cCRVPool.withdrawToken(tokens);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
    }
}
