// SPDX-FileCopyrightText: 2021 Tenderize <info@tenderize.me>

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IResolver.sol";
import "./ContextUpgradeable.sol";

import "./ITenderizer.sol";

abstract contract Resolver is IResolver, ContextUpgradeable {

    struct Protocol {
        string name;
        IERC20 steak;
        address stakingContract;
        uint256 depositInterval;
        uint256 depositThreshold;
        uint256 rebaseInterval;
        uint256 rebaseThreshold;
        uint256 lastClaim;
    }

    mapping(address => Protocol) protocols;
    address gov;

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    function initialize() external initializer {
        __Context_init_unchained();
        gov = msg.sender;
    }

    function _depositChecker(address _tenderizer)
        view
        internal
    returns (bool canExec){
        Protocol storage protocol = protocols[_tenderizer];

        if (protocol.lastClaim + protocol.depositInterval > block.timestamp) {
            return false;
        }

        uint256 tenderizerSteakBal = protocol.steak.balanceOf(_tenderizer);

        if (tenderizerSteakBal >= protocol.depositThreshold) {
            canExec = true;
        }
    }

    function rebaseChecker(address _tenderizer)
        external 
        override
        view
        virtual
    returns (bool canExec, bytes memory execPayload);

    function claimRewardsExecutor(address _tenderizer) external override {
        ITenderizer tenderizer = ITenderizer(_tenderizer);
        protocols[_tenderizer].lastClaim = block.timestamp;
        tenderizer.claimRewards();
    }
    
    // Governance functions
    function register(
        string memory _name,
        address _tenderizer,
        IERC20 _steak,
        address _stakingContract,
        uint256 _depositInterval,
        uint256 _depositThreshold,
        uint256 _rebaseInterval,
        uint256 _rebaseThreshold
    ) onlyGov external override {
        protocols[_tenderizer] = Protocol({
            name: _name,
            steak: _steak,
            stakingContract: _stakingContract,
            depositInterval: _depositInterval,
            depositThreshold: _depositThreshold,
            rebaseInterval: _rebaseInterval,
            rebaseThreshold: _rebaseThreshold,
            lastClaim: block.timestamp - _rebaseInterval // initialize checkpoint
        });
    }

    function setGov(address _gov) onlyGov external override {
        gov = _gov;
    }
}
