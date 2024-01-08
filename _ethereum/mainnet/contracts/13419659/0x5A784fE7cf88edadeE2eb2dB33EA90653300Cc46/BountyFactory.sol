// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Bounty.sol";
import "./IERC721VaultFactory.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./Clones.sol";

contract BountyFactory is ReentrancyGuard {
    event BountyDeployed(
        address indexed addressDeployed,
        address indexed creator,
        address nftContract,
        uint256 nftTokenID,
        string name,
        string symbol,
        uint256 contributionCap,
        bool indexed isPrivate
    );

    address public immutable logic;

    constructor(
        address _gov,
        IERC721VaultFactory _tokenVaultFactory,
        IERC721 _logicNftContract,
        uint256 _logicTokenID
    ) {
        Bounty _bounty = new Bounty(_gov, _tokenVaultFactory);
        // initialize as expired bounty
        _bounty.initialize(
            _logicNftContract,
            _logicTokenID,
            "BOUNTY",
            "BOUNTY",
            0, // contribution cap
            0 // duration (expired right away)
        );
        logic = address(_bounty);
    }

    function startBounty(
        IERC721 _nftContract,
        uint256 _nftTokenID,
        string memory _name,
        string memory _symbol,
        uint256 _contributionCap,
        uint256 _duration,
        bool _isPrivate
    ) external nonReentrant returns (address bountyAddress) {
        bountyAddress = Clones.clone(logic);
        Bounty(bountyAddress).initialize(
            _nftContract,
            _nftTokenID,
            _name,
            _symbol,
            _contributionCap,
            _duration
        );
        emit BountyDeployed(
            bountyAddress,
            msg.sender,
            address(_nftContract),
            _nftTokenID,
            _name,
            _symbol,
            _contributionCap,
            _isPrivate
        );
    }
}
