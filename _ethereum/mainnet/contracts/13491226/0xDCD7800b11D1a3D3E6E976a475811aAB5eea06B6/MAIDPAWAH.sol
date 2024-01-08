// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Enumerable.sol";
import "./ICloneNurses.sol";

interface INurseRaid {
    function powerOfMaids(IERC721Enumerable maids, uint256 id) external view returns (uint256);
}

contract MAIDPAWAH is Ownable {
    INurseRaid public constant raid = INurseRaid(0x629d37B273c05597C8bEfB7B48525803B202D9Ea);

    IERC20 public constant omu = IERC20(0xD428F1050AdC29976d4339b1ec602832034dF701);
    ICloneNurses public constant cloneNurses = ICloneNurses(0x5eE657F5426484A777a1fC7Abd436DfDB13b1cc3);
    IERC721Enumerable public constant maids = IERC721Enumerable(0x42ED30f2c459601A4f74Ff831B76Be64195D3dE4);
    IERC721Enumerable public constant sushiGirls = IERC721Enumerable(0xEB3b418e4A4430392Cd57b1356c5B1d2205A56d9);
    IERC721Enumerable public constant lingerieGirls = IERC721Enumerable(0x579a60Fbc649d3398F13E0385dBE79b3Ffad757c);

    IERC721Enumerable[] public housekeepers;

    uint256 public maidLikeWeight;
    uint256 public nurseWeight;
    uint256 public omuWeight;

    event AddHousekeepers(uint256 indexed id, IERC721Enumerable indexed newHousekeeper);
    event SetHousekeepers(uint256 indexed id, IERC721Enumerable indexed newHousekeeper);
    event SetWeight(uint256 maidLikeWeight, uint256 nurseWeight, uint256 omuWeight);

    constructor(
        uint256 _maidLikeWeight,
        uint256 _nurseWeight,
        uint256 _omuWeight
    ) {
        maidLikeWeight = _maidLikeWeight;
        nurseWeight = _nurseWeight;
        omuWeight = _omuWeight;
        emit SetWeight(_maidLikeWeight, _nurseWeight, _omuWeight);
    }

    function addHousekeeper(IERC721Enumerable newHousekeeper) external onlyOwner {
        uint256 id = housekeepers.length;
        housekeepers.push(newHousekeeper);
        emit AddHousekeepers(id, newHousekeeper);
    }

    function setHousekeeper(uint256 id, IERC721Enumerable newHousekeeper) external onlyOwner {
        housekeepers[id] = newHousekeeper;
        emit SetHousekeepers(id, newHousekeeper);
    }

    function setWeight(
        uint256 _maidLikeWeight,
        uint256 _nurseWeight,
        uint256 _omuWeight
    ) external onlyOwner {
        maidLikeWeight = _maidLikeWeight;
        nurseWeight = _nurseWeight;
        omuWeight = _omuWeight;
        emit SetWeight(_maidLikeWeight, _nurseWeight, _omuWeight);
    }

    function powerOfMaidLike(address account) internal view returns (uint256 totalPower) {
        uint256 sGirlsBalance = sushiGirls.balanceOf(account);
        if (sGirlsBalance > 0) {
            for (uint256 i = 0; i < sGirlsBalance; i++) {
                totalPower += raid.powerOfMaids(sushiGirls, sushiGirls.tokenOfOwnerByIndex(account, i));
            }
        }

        uint256 lGirlsBalance = lingerieGirls.balanceOf(account);
        if (lGirlsBalance > 0) {
            for (uint256 i = 0; i < lGirlsBalance; i++) {
                totalPower += raid.powerOfMaids(lingerieGirls, lingerieGirls.tokenOfOwnerByIndex(account, i));
            }
        }

        uint256 maidsBalance = maids.balanceOf(account);
        if (maidsBalance > 0) {
            for (uint256 i = 0; i < maidsBalance; i++) {
                totalPower += raid.powerOfMaids(maids, maids.tokenOfOwnerByIndex(account, i));
            }
        }

        uint256 keepers = housekeepers.length;
        if (keepers > 0) {
            for (uint256 i = 0; i < keepers; i++) {
                if (address(housekeepers[i]) != address(0)) {
                    uint256 keepersBalance = housekeepers[i].balanceOf(account);
                    if (keepersBalance > 0) {
                        for (uint256 j = 0; j < keepersBalance; j++) {
                            totalPower += raid.powerOfMaids(
                                housekeepers[i],
                                housekeepers[i].tokenOfOwnerByIndex(account, j)
                            );
                        }
                    }
                }
            }
        }
    }

    function powerOfNurses(address account) internal view returns (uint256 totalPower) {
        uint256 nursesBalance = cloneNurses.balanceOf(account);
        if (nursesBalance > 0) {
            for (uint256 i = 0; i < nursesBalance; i++) {
                uint256 id = cloneNurses.tokenOfOwnerByIndex(account, i);
                (uint256 _type, , ) = cloneNurses.nurses(id);
                (, , uint256 power, ) = cloneNurses.nurseTypes(_type);

                totalPower += (power + (cloneNurses.supportedPower(id) / 1e18));
            }
        }
    }

    function powerOfOMU(address account) internal view returns (uint256 omuPower) {
        omuPower = omu.balanceOf(account) / 1e18;
    }

    function balanceOf(address account) external view returns (uint256 balance) {
        balance += powerOfMaidLike(account) * maidLikeWeight;
        balance += powerOfNurses(account) * nurseWeight;
        balance += powerOfOMU(account) * omuWeight;
    }
}
