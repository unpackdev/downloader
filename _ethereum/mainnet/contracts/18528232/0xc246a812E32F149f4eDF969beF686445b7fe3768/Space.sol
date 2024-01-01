pragma solidity ^0.8.21;

import "./ISpace.sol";
import "./Planet.sol";
import "./AccPlanetData.sol";
import "./PlanetPrediction.sol";
import "./IERC20.sol";

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

contract Space is ISpace, Ownable {
    using PlanetPrediction for Planet;

    address public immutable dev;

    uint256 public minPlanetRewardPercent = 50; // 100%=1000
    uint256 public maxPlanetRewardPercent = 500; // 100%=1000
    uint8 constant _startPlanetsCount = 2;
    uint8 public constant maxPlanetsCount = 4; // maximum planets count
    uint256 public constant newPlanetTimeMin = 1 minutes;
    uint256 public constant newPlanetTimeMax = 1 hours;
    uint256 public planetDestructionTimeMin = 60 seconds;
    uint256 public planetDestructionTimeMax = 600 seconds;
    uint256 public planetPeriodWaitTimerMin = 60 seconds; // planet period wait time interval min
    uint256 public planetPeriodWaitTimerMax = 36000 seconds; // planet period wait time interval max
    uint256 public planetClaimResourcesTimerMin = 60 seconds; // planet claim time interval min
    uint256 public planetClaimResourcesTimerMax = 3600 seconds; // planet claim time interval max
    uint256 public destructionStartProb = 30; // noe of this is starts destruction on claim
    IERC20 public erc20;
    IERC20 public erc202;
    uint256 public totalCreatedPlanets; // total created planets count
    bool public isStarted;

    uint256 _devFeePercent = 40; // dev fee percent
    address _deployer;
    uint256 internal _nonce = 1;
    Planet[maxPlanetsCount] _planets; // accounts planet data
    mapping(address => AccPlanetData[maxPlanetsCount]) accs;
    uint256 _newPlanetTime;

    constructor(address dev_) {
        _deployer = msg.sender;
        dev = dev_;
    }

    function start() external onlyOwner {
        require(!isStarted, "already started");
        isStarted = true;
        for (uint8 i = 1; i <= _startPlanetsCount; ++i) _createPlanet(i);
    }

    function setPeriodWaitTimer(
        uint256 planetPeriodWaitTimerMin_,
        uint256 planetPeriodWaitTimerMax_
    ) external onlyOwner {
        require(
            planetPeriodWaitTimerMin_ > 0 &&
                planetPeriodWaitTimerMin_ <= planetPeriodWaitTimerMax_,
            "not correct"
        );
        planetPeriodWaitTimerMin = planetPeriodWaitTimerMin_;
        planetPeriodWaitTimerMax = planetPeriodWaitTimerMax_;
    }

    function setClaimResourcesTimer(
        uint256 planetClaimResourcesTimerMin_,
        uint256 planetClaimResourcesTimerMax_
    ) external onlyOwner {
        require(
            planetClaimResourcesTimerMin_ > 0 &&
                planetClaimResourcesTimerMin_ <= planetClaimResourcesTimerMax_,
            "not correct"
        );
        planetClaimResourcesTimerMin = planetClaimResourcesTimerMin_;
        planetClaimResourcesTimerMax = planetClaimResourcesTimerMax_;
    }

    function setRewardPercent(uint256 min, uint256 max) external onlyOwner {
        require(min <= max, "not correct");
        require(max <= 1000, "not correct");
        minPlanetRewardPercent = min;
        maxPlanetRewardPercent = max;
    }

    function setDestructionStartProb(uint256 prob) external onlyOwner {
        require(prob > 1);
        destructionStartProb = prob;
    }

    function setErc20(address erc20_, address erc202_) external {
        require(msg.sender == _deployer);
        delete _deployer;
        erc20 = IERC20(erc20_);
        erc202 = IERC20(erc202_);
    }

    receive() external payable {
        uint256 devFee = (msg.value * _devFeePercent) / 100;
        (bool sentFee, ) = payable(dev).call{value: devFee}("");
        require(sentFee, "sent fee error: dev ether is not sent");
    }

    function devFeePercent() external view returns (uint256) {
        return _devFeePercent;
    }

    function setDevFeePercent(uint256 percent) external onlyOwner {
        require(percent <= 50);
        _devFeePercent = percent;
    }

    function goToPlanet(uint256 planetId, uint256 tokensCount) external {
        // limitations
        require(isStarted, "not started");
        // get planet
        (Planet storage planet, uint8 number) = _getPlanetByIdInternal(
            planetId
        );
        require(planet.isExists(), "planet is not exists");
        // update planet
        //_updateBeforeUsePlanet(planet, number);
        _destroyPlanet(planet, number);
        _updatePlanet(planet, number);
        require(planet.isExists(), "planet is not exists");

        // thansfer stak tokens
        uint256 lastTokens = erc20.balanceOf(address(this));
        erc20.transferFrom(msg.sender, address(this), tokensCount);
        uint256 staked = erc20.balanceOf(address(this)) - lastTokens;

        // write data
        AccPlanetData storage acc = accs[msg.sender][number - 1];
        if (acc.planetId != planet.id) ++planet.accountsCount;
        acc.planetId = planet.id;
        acc.claimPeriod = planet.periodNumber();
        acc.tokenStaked += staked;
        planet.tokenStaked += staked;
    }

    function leavePlanet(uint256 planetId) external {
        (Planet storage planet, uint8 number) = _getPlanetByIdInternal(
            planetId
        );
        _updateBeforeUsePlanet(planet, number);
        AccPlanetData storage acc = accs[msg.sender][number - 1];
        require(acc.planetId > 0, "address slot for planet not found");
        //if (_canClaimRewards(acc, planet))
        //    _claimRewards(msg.sender, acc, planet);
        erc20.transfer(msg.sender, acc.tokenStaked);
        --planet.accountsCount;
        planet.tokenStaked -= acc.tokenStaked;
        delete accs[msg.sender][number - 1];
    }

    function _updateBeforeUsePlanet(
        Planet storage planet,
        uint8 number
    ) private {
        require(planet.isExists(), "the planet is not exists");
        _executePlanetsDestructions();
        _updatePlanet(planet, number);
        _executeNewPlanets();
        require(planet.isExists(), "the planet is not exisits");
    }

    function getAccSlots(
        address addr
    ) external view returns (AccPlanetData[] memory) {
        AccPlanetData[] memory res = new AccPlanetData[](maxPlanetsCount);
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            AccPlanetData storage data = accs[addr][i];
            Planet memory planet = _planets[i];
            if (!planet.isExists()) continue;
            res[i] = data;
        }

        return res;
    }

    function getAccSlotForPlanet(
        address acc,
        uint256 planetId
    ) public view returns (AccPlanetData memory) {
        return _getAccSlotForPlanet(acc, planetId);
    }

    function _getAccSlotForPlanet(
        address acc,
        uint256 planetId
    ) private view returns (AccPlanetData storage) {
        require(planetId > 0, "planet with id=0 is not exists");
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            AccPlanetData storage data = accs[acc][i];
            if (data.planetId == planetId) {
                require(
                    isPlanetExists(data.planetId),
                    "address slot for planet not found"
                );
                return data;
            }
        }

        revert("address slot for planet not found");
    }

    function _trySetDestructionTime(Planet storage planet) private {
        if (!planet.isExists() || planet.destroyTime != 0) return;
        if (_rand(1, destructionStartProb) % destructionStartProb != 1) return;

        planet.setDestroyTimer(
            _rand(planetDestructionTimeMin, planetDestructionTimeMax)
        );
    }

    function isPlanetClaimInterval(
        uint8 planetNumber
    ) public view returns (bool) {
        return _isPlanetClaimInterval(_getPlanetByNumber(planetNumber));
    }

    function _isPlanetClaimInterval(
        Planet memory planet
    ) private view returns (bool) {
        return planet.id > 0 && planet.isClaimTime();
    }

    /*function claimRewardsAllPlanets() external {
        uint8 claimCount;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            AccPlanetData storage data = accs[msg.sender][i];
            Planet storage planet = _planets[i];
            if (!planet.isExists()) continue;
            _updatePlanet(planet, i + 1);
            if (!_canClaimRewards(data, planet)) continue;
            _claimRewards(msg.sender, data, planet);
            ++claimCount;
        }
        _executeNewPlanets();
        require(claimCount > 0, "can not claim rewards yet");
    }*/

    function claimRewards(uint256 planetId) external {
        (Planet storage planet, uint8 number) = _getPlanetByIdInternal(
            planetId
        );
        _updateBeforeUsePlanet(planet, number);
        AccPlanetData storage data = accs[msg.sender][number - 1];
        require(_canClaimRewards(data, planet), "can not claim rewards yet");
        _claimRewards(msg.sender, data, planet);
    }

    function _canClaimRewards(
        AccPlanetData memory acc,
        Planet memory planet
    ) private view returns (bool) {
        return
            planet.isExists() &&
            planet.isClaimTime() &&
            acc.claimPeriod + 1 < planet.periodNumber();
    }

    function _claimRewards(
        address addr,
        AccPlanetData storage acc,
        Planet storage planet
    )
        private
        returns (
            uint256 ethRewarded,
            uint256 tokenRewarded,
            uint256 token2Rewarded
        )
    {
        _tryNextClaimPeriodSnapshot(planet);

        ethRewarded = planet.ethRewardPeriod(acc.tokenStaked);
        tokenRewarded = planet.tokenRewardPeriod(acc.tokenStaked);
        token2Rewarded = planet.token2RewardPeriod(acc.tokenStaked);

        acc.claimPeriod = planet.periodNumber() - 1;

        if (ethRewarded > 0) {
            (bool sentFee, ) = payable(addr).call{value: ethRewarded}("");
            require(sentFee, "sent fee error: ether is not sent");
            planet.eth -= ethRewarded;
        }
        if (tokenRewarded > 0) {
            erc20.transfer(addr, tokenRewarded);
            planet.token -= tokenRewarded;
        }
        if (token2Rewarded > 0) {
            erc202.transfer(addr, token2Rewarded);
            planet.token2 -= token2Rewarded;
        }

        _trySetDestructionTime(planet);
    }

    function _tryNextClaimPeriodSnapshot(Planet storage planet) private {
        if (
            !planet.isExists() ||
            planet.destroyTime != 0 ||
            !planet.isClaimPeriodDirty()
        ) return;
        _addRewardsToPlanet(planet);
        planet.tokenStakedSnapshot = planet.tokenStaked;
        planet.claimPeriodSnapshot = planet.periodNumber();
        planet.ethSnapshot = planet.eth;
        planet.tokenSnapshot = planet.token;
        planet.token2Snapshot = planet.token2;
    }

    function getRewardForTokens(
        uint256 planetId,
        uint256 tokensCount
    ) external view returns (uint256 eth, uint256 token, uint256 token2) {
        (Planet storage planet, ) = _getPlanetByIdInternal(planetId);
        eth = planet.ethRewardForTokens(tokensCount);
        token = planet.tokenRewardForTokens(tokensCount);
        token2 = planet.token2RewardForTokens(tokensCount);
    }

    function getRewardForAccount(
        uint256 planetId,
        address account
    ) external view returns (uint256 eth, uint256 token, uint256 token2) {
        (Planet storage planet, uint8 number) = _getPlanetByIdInternal(
            planetId
        );
        AccPlanetData memory acc = accs[account][number - 1];
        if (acc.claimPeriod == planet.periodNumber()) {
            return (0, 0, 0);
        }
        eth = planet.ethRewardPeriod(acc.tokenStaked);
        token = planet.tokenRewardPeriod(acc.tokenStaked);
        token2 = planet.token2RewardPeriod(acc.tokenStaked);
    }

    function _getPlanetNumber(
        AccPlanetData memory acc
    ) private view returns (uint8) {
        if (acc.planetId == 0) return 0;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            if (_planets[i].id == acc.planetId) return i + 1;
        }
        return 0;
    }

    function getPlanetByNumber(
        uint8 number
    ) external view returns (Planet memory) {
        return _getPlanetByNumber(number);
    }

    function _getPlanetByNumber(
        uint8 number
    ) private view returns (Planet storage) {
        require(
            number >= 1 && number <= maxPlanetsCount,
            "incorrect planet number"
        );
        return _planets[number - 1];
    }

    function getPlanetNumberById(uint256 id) public view returns (uint8) {
        if (id == 0) return 0;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            if (_planets[i].id == id) return i + 1;
        }
        return 0;
    }

    function isPlanetExists(uint256 id) public view returns (bool) {
        return _getPlanetById(id).isExists();
    }

    function getPlanetById(uint256 id) external view returns (Planet memory) {
        return _getPlanetById(id);
    }

    function _getPlanetByIdInternal(
        uint256 id
    ) private view returns (Planet storage planet, uint8 number) {
        number = getPlanetNumberById(id);
        require(number > 0, "has no planet with certain id");
        planet = _planets[number - 1];
    }

    function _getPlanetById(
        uint256 id
    ) internal view returns (Planet storage planet) {
        (planet, ) = _getPlanetByIdInternal(id);
    }

    function getPlanetClaimPeriod(
        uint256 planetId
    ) external view returns (uint256) {
        return _getPlanetById(planetId).periodNumber();
    }

    function tokenStacked() public view returns (uint256) {
        uint256 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            if (!_planets[i].isExists()) continue;
            res += _planets[i].tokenStaked;
        }
        return res;
    }

    function token2Total() public view returns (uint256) {
        return erc202.balanceOf(address(this));
    }

    function ethOnPlanets() public view returns (uint256) {
        uint256 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            res += _planets[i].ethOnPlanet();
        }
        return res;
    }

    function tokenOnPlanets() public view returns (uint256) {
        uint256 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            res += _planets[i].tokenOnPeriod();
        }
        return res;
    }

    function tokenOnPlanetsRewardWithStacks() public view returns (uint256) {
        uint256 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            res += _planets[i].token + _planets[i].tokenStaked;
        }
        return res;
    }

    function token2OnPlanets() public view returns (uint256) {
        uint256 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            res += _planets[i].token2OnPlanet();
        }
        return res;
    }

    function accountsOnPlanets() public view returns (uint256) {
        uint256 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            res += _planets[i].accountsCount;
        }
        return res;
    }

    function planetsCount() public view returns (uint8) {
        uint8 res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            if (_planets[i].id > 0) ++res;
        }
        return res;
    }

    function _getEmptyPlanetNumber() internal view returns (uint8) {
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            if (_planets[i].id == 0) return i + 1;
        }
        return 0;
    }

    function _rand() internal virtual returns (uint256) {
        //return _nonce++ * block.timestamp * block.number;
        return _nonce++ * block.number;
    }

    function _rand(uint256 min, uint256 max) private returns (uint256) {
        return min + (_rand() % (max - min + 1));
    }

    function ethRewardsCount() public view returns (uint256) {
        return address(this).balance - ethOnPlanets();
    }

    function tokenRewardsCount() public view returns (uint256) {
        return
            erc20.balanceOf(address(this)) - tokenOnPlanetsRewardWithStacks();
    }

    function token2RewardsCount() public view returns (uint256) {
        return token2Total() - token2OnPlanets();
    }

    function _generatePlanetEth() private returns (uint256) {
        return
            (ethRewardsCount() *
                _rand(minPlanetRewardPercent, maxPlanetRewardPercent)) / 1000;
    }

    function _generatePlanetToken() private returns (uint256) {
        return
            (tokenRewardsCount() *
                _rand(minPlanetRewardPercent, maxPlanetRewardPercent)) / 1000;
    }

    function _generatePlanetToken2() private returns (uint256) {
        return
            (token2RewardsCount() *
                _rand(minPlanetRewardPercent, maxPlanetRewardPercent)) / 1000;
    }

    function _addRewardsToPlanet(Planet storage planet) private {
        planet.eth += _generatePlanetEth();
        planet.token += _generatePlanetToken();
        planet.token2 += _generatePlanetToken2();
    }

    function getPlanets()
        external
        view
        returns (PlanetData[maxPlanetsCount] memory)
    {
        PlanetData[maxPlanetsCount] memory res;
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            if (!_planets[i].isExists()) continue;
            res[i] = _planets[i].getData(i + 1);
        }
        return res;
    }

    function getPlanetData(
        uint256 planetId
    ) external view returns (PlanetData memory) {
        (Planet storage planet, uint8 number) = _getPlanetByIdInternal(
            planetId
        );
        return planet.getData(number);
    }

    function _createPlanet(uint8 number) private {
        Planet storage planet = _getPlanetByNumber(number);
        planet.id = ++totalCreatedPlanets;
        uint256 periodClaim = _rand(
            planetClaimResourcesTimerMin,
            planetClaimResourcesTimerMax
        );
        uint256 periodWait = _rand(
            planetPeriodWaitTimerMin,
            planetPeriodWaitTimerMax
        );
        planet.periodTimer = periodClaim + periodWait;
        planet.claimResourcesTimer = periodClaim;
        planet.creationTime = block.timestamp;
        _addRewardsToPlanet(planet);
        _newPlanetTime =
            block.timestamp +
            _rand(newPlanetTimeMin, newPlanetTimeMax);
    }

    function _isNeedDestroyPlanet(
        Planet memory planet
    ) private view returns (bool) {
        return planet.id > 0 && !planet.isExists();
    }

    function executeNewPlanets() external {
        _executeNewPlanets();
    }

    function _executeNewPlanets() private {
        // time limit
        if (block.timestamp < _newPlanetTime) return;
        // getting new planet number
        uint8 newPlanetNumber = _getEmptyPlanetNumber();
        if (newPlanetNumber == 0) return;
        // creating the new planet
        _createPlanet(newPlanetNumber);
    }

    function updatePlanet(uint8 number) external {
        _updatePlanet(_getPlanetByNumber(number), number);
        _executeNewPlanets();
    }

    function _updatePlanet(Planet storage planet, uint8 number) private {
        if (_destroyPlanet(planet, number)) return;
        _tryNextClaimPeriodSnapshot(planet);
    }

    function _executePlanetsDestructions() private {
        for (uint8 i = 1; i <= maxPlanetsCount; ++i) {
            _destroyPlanet(_planets[i - 1], i);
        }
    }

    function _destroyPlanet(
        Planet storage planet,
        uint8 number
    ) private returns (bool) {
        require(
            number >= 1 && number <= maxPlanetsCount,
            "incorrect planet number"
        );
        if (!_isNeedDestroyPlanet(planet)) return false;
        uint256 tokenToBurn = planet.token + planet.tokenStaked;
        if (tokenToBurn > 0) erc20.transfer(address(0), tokenToBurn);
        delete _planets[number - 1];
        return true;
    }

    function _executePlanetsClaimPeriods() private {
        for (uint8 i = 0; i < maxPlanetsCount; ++i) {
            _tryNextClaimPeriodSnapshot(_planets[i]);
        }
    }

    function executePlanets() external {
        _executePlanetsDestructions();
        _executePlanetsClaimPeriods();
        _executeNewPlanets();
    }
}
