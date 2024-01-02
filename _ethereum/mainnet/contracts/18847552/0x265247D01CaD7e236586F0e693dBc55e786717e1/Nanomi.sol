// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./TreasuryDeclaration.sol";

contract Nanomi is ERC20Capped, ERC20Burnable, Ownable {
    uint16 constant TOTAL_MONTHS = 60;
    uint16 ReleaseIndex = 0;
    uint256 constant MAX_SUPPLY = 199700000000;
    Treasury[TOTAL_MONTHS] Treasuries;

    uint[60] ReleaseDates = [
        1704182989,
        1707217489,
        1710165025,
        1712838461,
        1715609218,
        1717788247,
        1720513050,
        1723384289,
        1727003089,
        1728807489,
        1730459039,
        1734347089,
        1736450689,
        1738743489,
        1741772689,
        1743519089,
        1746386689,
        1749910089,
        1752414652,
        1755026661,
        1757502826,
        1760871547,
        1762370382,
        1765486049,
        1768810857,
        1769963858,
        1774178291,
        1777213089,
        1779265299,
        1781629489,
        1783508191,
        1786476100,
        1789493000,
        1791995257,
        1794681011,
        1797246528,
        1799070412,
        1801825474,
        1805138689,
        1807679011,
        1809285899,
        1812625498,
        1816762994,
        1819447089,
        1819826652,
        1822734871,
        1825336964,
        1827745272,
        1832061489,
        1834080187,
        1836301889,
        1839067058,
        1841670237,
        1843556658,
        1847543778,
        1848760014,
        1852362920,
        1855934628,
        1856968075,
        1859543591
    ];

    constructor() ERC20("Nanomi", "NANOMI") ERC20Capped(MAX_SUPPLY * 10 ** 18) {
        generateTreasuries();
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        require(
            ERC20.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    function generateTreasuries() private {
        uint40[5] memory amounts = [
            100000000000,
            50000000000,
            35000000000,
            12000000000,
            2700000000
        ];

        for (uint16 i = 0; i < TOTAL_MONTHS; i++) {
            Treasuries[i].releaseDate = ReleaseDates[i];
            Treasuries[i].releaseAmount = amounts[i / 12] / 12;
        }
    }

    function getUnlockDates()
        public
        view
        returns (uint256[TOTAL_MONTHS] memory)
    {
        uint256[TOTAL_MONTHS] memory unlockDates;
        for (uint16 i = 0; i < TOTAL_MONTHS; i++) {
            unlockDates[i] = Treasuries[i].releaseDate;
        }
        return unlockDates;
    }

    function getAllTreasuries()
        public
        view
        returns (Treasury[TOTAL_MONTHS] memory)
    {
        return Treasuries;
    }

    function getDebugInfo() public view returns (uint) {
        return ReleaseIndex;
    }

    function unlockTreasury() public onlyOwner returns (uint) {
        require(ReleaseIndex < TOTAL_MONTHS, "All treasuries unlocked.");
        if (
            Treasuries[ReleaseIndex].releaseDate <= block.timestamp &&
            !Treasuries[ReleaseIndex].isReleased
        ) {
            _mint(
                msg.sender,
                Treasuries[ReleaseIndex].releaseAmount * 10 ** 18
            );
            Treasuries[ReleaseIndex].isReleased = true;
            ReleaseIndex++;
        }
        return ReleaseIndex;
    }
}
