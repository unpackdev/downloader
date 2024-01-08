// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./ERC20.sol";

contract KokoToken is ERC20 {
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
        address _stratigic_sale,
        address _ido,
        address _launchpads,
        address _staking,
        address _com_growth,
        address _partnership
        ) ERC20("Kokoswap Token", "KOKO") {
        _mint(_stratigic_sale, 33_000_000 * (10 ** 18));
        _mint(_ido, 49_500_000 * (10 ** 18));
        _mint(_launchpads, 59_400_000 * (10 ** 18));
        _mint(_staking, 79_200_000 * (10 ** 18));
        _mint(_com_growth, 16_500_000 * (10 ** 18));
        _mint(_partnership, 9_900_000 * (10 ** 18));

        team = _team;
        dev = _development;

        releaseStartDate = 1625169972;
    }

    function devRelease() public {
        if (lastDevRelease == 0) {
            require(
                releaseStartDate <= block.timestamp,
                "token: release not started"
            );
            _mint(dev, 4_125_000 * multiplier);
            lastDevRelease = releaseStartDate;
            totalDevMinted += 4_125_000;
        } else {
            require(
                totalDevMinted <= 33_000_001 * multiplier,
                "token: let the quarter over"
            );
            require(
                block.timestamp >= lastDevRelease + 7776000,
                "token: let the quarter over"
            );
            _mint(dev, 4_125_000 * multiplier);
            lastDevRelease = lastDevRelease + 7776000;
            totalDevMinted += 4_125_000;
        }
    }

    function teamRelease() public {
        if (lastTeamRelease == 0) {
            require(
                releaseStartDate <= block.timestamp,
                "token: release not started"
            );
            _mint(dev, 6_187_500 * multiplier);
            lastTeamRelease = releaseStartDate;
            totalTeamMinted += 6_187_500;
        } else {
            require(
                totalTeamMinted <= 49_500_001 * multiplier,
                "token: let the quarter over"
            );
            require(
                block.timestamp >= lastTeamRelease + 7776000,
                "token: let the quarter over"
            );
            _mint(team, 6_187_500 * multiplier);
            lastTeamRelease = lastTeamRelease + 7776000;
            totalTeamMinted += 6_187_500;
        }
    }
}
