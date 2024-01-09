// SPDX-License-Identifier: Unlicense
// Developed by EasyChain (easychain.tech)
//
pragma solidity ^0.8.4;
import "./Ownable.sol";

abstract contract ERC721StagedSale is Ownable {

    uint256 public constant NO_STAGE = 9999;

    uint256 private totalSupply;

    struct StageData {
        uint256 total;
        uint256 minted;
        uint256 stagePercent;
        bool open;
    }

    mapping(uint256 => StageData) public stages;
    uint256 public stagesCount;

    constructor(uint256 _totalSupply) {
        require(_totalSupply > 0);

        totalSupply = _totalSupply;
    }

    function updateStagesData(
        uint256[] memory _totals,
        uint256[] memory _stagePercents
    ) public onlyOwner {
        require(_totals.length == _stagePercents.length, "Invalid stage parameters");
        require(_totals.length >= stagesCount, "Can not remove stage");

        uint256 total = 0;
        for (uint256 i = 0; i < _totals.length; i++) {
            total += _totals[i];      
        }
        
        require(total == totalSupply, "Invalid total is not equal to totalSupply");

        _disableAllStages();

        stagesCount = _totals.length;

        for (uint256 i = 0; i < _totals.length; i++) {
            _applyStage(i, _totals[i], _stagePercents[i]);
        }
    }

    function open(uint256 _num) public onlyOwner {
        require(_num < stagesCount, "Invalid stage number");
        require(stages[_num].total >= stages[_num].minted, "Stage is sold out");

        _disableAllStages();

        stages[_num].open = true;
    }

    function currentStage() public view returns (uint256) {
        for (uint256 i = 0; i < stagesCount; i++) {
            if (stages[i].open) {
                return i;
            }
        }
        return NO_STAGE;
    }

    function _mintStaged(
        uint256 _amount, 
        uint256 _pricePerToken,
        address _to
    ) internal returns (uint256) {
        uint256 stage = currentStage();
        require(stage != NO_STAGE, "No stage is opened");
        require(stages[stage].minted + _amount <= stages[stage].total, "Stage limit hit");
        
        stages[stage].minted += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            _internalMint(_to);
        }

        return _pricePerToken * stages[stage].stagePercent / 100;
    }

    function _disableAllStages() internal {
        for (uint256 i = 0; i < stagesCount; i++) {
            stages[i].open = false;
        }
    }

    function _applyStage(
        uint256 _num,
        uint256 _total,
        uint256 _stagePercent
    ) internal {
        require(stages[_num].minted <= _total, "Total less then minted");
        require(_stagePercent > 0, "Invalid zero stage percent");

        uint256 minted = stages[_num].minted;

        stages[_num] = StageData({
            total: _total,
            minted: minted,
            stagePercent: _stagePercent,
            open: false
        });
    }

    function _internalMint(address _to) internal virtual returns (uint256);
}