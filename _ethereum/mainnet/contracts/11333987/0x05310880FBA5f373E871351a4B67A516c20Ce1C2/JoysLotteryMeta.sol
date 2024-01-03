// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Ownable.sol";


contract JoysLotteryMeta is Ownable {

    // events
    event LotteryMetaAdd(address indexed to, uint32 level,
        uint32 strengthMin, uint32 strengthMax,
        uint32 intelligenceMin, uint32 intelligenceMax,
        uint32 agilityMin, uint32 agilityMax,
        uint256 weight);

    event LotteryMetaUpdate(address indexed to, uint32 level,
        uint32 strengthMin, uint32 strengthMax,
        uint32 intelligenceMin, uint32 intelligenceMax,
        uint32 agilityMin, uint32 agilityMax,
        uint256 weight);

    // hero base info
    struct MetaInfo {
        // level
        uint32 level;

        // strength
        uint32 sMin;
        uint32 sMax;

        // intelligence
        uint32 iMin;
        uint32 iMax;

        // agility
        uint32 aMin;
        uint32 aMax;

        uint256 weight;
    }
    MetaInfo[] public metaInfo;
    mapping(uint32 => bool) public metaLevel;

    /**
     * @dev addMeta.
     * Requirements: only owner, when paused.
     * @notice add new meta info to contract
     * @param _level The meta level
     * @param _sMin The min strength value
     * @param _sMax The max strength value
     * @param _iMin The min intelligence value
     * @param _iMax The max intelligence value
     * @param _aMin The min agility value
     * @param _aMax The max agility value
     * @param _weight The meta weight
     */
    function addMeta (
        uint32 _level,
        uint32 _sMin,
        uint32 _sMax,
        uint32 _iMin,
        uint32 _iMax,
        uint32 _aMin,
        uint32 _aMax,
        uint256 _weight)
    onlyOwner public {
        require(_level > 0, "JoysLotteryMeta: The level starts at 1.");

        if (metaLevel[_level]) {
            return;
        }

        // new level must bigger than old
        if(metaInfo.length > 0) {
            require(_level > metaInfo[metaInfo.length - 1].level, "JoysLotteryMeta: new level must bigger than old");
            require(_level == metaInfo[metaInfo.length - 1].level + 1, "JoysLotteryMeta: new level must bigger.");
        }

        metaInfo.push(MetaInfo({
            level: _level,
            sMin: _sMin,
            sMax: _sMax,
            iMin: _iMin,
            iMax: _iMax,
            aMin: _aMin,
            aMax: _aMax,
            weight: _weight
            }));
        metaLevel[_level] = true;

        emit LotteryMetaAdd(_msgSender(), _level, _sMin, _sMax, _iMin, _iMax, _aMin, _aMax, _weight);
    }

    /**
     * @dev updateMeta.
     * Requirements: only owner, when paused.
     * @notice update special level meta info
     * @param _level The meta level
     * @param _sMin The min strength value
     * @param _sMax The max strength value
     * @param _iMin The min intelligence value
     * @param _iMax The max intelligence value
     * @param _aMin The min agility value
     * @param _aMax The max agility value
     * @param _weight The weight of the meta
     */
    function updateMeta (uint32 _level,
        uint32 _sMin,
        uint32 _sMax,
        uint32 _iMin,
        uint32 _iMax,
        uint32 _aMin,
        uint32 _aMax,
        uint256 _weight)
    onlyOwner public {
        require(_level > 0 && _level <= length(), "JoysLotteryMeta: invalid index.");

        for (uint32 idx = 0; idx < metaInfo.length; ++idx) {
            if (metaInfo[idx].level == _level) {
                metaInfo[idx] = MetaInfo({
                    level: _level,
                    sMin: _sMin,
                    sMax: _sMax,
                    iMin: _iMin,
                    iMax: _iMax,
                    aMin: _aMin,
                    aMax: _aMax,
                    weight: _weight
                    });
                break;
            }
        }

        emit LotteryMetaUpdate(_msgSender(), _level, _sMin, _sMax, _iMin, _iMax, _aMin, _aMax, _weight);
    }

    function length() public view returns (uint32) {
        return uint32(metaInfo.length);
    }

    function meta(uint256 _idx) public view returns (uint32, uint32, uint32, uint32, uint32, uint32, uint32, uint256){
        require(_idx < length(), "JoysLotteryMeta: invalid index.");
        MetaInfo storage m = metaInfo[_idx];
        return (m.level, m.sMin, m.sMax, m.iMin, m.iMax, m.aMin, m.aMax, m.weight);
    }
}

contract JoysHeroLotteryMeta is JoysLotteryMeta {
    constructor() public {
        addMeta(1, 500, 800, 400, 600, 500, 800, 10000);
        addMeta(2, 1500, 1800, 1000, 1200, 1500, 1800, 5000);
        addMeta(3, 4000, 6000, 4000, 6000, 2500, 3500, 2000);
        addMeta(4, 7000, 9000, 9000, 10000, 6000, 7000, 500);
        addMeta(5, 10000, 11000, 10000, 12000, 9000, 10000, 100);
        addMeta(6, 18000, 20000, 18000, 20000, 16000, 18000, 5);
    }
}

contract JoysWeaponLotteryMeta is JoysLotteryMeta {
    // init weapon lottery meta
    constructor() public {
        addMeta(1, 500, 700, 600, 800, 600, 800, 10000);
        addMeta(2, 1800, 2000, 1600, 1800, 2000, 2200, 4000);
        addMeta(3, 3000, 4000, 2500, 3500, 3000, 4000, 2000);
        addMeta(4, 6000, 8000, 8000, 9000, 6000, 7000, 500);
        addMeta(5, 16000, 18000, 16000, 18000, 18000, 20000, 0);
        addMeta(6, 18000, 20000, 16000, 18000, 16000, 18000, 0);
    }
}