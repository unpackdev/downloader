// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.21;

interface ISimpleFarm {

    function setRewardRate(
        uint256 newRate
    )
        external;

    function rewardToken()
        external
        view
        returns (IERC20);

    function rewardDuration()
        external
        view
        returns (uint256);
}

interface IERC20 {

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool);

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);
}

contract SimpleManager {

    address public owner;
    address public worker;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "SimpleManager: NOT_OWNER"
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == worker,
            "SimpleManager: NOT_WORKER"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        worker = msg.sender;
    }

    function changeWorker(
        address _newWorker
    )
        external
        onlyOwner
    {
        worker = _newWorker;
    }

    uint256 public latestRate;
    address public latestTarget;

    function manageRate(
        address _targetFarms,
        uint256 _newRates
    )
        external
        onlyWorker
    {
        latestRate = _newRates;
        latestTarget = _targetFarms;
    }

    function manageRates(
        address[] calldata _targetFarms,
        uint256[] calldata _newRates
    )
        external
        onlyWorker
    {
    }

    function recoverToken(
        IERC20 tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        tokenAddress.transfer(
            owner,
            tokenAmount
        );
    }
}
