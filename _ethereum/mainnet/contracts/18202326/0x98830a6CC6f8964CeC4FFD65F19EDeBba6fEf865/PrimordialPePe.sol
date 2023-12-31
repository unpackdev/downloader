// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Math.sol";
import "./IERC721Enumerable.sol";
import "./EnumerableSet.sol";
import "./ERC20.sol";

/**
 * @title PrimordialPePe
 * @dev Contract to manage staking and rewards for Primordial PePe tokens.
 */
contract PrimordialPePe is ERC20Burnable, Ownable, AccessControl {

    struct StakedPlanet {
        uint256 tokenId;
        uint256 stakedSince;
        uint256 primordialEmission;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters;
    EnumerableSet.AddressSet private admins;

    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public constant STAKE_LIMIT = 25;

    bool public minable = false;
    address public allowed_pepe_miner;
    address public allowed_pond_miner;
    uint256 public max_rig_supply = 420690000000000000000000000000000;

    address public primordialplanetsAddress;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    //User to staked planets
    mapping(address => EnumerableSet.UintSet) private stakedPlanets;
    //Staked Planet to timestamp staked
    mapping(uint256 => uint256) public planetStakeTimes;
    mapping(uint256 => uint256) public planetClaimTimes;

   constructor() ERC20("PrimordialPePe", "PPEPE") {

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        minters.add(msg.sender);
        admins.add(msg.sender);
    }

    /**
     * @notice Stake specified planet IDs.
     * @param _planetIds The planet IDs to stake.
     */
    function stakePlanetByIds(uint256[] memory _planetIds) external {
        require(
            _planetIds.length + stakedPlanets[msg.sender].length() <= STAKE_LIMIT,
            "Can only have a max of 25 planets staked in your solar system!"
        );
        for (uint256 i = 0; i < _planetIds.length; i++) {
            _stakePlanet(_planetIds[i]);
        }
    }

    function unstakePlanetByIds(uint256[] memory _planetIds) public {
        for (uint256 i = 0; i < _planetIds.length; i++) {
            _unstakePlanet(_planetIds[i]);
        }
    }

    function claimRewardsByIds(uint256[] memory _planetIds) external {
        uint256 runningPePeAllowance;

        for (uint256 i = 0; i < _planetIds.length; i++) {
            uint256 thisPlanetId = _planetIds[i];
            require(
                stakedPlanets[msg.sender].contains(thisPlanetId),
                "Can only claim from a planet in your solar system!"
            );
            runningPePeAllowance += getPrimordialOwedToThisPlanet(thisPlanetId);

            planetClaimTimes[thisPlanetId] = block.timestamp;
        }
        _mint(msg.sender, runningPePeAllowance);
    }

    function claimAllRewards() external {
        uint256 runningPePeAllowance;

        for (uint256 i = 0; i < stakedPlanets[msg.sender].length(); i++) {
            uint256 thisPlanetId = stakedPlanets[msg.sender].at(i);
            runningPePeAllowance += getPrimordialOwedToThisPlanet(thisPlanetId);

            planetClaimTimes[thisPlanetId] = block.timestamp;
        }
        _mint(msg.sender, runningPePeAllowance);
    }

    function unstakeAll() external {
        unstakePlanetByIds(stakedPlanets[msg.sender].values());
    }

    function _stakePlanet(uint256 _planetId) internal onlyPlanetOwner(_planetId) {
        //Transfer their token
        IERC721Enumerable(primordialplanetsAddress).transferFrom(
            msg.sender,
            address(this),
            _planetId
        );

        // Add the planet to the owner's solar system
        stakedPlanets[msg.sender].add(_planetId);

        //Set this planetId timestamp to now
        planetStakeTimes[_planetId] = block.timestamp;
        planetClaimTimes[_planetId] = 0;
    }

    function _unstakePlanet(uint256 _planetId)
        internal
        onlyPlanetStaker(_planetId)
    {
        uint256 primordialOwedToThisPlanet = getPrimordialOwedToThisPlanet(_planetId);
        _mint(msg.sender, primordialOwedToThisPlanet);

        IERC721(primordialplanetsAddress).transferFrom(
            address(this),
            msg.sender,
            _planetId
        );

        stakedPlanets[msg.sender].remove(_planetId);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "PrimordialPePe: must have minter role to mint");
        _mint(to, amount);
    }

    // GETTERS

    function getStakedPlanetData(address _address)
        external
        view
        returns (StakedPlanet[] memory)
    {
        uint256[] memory ids = stakedPlanets[_address].values();
        StakedPlanet[] memory stakedPlanet = new StakedPlanet[](ids.length);
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 _planetId = ids[index];
            stakedPlanet[index] = StakedPlanet(
                _planetId,
                planetStakeTimes[_planetId],
                getPlanetPrimordialEmission(_planetId)
            );
        }

        return stakedPlanet;
    }

    function tokensStaked(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return stakedPlanets[_address].values();
    }

    function stakedPlanetQuantity(address _address)
        external
        view
        returns (uint256)
    {
        return stakedPlanets[_address].length();
    }

    function getPrimordialOwedToThisPlanet(uint256 _planetId)
        public
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp - planetStakeTimes[_planetId];
        uint256 elapsedDays = elapsedTime < 1 days ? 0 : elapsedTime / 1 days;
        uint256 leftoverSeconds = elapsedTime - elapsedDays * 1 days;

        if (planetClaimTimes[_planetId] == 0) {
            return _calculatePrimordial(elapsedDays, leftoverSeconds);
        }

        uint256 elapsedTimeSinceClaim = planetClaimTimes[_planetId] -
            planetStakeTimes[_planetId];
        uint256 elapsedDaysSinceClaim = elapsedTimeSinceClaim < 1 days
            ? 0
            : elapsedTimeSinceClaim / 1 days;
        uint256 leftoverSecondsSinceClaim = elapsedTimeSinceClaim -
            elapsedDaysSinceClaim *
            1 days;

        return
            _calculatePrimordial(elapsedDays, leftoverSeconds) -
            _calculatePrimordial(elapsedDaysSinceClaim, leftoverSecondsSinceClaim);
    }

    function getTotalRewardsForUser(address _address)
        external
        view
        returns (uint256)
    {
        uint256 runningPrimordialTotal;
        uint256[] memory planetIds = stakedPlanets[_address].values();
        for (uint256 i = 0; i < planetIds.length; i++) {
            runningPrimordialTotal += getPrimordialOwedToThisPlanet(planetIds[i]);
        }
        return runningPrimordialTotal;
    }

    function getPlanetPrimordialEmission(uint256 _planetId)
        public
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp - planetStakeTimes[_planetId];
        uint256 elapsedDays = elapsedTime < 1 days ? 0 : elapsedTime / 1 days;
        return _primordialDailyIncrement(elapsedDays);
    }

    function getMinterCount() public view returns (uint256) {
        return minters.length();
    }

    function getMinter(uint256 index) public view returns (address) {
        require(index < minters.length(), "Index out of range");
        return minters.at(index);
    }

    function getAdminCount() public view returns (uint256) {
        return admins.length();
    }

    function getAdmin(uint256 index) public view returns (address) {
        require(index < admins.length(), "Index out of range");
        return admins.at(index);
    }

    function _calculatePrimordial(uint256 _days, uint256 _leftoverSeconds)
        internal
        pure
        returns (uint256)
    {
        uint256 progressiveDays = Math.min(_days, 100);
        uint256 progressiveReward = progressiveDays == 0
            ? 0
            : (progressiveDays *
                (2525 ether + 25 ether * (progressiveDays - 1) + 2525 ether)) /
                2;

        uint256 dailyIncrement = _primordialDailyIncrement(_days);
        uint256 leftoverReward = _leftoverSeconds > 0
            ? (dailyIncrement * _leftoverSeconds) / 1 days
            : 0;

        if (_days <= 100) {
            return progressiveReward + leftoverReward;
        }
        return progressiveReward + (_days - 100) * 5000 ether + leftoverReward;
    }

    function _primordialDailyIncrement(uint256 _days)
        internal
        pure
        returns (uint256)
    {
        return _days > 100 ? 5000 ether : 2500 ether + _days * 25 ether;
    }

    // ACCESS CONTROL FUNCTIONS

    function grantAdminRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PrimordialPePe: must have admin role to grant new admin");
        grantRole(DEFAULT_ADMIN_ROLE, account);
        admins.add(account);
    }

    function revokeAdminRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PrimordialPePe: must have admin role to revoke admin");
        revokeRole(DEFAULT_ADMIN_ROLE, account);
        admins.remove(account);
    }

    function grantMinterRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PrimordialPePe: must have admin role to grant minter role");
        grantRole(MINTER_ROLE, account);
        minters.add(account);
    }

    function revokeMinterRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PrimordialPePe: must have admin role to revoke minter role");
        revokeRole(MINTER_ROLE, account);
        minters.remove(account);
    }

    // MINING RIG

    function activate() external payable {
        require(allowed_pepe_miner == address(0) || allowed_pond_miner == address(0), "Miners activated");
        require(msg.sender != allowed_pepe_miner, "Miner already activated");
        require(minable == false, "INVALID");

        uint256 mintAmount = 1000000 ether;

        if (allowed_pepe_miner == address(0)) {
            allowed_pepe_miner = msg.sender;
            _mint(allowed_pepe_miner, mintAmount);
        } else {
            allowed_pond_miner = msg.sender;
            _mint(allowed_pond_miner, mintAmount);
            minable = true; 
        }
    }

    function mintSupplyFromMinedLP(
        address miner,
        uint256 value
    ) external payable {
        require(minable == true, "INVALID");
        require(msg.sender == allowed_pepe_miner || msg.sender == allowed_pond_miner, "INVALID");

        uint _supply = totalSupply();
        uint _calculated = _supply + value;

        require(_calculated <= max_rig_supply, "EXCEEDS MAX");
        _mint(miner, value);
    }

    // OWNER FUNCTIONS

    function setAddresses(address _primordialplanetsAddress)
        public
        onlyOwner
    {
        primordialplanetsAddress = _primordialplanetsAddress;
    }

    // MODIFIERS

    modifier onlyPlanetOwner(uint256 _planetId) {
        require(
            IERC721Enumerable(primordialplanetsAddress).ownerOf(_planetId) == msg.sender,
            "Can only stake planets in your domain!"
        );
        _;
    }

    modifier onlyPlanetStaker(uint256 _planetId) {
        require(
            stakedPlanets[msg.sender].contains(_planetId),
            "Can only unstake planets in your solar system!"
        );
        _;
    }
}