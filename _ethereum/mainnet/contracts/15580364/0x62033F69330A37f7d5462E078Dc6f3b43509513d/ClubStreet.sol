// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./DancerQueue.sol";

interface ICustomRules {
    function isAllowedJoin(address _account, uint256 _targetClubNum, bytes memory _condition) external view returns(bool, string memory);
    function isAllowedBounty(address _account, uint256 _targetClubNum) external view returns(bool, string memory);
}


interface IPartyHeatPointCenter {
    function claim(address _account, uint256 _targetClubNum, string memory actionType) external;
}


interface IClubStreet {
    function getBountyForBatch(address _account, IERC20 _token, uint256 _index, uint256 _targetClubNum) external;
}


contract ClubStreet is Ownable {
    using DancerQueue for DancerQueue.DancerDeque;
    
    enum BountyType { AVERAGE, RANDOM }

    struct ClubInfo {
        bool isInOperation;
        IERC20 feeToken;
        uint256 feeAmount;
        uint256 bountyFeeRatio;
        uint256 interval;
        uint256 maxDancers;
        string metadata;
        ICustomRules customRules;
        IPartyHeatPointCenter partyHeatPointCenter;
        DancerQueue.DancerDeque dancers;
        mapping(address => uint256) dancerMap;
        mapping(IERC20 => bool) transferWhitelist;
    }

    struct BountyDatas{
        uint256 totalAmount;
        uint256 bountyNum;
        mapping(uint256 => BountyData) bountyMap;
    }

    struct BountyData{
        uint256 totalAmount;
        uint256 totalNumber;
        uint256 remainNumber;
        uint256 remainAmount;
        uint256 starttime;
        uint256 duration;
        BountyType bountyType;
        mapping(address => uint256) userMap;
    }

    address public feeTo;
    address public bountyFeeTo;
    uint256 public clubNum;
    uint256 public bountyLifeCycle;

    mapping(uint256 => ClubInfo) private clubs;
    mapping(uint256 => mapping(IERC20 => BountyDatas)) private bounties;
    
    event NewFeeTo(address oldAddr, address newAddr);
    event NewBountyFeeTo(address oldAddr, address newAddr);
    event NewBountyLifeCycle(uint256 oldBountyLifeCycle, uint256 newBountyLifeCycle);
    event NewMetadata(string newMetadata, uint256 targetClubNum);
    event NewTransferWhitelist(address token, bool status, uint256 targetClubNum);
    event NewCustomRules(address customRules, uint256 targetClubNum);
    event NewPartyHeatPointCenter(address partyHeatPointCenter, uint256 targetClubNum);
    event NewClubInfo(
        uint256 targetClubNum, 
        IERC20 feeToken, 
        uint256 bountyFeeRatio, 
        uint256 feeAmount, 
        uint256 interval, 
        uint256 maxDancer, 
        bool isOperation
    );
    event OpenClub(uint256 amount, uint256 clubNum);
    event Join(address account, uint256 timestamp, uint256 targetClubNum);
    event SendBounty(
        address token, 
        uint256 amount, 
        uint256 number,
        BountyType bountyType, 
        uint256 starttime,
        uint256 duration,
        uint256 bountyFee, 
        uint256 index, 
        uint256 targetClubNum
    );
    event GetBounty(address token, address account, uint256 amount, uint256 targetClubNum, uint256 index);
    event GetBackExpiredFund(address token, address account, uint256 amount, uint256 targetClubNum);
    event GetBountyFailure(uint256 index, bytes error);

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ClubStreet: Must use EOA");
        _;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        address oldFeeTo = feeTo;
        feeTo = _feeTo;
        emit NewFeeTo(oldFeeTo, _feeTo);
    }

    function setBountyFeeTo(address _bountyFeeTo) public onlyOwner {
        address oldBountyFeeTo = bountyFeeTo;
        bountyFeeTo = _bountyFeeTo;
        emit NewBountyFeeTo(oldBountyFeeTo, _bountyFeeTo);
    }

    function setBountyLifeCycle(uint256 _bountyLifeCycle) public onlyOwner {
        require(_bountyLifeCycle > 0, "ClubStreet: Not Allow Zero");
        uint256 oldBountyLifeCycle = bountyLifeCycle;
        bountyLifeCycle = _bountyLifeCycle;
        emit NewBountyLifeCycle(oldBountyLifeCycle, _bountyLifeCycle);
    }

    function changeClubInfo(
        uint256 _targetClubNum,
        IERC20 _feeToken,
        uint256 _bountyFeeRatio,
        uint256 _feeAmount,
        uint256 _interval,
        uint256 _maxDancers,
        bool _isInOperation
    ) 
        public 
        onlyOwner 
    {
        clubs[_targetClubNum].feeToken = _feeToken;
        clubs[_targetClubNum].bountyFeeRatio = _bountyFeeRatio;
        clubs[_targetClubNum].feeAmount = _feeAmount;
        clubs[_targetClubNum].interval = _interval;
        clubs[_targetClubNum].maxDancers = _maxDancers;
        clubs[_targetClubNum].isInOperation = _isInOperation;
        emit NewClubInfo(_targetClubNum, _feeToken, _bountyFeeRatio, _feeAmount, _interval, _maxDancers, _isInOperation);
    }

    function setNewMetadata(string[] memory _metadatas, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _metadatas.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            clubs[_targetClubNums[i]].metadata = _metadatas[i];
            emit NewMetadata(_metadatas[i], _targetClubNums[i]);
        }
    }

    function setTransferWhitelist(IERC20[][] memory _tokens, bool[][] memory _alloweds, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            for (uint256 j; j < _tokens[i].length; j++) {
                clubs[_targetClubNums[i]].transferWhitelist[_tokens[i][j]] = _alloweds[i][j];
                emit NewTransferWhitelist(address(_tokens[i][j]), _alloweds[i][j], _targetClubNums[i]);
            }
        }
    }

    function setCustomRules(ICustomRules[] memory _customRules, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _customRules.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            clubs[_targetClubNums[i]].customRules = _customRules[i];
            emit NewCustomRules(address(_customRules[i]), _targetClubNums[i]);
        }
    }

    function setPartyHeatPointCenter(IPartyHeatPointCenter[] memory _partyHeatPointCenters, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _partyHeatPointCenters.length; i++) {
            // require(clubs[_targetClubNums[i]].isInOperation, "ClubStreet: Not in operation");
            clubs[_targetClubNums[i]].partyHeatPointCenter = _partyHeatPointCenters[i];
            emit NewPartyHeatPointCenter(address(_partyHeatPointCenters[i]), _targetClubNums[i]);
        }
    }

    function openClubs(
        string[] memory _metadatas,
        IERC20[] memory _feeTokens,
        uint256[] memory _feeAmounts,
        uint256[] memory _bountyFeeRatios,
        uint256[] memory _intervals,
        uint256[] memory _maxDancers,
        ICustomRules[] memory _customRules,
        IPartyHeatPointCenter[] memory _partyHeatPointCenter
    ) 
        external 
        onlyOwner 
    {
        for (uint256 i; i < _feeTokens.length; i++) {
            ClubInfo storage club = clubs[clubNum++];
            club.isInOperation = true;
            club.metadata = _metadatas[i];
            club.feeToken = _feeTokens[i];
            club.feeAmount = _feeAmounts[i];
            club.bountyFeeRatio = _bountyFeeRatios[i];
            club.interval = _intervals[i];
            club.maxDancers = _maxDancers[i];
            club.customRules = _customRules[i];
            club.partyHeatPointCenter = _partyHeatPointCenter[i];
        }
        emit OpenClub(_feeTokens.length, clubNum);
    }

    function join(uint256 _targetClubNum, bytes memory _conditions) external onlyEOA {
        _join(msg.sender, _targetClubNum, _conditions);
    }

    function sendBounty(
        IERC20 _token, 
        uint256 _amount, 
        uint256 _number, 
        BountyType _bountyType,
        uint256 _starttime, 
        uint256 _duration, 
        uint256 _targetClubNum
    )
        external 
        onlyEOA 
    {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        require(targetClub.isInOperation, "ClubStreet: Not in operation");

        uint256 nowTime = block.timestamp;
        uint256 _bountyFee;

        if (msg.sender == owner()) {
            _token.transferFrom(msg.sender, address(this), _amount);
            
        } else {
            if (targetClub.customRules != ICustomRules(address(0))) {
                (bool _isAllowed, string memory _desc) = targetClub.customRules.isAllowedBounty(msg.sender, _targetClubNum);
                require(_isAllowed, _desc);
            }

            uint256 startTime = targetClub.dancerMap[msg.sender];
            require(startTime > 0 && nowTime < startTime + targetClub.interval, "ClubStreet: Not in the club");
            require(targetClub.transferWhitelist[_token], "ClubStreet: Not in the whitelist");

            _token.transferFrom(msg.sender, address(this), _amount);
            
            if (targetClub.bountyFeeRatio > 0 && bountyFeeTo != address(0)) {
                _bountyFee = _amount * targetClub.bountyFeeRatio / 1e18;
                _token.transfer(bountyFeeTo, _bountyFee);
            }
        }

        uint256 _finalAmount = _amount - _bountyFee;
        BountyDatas storage last = bounties[_targetClubNum][_token];
        last.totalAmount += _finalAmount;

        BountyData storage newBounty = last.bountyMap[last.bountyNum];
        newBounty.totalAmount = _finalAmount;
        newBounty.totalNumber = _number;
        newBounty.remainNumber = _number;
        newBounty.remainAmount = _finalAmount;
        newBounty.bountyType = _bountyType;
        newBounty.starttime = _starttime > nowTime ? _starttime : nowTime;
        newBounty.duration = _duration;

        last.bountyNum++;

        if (targetClub.partyHeatPointCenter != IPartyHeatPointCenter(address(0)) && msg.sender != owner()) {
           targetClub.partyHeatPointCenter.claim(msg.sender, _targetClubNum, "sendBounty");
        }

        emit SendBounty(
            address(_token), 
            _finalAmount, 
            _number,
            _bountyType,
            _starttime,
            _duration, 
            _bountyFee, 
            last.bountyNum, 
            _targetClubNum
        );
    }

    function getBounty(IERC20 _token, uint256 _index, uint256 _targetClubNum) external onlyEOA {
        _getBounty(msg.sender, _token, _index, _targetClubNum);
    }

    function getBountyForBatch(address _account, IERC20 _token, uint256 _index, uint256 _targetClubNum) external {
        require(msg.sender == address(this), "ClubStreet: Must be address(this)");
        _getBounty(_account, _token, _index, _targetClubNum);
    }

    function batchGetBounty(IERC20[] memory _tokens, uint256[] memory _indexs, uint256[] memory _targetClubNums) public onlyEOA {
        for (uint256 i; i < _tokens.length; i++) {
            try IClubStreet(address(this)).getBountyForBatch(msg.sender, _tokens[i], _indexs[i], _targetClubNums[i]) {
                // success
            }
            catch Error(string memory reason) {
                // catch failing revert() and require()
                emit GetBountyFailure(i, bytes(reason));
            } catch (bytes memory reason) {
                // catch failing assert()
                emit GetBountyFailure(i, reason);
            }
        }
    }

    function getBackExpiredFund(IERC20 _token, uint256 _index, uint256 _targetClubNum) public onlyOwner {
        BountyDatas storage last = bounties[_targetClubNum][_token];
        BountyData storage bounty = last.bountyMap[_index];
        if (bounty.duration != 0) {
            require(block.timestamp - bounty.starttime > bounty.duration, "ClubStreet: Not Expired");
        } else {
            require(block.timestamp - bounty.starttime > bountyLifeCycle, "ClubStreet: Not Expired");
        }
        
        uint256 _reward = last.bountyMap[_index].remainAmount;
        last.bountyMap[_index].remainAmount = 0;

        _token.transfer(bountyFeeTo, _reward);
        emit GetBackExpiredFund(address(_token), bountyFeeTo, _reward, _targetClubNum);
    }

    function getBackExpiredFunds(IERC20[] memory _tokens, uint256[] memory _indexs, uint256[] memory _targetClubNums) public onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            getBackExpiredFund(_tokens[i], _indexs[i], _targetClubNums[i]);
        }
    }

    function _join(address _account, uint256 _targetClubNum, bytes memory _conditions) internal {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        require(targetClub.isInOperation, "ClubStreet: Not in operation");
        uint256 nowTime = block.timestamp;
        if (targetClub.dancers.length() == targetClub.maxDancers) {
            uint256 joinTime = targetClub.dancers.front().joinTime;
            require(nowTime - joinTime > targetClub.interval, "ClubStreet: The club is full");
            targetClub.dancers.popFront();
        }

        require(nowTime - targetClub.dancerMap[_account] > targetClub.interval, "ClubStreet: Already in the club");

        if (targetClub.customRules != ICustomRules(address(0))) {
           (bool _isAllowed, string memory _desc) = targetClub.customRules.isAllowedJoin(_account, _targetClubNum, _conditions);
           require(_isAllowed, _desc);
        }

        if (targetClub.feeAmount > 0 && feeTo != address(0)) {
            targetClub.feeToken.transferFrom(_account, feeTo, targetClub.feeAmount);
        }

        targetClub.dancerMap[_account] = nowTime;
        targetClub.dancers.pushBack(DancerQueue.Dancer(_account, nowTime));

        if (targetClub.partyHeatPointCenter != IPartyHeatPointCenter(address(0))) {
           targetClub.partyHeatPointCenter.claim(_account, _targetClubNum, "join");
        }

        emit Join(_account, nowTime, _targetClubNum);
    }

    function _getBounty(address _account, IERC20 _token, uint256 _index, uint256 _targetClubNum) internal {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        require(targetClub.isInOperation, "ClubStreet: Not in operation");

        if (targetClub.customRules != ICustomRules(address(0))) {
            (bool _isAllowed, string memory _desc) = targetClub.customRules.isAllowedBounty(_account, _targetClubNum);
            require(_isAllowed, _desc);
        }

        uint256 nowTime = block.timestamp;
        uint256 startTime = targetClub.dancerMap[_account];
        require(startTime > 0 && nowTime < startTime + targetClub.interval, "ClubStreet: Not in the club");

        BountyDatas storage last = bounties[_targetClubNum][_token];
        require(last.bountyMap[_index].remainNumber > 0, "ClubStreet: Not Init or Finished");

        require(last.bountyMap[_index].userMap[_account] == 0, "ClubStreet: Already Claimed");

        require(nowTime >= last.bountyMap[_index].starttime, "ClubStreet: Not Start");

        require(last.bountyMap[_index].duration == 0 || nowTime < last.bountyMap[_index].starttime + last.bountyMap[_index].duration, "ClubStreet: Expired");

        uint256 _reward;
        if (last.bountyMap[_index].bountyType == BountyType.AVERAGE) {
            if (last.bountyMap[_index].remainNumber == 1) {
                _reward = last.bountyMap[_index].remainAmount;
            } else {
                _reward = last.bountyMap[_index].totalAmount / last.bountyMap[_index].totalNumber;
            }
        } else {
            if (last.bountyMap[_index].remainNumber == 1) {
                _reward = last.bountyMap[_index].remainAmount;
            } else {
                while (_reward == 0) {
                    _reward = uint256(keccak256(abi.encodePacked(_index, _account, block.difficulty, block.timestamp))) %
                            (2 * last.bountyMap[_index].remainAmount / last.bountyMap[_index].remainNumber);
                }
            }
        }

        last.bountyMap[_index].remainAmount -= _reward;
        last.bountyMap[_index].userMap[_account] = _reward;
        last.bountyMap[_index].remainNumber--;

        _token.transfer(_account, _reward);

        if (targetClub.partyHeatPointCenter != IPartyHeatPointCenter(address(0))) {
           targetClub.partyHeatPointCenter.claim(_account, _targetClubNum, "getBounty");
        }

        emit GetBounty(address(_token), _account, _reward, _targetClubNum, _index);
    }
    
    function getInClubDancer(uint256 _targetClubNum) external view returns(address[] memory) {
        ClubInfo storage targetClub = clubs[_targetClubNum];
        uint256 index;
        uint256 nowTime = block.timestamp;
        for(uint256 i; i < targetClub.dancers.length(); i++) {
            uint256 joinTime = targetClub.dancers.at(i).joinTime;
            if (nowTime - joinTime < targetClub.interval) {
                break;
            }
            index++;
        }
        uint256 amount = targetClub.dancers.length() - index;
        address[] memory inClubDancerList = new address[](amount);

        for(uint256 i; i < amount; i++) {
            inClubDancerList[i] = targetClub.dancers.at(index+i).addr;
        }
        return inClubDancerList;
    }

    function getClubInfo(uint256 _targetClubNum) 
        external 
        view 
        returns(
            bool isInOperation,
            IERC20 feeToken,
            uint256 feeAmout,
            uint256 bountyFeeRatio,
            uint256 interval,
            uint256 maxDancers,
            string memory metadata,
            ICustomRules customRules
        ) 
    {

        ClubInfo storage targetClub = clubs[_targetClubNum];
        isInOperation = targetClub.isInOperation;
        feeToken = targetClub.feeToken;
        feeAmout = targetClub.feeAmount;
        bountyFeeRatio = targetClub.bountyFeeRatio ;
        interval = targetClub.interval;
        maxDancers = targetClub.maxDancers;
        customRules = targetClub.customRules;
        metadata = targetClub.metadata;
    }
}