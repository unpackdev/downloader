// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./ERC20.sol";

contract ChilliToken is ERC20 {
    uint256 public constant multiplier = (10**18);

    uint256 public lastDevRelease;
    uint256 public lastTeamRelease;

    address team;
    address dev;

    uint256 public releaseStartDate;

    uint256 totalDevMinted;
    uint256 totalTeamMinted;

    constructor(
        address _development,
        address _team,
        address _uniswap,
        address _farming,
        address _airdrops,
        address _bounties
    ) ERC20("Chilli Token", "CHLI") {
        _mint(_uniswap, 120_000_000 * multiplier);
        _mint(_farming, 75_000_000 * multiplier);
        _mint(_airdrops, 7_500_000 * multiplier);
        _mint(_bounties, 7_500_000 * multiplier);

        team = _team;
        dev = _development;

        releaseStartDate = 1627776000;
    }

    function devRelease() public {
        if (lastDevRelease == 0) {
            require(
                releaseStartDate <= block.timestamp,
                "token: release not started"
            );
            _mint(dev, 7_500_000 * multiplier);
            lastDevRelease = releaseStartDate;
            totalDevMinted += 7_500_000;
        } else {
            require(
                totalDevMinted <= 60_000_001 * multiplier,
                "token: let the quarter over"
            );
            require(
                block.timestamp >= lastDevRelease + 7776000,
                "token: let the quarter over"
            );
            _mint(dev, 7_500_000 * multiplier);
            lastDevRelease = lastDevRelease + 7776000;
            totalDevMinted += 7_500_000;
        }
    }

    function teamRelease() public {
        if (lastTeamRelease == 0) {
            require(
                releaseStartDate <= block.timestamp,
                "token: release not started"
            );
            _mint(dev, 3_750_000 * multiplier);
            lastTeamRelease = releaseStartDate;
            totalTeamMinted += 3_750_000;
        } else {
            require(
                totalTeamMinted <= 30_000_001 * multiplier,
                "token: let the quarter over"
            );
            require(
                block.timestamp >= lastTeamRelease + 7776000,
                "token: let the quarter over"
            );
            _mint(team, 3_750_000 * multiplier);
            lastTeamRelease = lastTeamRelease + 7776000;
            totalTeamMinted += 3_750_000;
        }
    }
}
