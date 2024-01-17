// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./ABDKMath64x64.sol";
import "./Calculate.sol";

/// @title Claim and minting contract for vvddrr.
/// @author Osman Ali.
/// @notice Claim, mint and earn vvddrr with a maximum of 21,000,000.
contract Token is ERC20, ERC20Burnable, Ownable {
    using Math for uint256;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    /// @notice A boolean used to allow only one setting of the ffxxdd controller.
    bool public setFfxxddController;

    /// @notice A boolean used to allow only one setting of the genesisTimestamp.
    bool public setGenesisOnce;

    /// @notice A boolean used to allow only one setting of the mmccrr controller.
    bool public setMmccrrController;

    /// @notice A boolean used to allow only one setting of the vvrrbb controller.
    bool public setVvrrbbController;

    /// @notice A public value used to store the current number of active minters.
    uint256 public activeMinters;

    /// @notice A count of the number of vvddrr claims made.
    /// @dev claimCount will always be below MAX_CLAIMS.
    uint256 public claimCount;

    /// @notice The amount of vvddrr tokens created up to the current time.
    /// @dev Includes both minted and burned vvddrr.
    uint256 public currentCreated;

    /// @notice The amount of vvddrr created through cRank mint claims up to the current time.
    /// @dev Includes both minted and burned vvddrr.
    uint256 public currentClaimCreated;

    /// @notice The timestamp initially set after contract creation used as the basis for duration calculations.
    uint256 public genesisTimestamp;

    /// @notice A value used to indicate the ranking of each user relative to all other cRank users.
    /// @dev This is initially set to the GENESIS_RANK to initialy the globalRank count.
    uint256 public globalRank = GENESIS_RANK;

    /// @notice A general constant for use in percentage basis point conversion and calculation.
    uint256 public constant BASIS = 10_000;

    /// @notice A specific numerical value used to remove basic point adjustments in cRank reward calculations.
    uint256 public constant BASIS_DEMNOMINATOR = 1_000_000_000;

    /// @notice The base amout that is rewarded for each completed cRank claim and mint.
    /// @dev Value is 0.3805175038 ETH.
    uint256 public constant CLAIM_REWARD_BASE = 380517503800000000;

    /// @notice The initial percentage in basis point used to calculate Early Adopter Amplification rewards.
    uint256 public constant EAA_PM_START_BASIS = 11_000;

    /// @notice The initial value in basis points by which the Early Adopter Amplification is reduced.
    uint256 public constant EAA_PM_STEP_BASIS = 10;

    /// @notice The constant by a percentage of which the Early Adopter Amplification is modified.
    /// @dev Setting the value to 2,600,000 results in deacrease every 300,000.
    uint256 public constant EAA_RANK_STEP = 2_600_000;

    /// @notice A constant setting the initial genesis rank for the first cRank.
    uint256 public constant GENESIS_RANK = 1;

    /// @notice The maximum number of cRank claims available + 1.
    uint256 public constant MAX_CLAIMS = 2_628_001;

    /// @notice The maximum amount of vvddrr that can be created.
    /// @dev This differs from the current totalSupply as it includes all burned tokens.
    uint256 public constant MAX_CREATED = 21000000000000000000000000; // 21_000_000 ETH

    /// @notice The maximum duration up to which a minting term can be extended.
    uint256 public constant MAX_TERM_END = 1_000 * SECONDS_IN_DAY;

    /// @notice The initial starting term set for the first set of cRank claims.
    uint256 public constant MAX_TERM_START = 100 * SECONDS_IN_DAY;

    // @notice A constant used to calculate the minimum value a minting term should be above.
    uint256 public constant MIN_TERM = 1 * SECONDS_IN_DAY - 1;

    /// @notice Constant setting the seconds in a day.
    uint256 public constant SECONDS_IN_DAY = 3_600 * 24;

    /// @notice The initial value by which a term duration if amlified to increase rewards.
    uint256 public constant TERM_AMPLIFIER = 15;

    /// @notice The number of cRank users after which the term amplifier threshold begins to take effect.
    uint256 public constant TERM_AMPLIFIER_THRESHOLD = 5_000;

    /// @notice The MintInfo struct stores the values needed to calculate a claim value.
    struct MintInfo {
        address user;
        uint256 term;
        uint256 claimMaxTerm;
        uint256 maturityTimestamp;
        uint256 rank;
        uint256 eaaRate;
    }

    /// @notice An address is used to indicate inclusion in a set of controller values.
    /// @dev Controllers allow external mining rig contracts to mint and burn vvddrr.
    mapping(address => bool) controllers;

    /// @notice An address is used a key to each struct of information for a given user mint.
    mapping(address => MintInfo) public userMints; // Used to avoid duplicates

    /// @notice Emitted when a rank is claimed.
    event RankClaimed(address indexed user, uint256 term, uint256 maxTerm, uint256 rank, uint256 eaaRate);

    /// @notice Detailed event emitted when a mint is claimed.
    event MintClaimed(address indexed user, uint256 rewardAmount, uint256 rankPercentage, uint256 termPercentage, uint256 eaaRate, uint256 basisReward);

    /// @notice Create the vvddrr ERC20 contract.
    constructor() ERC20("vvddrr", "VVDDRR") {}

    /// @notice A claim rank resulting in a cRank assignment and available mint claim.
    /// @param term The term for which a user will wait to claim their reward.
    function claimRank_66u(uint256 term) external {
        uint256 _claimCount = claimCount;
        uint256 _activeMinters = activeMinters;
        uint256 _globalRank = globalRank;
        require(_claimCount < MAX_CLAIMS, "Max claims reached");
        uint256 termSeconds = term * SECONDS_IN_DAY;
        uint256 maxTermDays = _calculateMaxTerm() / SECONDS_IN_DAY;
        require(termSeconds > MIN_TERM, "CRank: Term less than minimum");
        require(termSeconds < _calculateMaxTerm() + 1, "CRank: Term more than current max term");
        require(userMints[_msgSender()].rank == 0, "CRank: Mint already in progress");

        // Create and store new MintInfo
        MintInfo memory mintInfo = MintInfo({
            user: _msgSender(),
            term: termSeconds,
            claimMaxTerm: _calculateMaxTerm(),
            maturityTimestamp: block.timestamp + termSeconds,
            rank: globalRank,
            eaaRate: _calculateEAARate()
        });

        userMints[_msgSender()] = mintInfo;

        _activeMinters++;
        activeMinters = _activeMinters;

        _claimCount++;
        claimCount = _claimCount;

        _globalRank++;
        globalRank = _globalRank;

        emit RankClaimed(_msgSender(), term, maxTermDays, _globalRank, _calculateEAARate());
    }

    /// @notice Claim a mint reward after acquring a cRank.
    function claimMintReward_72B() external {
        uint256 _currentCreated = currentCreated;

        MintInfo memory mintInfo = userMints[_msgSender()];
        require(mintInfo.rank > 0, "CRank: No mint exists");
        require(block.timestamp > mintInfo.maturityTimestamp, "CRank: Mint maturity not reached");

        uint256 rewardAmount = _calculateMintReward(
            mintInfo.rank,
            mintInfo.term,
            mintInfo.claimMaxTerm,
            mintInfo.eaaRate
        );

        uint256 burnAmount = randomBurn(globalRank, mintInfo.rank, mintInfo.term);
        uint256 totalAmount = rewardAmount + burnAmount;

        require(totalAmount + _currentCreated < MAX_CREATED, "Max vvddrr created");

        _mint(_msgSender(), rewardAmount);

        _mint(_msgSender(), burnAmount);
        _burn(_msgSender(), burnAmount);

        _currentCreated += totalAmount;
        currentCreated = _currentCreated;

        // Emit variables

        uint256 eaaRate = mintInfo.eaaRate;
        uint256 termDays = mintInfo.term / SECONDS_IN_DAY;
        uint256 termBasis = termDays * 100;
        uint256 claimMaxTermDays = mintInfo.claimMaxTerm / SECONDS_IN_DAY;
        uint256 claimMaxTermBasis = claimMaxTermDays * 100;
        uint256 termPercent = getPercentage(termBasis, BASIS, claimMaxTermBasis);
        uint256 rankDelta = Math.max(globalRank - mintInfo.rank, 1);
        uint256 rankLogValueBasis = Calculate.log2(rankDelta) * 100;
        uint256 rankPercentage = BASIS + rankLogValueBasis;
        uint256 basisReward = CLAIM_REWARD_BASE * rankPercentage * termPercent * eaaRate;

        // End of emit variables

        _cleanUpUserMint();

        emit MintClaimed(_msgSender(), rewardAmount, rankPercentage, termPercent, eaaRate, basisReward);
    }

    /// @notice Add the ffxxdd staking contract as a controller to allow minting and burning.
    /// @param controller The address of the ffxxdd staking contract.
    function addFfxxddController(address controller) external onlyOwner {
        require(setFfxxddController == false, "ffxxdd controller already set");
        controllers[controller] = true;
        setFfxxddController = true;
    }

    /// @notice Add the mmccrr staking contract as a controller to allow minting and burning.
    /// @param controller The address of the mmccrr staking contract.
    function addMmccrrController(address controller) external onlyOwner {
        require(setMmccrrController == false, "mmccrr controller already set");
        controllers[controller] = true;
        setMmccrrController = true;
    }

    /// @notice Add the vvrrbb staking contract as a controller to allow minting and burning.
    /// @param controller The address of the vvrrbb staking contract.
    function addVvrrbbController(address controller) external onlyOwner {
        require(setVvrrbbController == false, "vvrrbb controller already set");
        controllers[controller] = true;
        setVvrrbbController = true;
    }

    /// @notice Burn functionality for a controller.
    /// @param from The address from which vvddrr will be taken to be burned.
    /// @param amount The amout of vvddrr to be burned expressed in Wei.
    function burnController(address from, uint256 amount) external {
        uint256 _currentCreated = currentCreated;
        require(controllers[_msgSender()], "Only controllers can burn");
        require(_currentCreated + amount < MAX_CREATED, "Mint amount will exceed max created");
        _burn(from, amount);
        _currentCreated += amount;
        currentCreated = _currentCreated;
    }

    /// @notice Mint functionality for a controller.
    /// @param to The address to which minted vvddrr will be sent.
    /// @param amount The amount of vvddrr minted expressed in Wei.
    function mintController(address to, uint256 amount) external {
        uint256 _currentCreated = currentCreated;
        require(controllers[_msgSender()], "Only controllers can mint");
        require(_currentCreated + amount < MAX_CREATED, "Mint amount will exceed max created");
        _mint(to, amount);
        _currentCreated += amount;
        currentCreated = _currentCreated;
    }

    /// @notice An explicit function to determine the amount of vvddrr created.
    /// @dev Includes both minted and burned tokens.
    /// @return The amount of currently created vvddrr tokens expressed in Wei.
    function getCurrentCreated() external view returns (uint256) {
        return currentCreated;
    }

    /// @notice Get the current Early Adoption Amplification factor.
    /// @return A percentage basis point value provided the current EAAR.
    function getCurrentEAAR() external view returns (uint256) {
        return _calculateEAARate();
    }

    /// @notice Get the current max term.
    /// @return The current maximum term for which a claim can be set.
    function getCurrentMaxTerm() external view returns (uint256) {
        return _calculateMaxTerm();
    }

    /// @notice Get struct providing the information for a speciic user mint.
    /// @return The mint info for a specific address.
    function getUserMint() external view returns (MintInfo memory) {
        return userMints[_msgSender()];
    }

    /// @notice An explicit function to return the maximum about of vvddrr that can be created.
    /// @return The maxium amount of vvddrr that can be created expressed in Wei.
    function getMaximumCreated() external pure returns (uint256) {
        return MAX_CREATED;
    }

    /// @notice Set the genesisTimestamp after contract creation.
    function setGenesisTimestamp() public onlyOwner {
      require(setGenesisOnce == false, "Genesis timestamp already set");
      genesisTimestamp = block.timestamp;
      setGenesisOnce = true;
    }

    /// @notice Calculate the Early Adopter Amplification Rate using globalRank and step values.
    /// @return Retuns the current EAA Rate expresses in percentage basis points.
    function _calculateEAARate() public view returns (uint256) {
        uint256 globalRankDecrease = Math.mulDiv(globalRank,EAA_PM_STEP_BASIS,EAA_RANK_STEP);
        uint256 globalRankDecreaseBasis = globalRankDecrease * 100;
        uint256 decrease = EAA_PM_START_BASIS - globalRankDecreaseBasis;
        if (decrease < BASIS) return BASIS;
        return decrease;
    }

    /// @notice An explicit function to provide the current total supply of vvddrr.
    /// @dev This does not include a count of burned vvddrr.
    /// @return Retuns the current total supply of vvddrr.
    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    /// @notice Create a random burn amount between 0 and the CLAIM_REWARD_BASE amount.
    /// @param a A variable input to create randomness.
    /// @param b A variable input to create randomness.
    /// @param c A variable input to create randomness.
    /// @return A random value.
    function randomBurn(uint256 a, uint256 b, uint256 c) public view returns (uint256) {
        uint256 v = uint(keccak256(abi.encodePacked("f609ad48b824b4cc229bae65827cc0c228bd63bb33010c47e88fc6375aecd74f", block.timestamp, toString(a), toString(b), toString(c)))) % CLAIM_REWARD_BASE;
        return v;
    }

    /// @notice The gross reward for a given user mint.
    /// @param rankDelta The different between the current globalRank and a user's cRank.
    /// @param term A user's initially set mint term.
    /// @param claimMaxTerm A user's set max term.
    /// @param eaaRate The calculated Early Adopter Amplication Factor.
    /// @return The gross reward for a mint claim expressed in basis points.
    function getGrossReward(
        uint256 rankDelta,
        uint256 term,
        uint256 claimMaxTerm,
        uint256 eaaRate
    ) public pure returns (uint256) {
        uint256 termPercentage = getTermPercent(term, claimMaxTerm);
        uint256 rankLogValueBasis = Calculate.log2(rankDelta) * 100;
        uint256 rankPercentage = BASIS + rankLogValueBasis;
        uint256 basisReward = CLAIM_REWARD_BASE * rankPercentage * termPercentage * eaaRate;
        uint256 reward = basisReward / BASIS_DEMNOMINATOR;
        uint256 rewardAdjusted = reward / 100;
        return rewardAdjusted;
    }

    /// @notice A general percentage calculation function used for basis point calculations.
    /// @param a A numerator value.
    /// @param b A basis point value.
    /// @param d A denominator value.
    /// @return A calculated percentage value returned in basis points.
    function getPercentage(uint256 a, uint256 b, uint256 d) public pure returns (uint256) {
        uint256 value = Math.mulDiv(a,b,d);
        return value;
    }

    /// @notice Calculate percentage of a mint term relative to the max available term in basis points.
    /// @param term A user selected mint term.
    /// @param claimMaxTerm The maxium available term.
    /// @return A percentage value returned in basis points.
    function getTermPercent(uint256 term, uint256 claimMaxTerm) public pure returns (uint256) {
        uint256 termDays = term / SECONDS_IN_DAY;
        uint256 termBasis = termDays * 100;
        uint256 claimMaxTermDays = claimMaxTerm / SECONDS_IN_DAY;
        uint256 claimMaxTermBasis = claimMaxTermDays * 100;
        // uint256 termPercent = (BASIS + getPercentage(termBasis, BASIS, claimMaxTermBasis));
        uint256 termPercent = getPercentage(termBasis, BASIS, claimMaxTermBasis);
        return termPercent;
    }

    /// @notice Remove the user mint struct and decrease the active minters after a mint is claimed.
    function _cleanUpUserMint() private {
        delete userMints[_msgSender()];
        activeMinters--;
    }

    /// @notice Use globalRank and term amplifiers to calculate the maxixum term allowed to claim a mint.
    /// @return Returns a value in seconds beyond which a mint term will not be extended.
    function _calculateMaxTerm() private view returns (uint256) {
        if (globalRank > TERM_AMPLIFIER_THRESHOLD) {
            uint256 delta = globalRank.fromUInt().log_2().mul(TERM_AMPLIFIER.fromUInt()).toUInt();
            uint256 newMax = MAX_TERM_START + delta * SECONDS_IN_DAY;
            return Math.min(newMax, MAX_TERM_END);
        }
        return MAX_TERM_START;
    }

    /// @notice Calculate mint rewards based on the relationship between the globalRank, cRank and gross reward.
    /// @return Returns a reward value expressed in Wei.
    function _calculateMintReward(
        uint256 cRank,
        uint256 term,
        uint256 claimMaxTerm,
        uint256 eaaRate
    ) private view returns (uint256) {
        uint256 rankDelta = Math.max(globalRank - cRank, 1);
        uint256 reward = getGrossReward(rankDelta, term, claimMaxTerm, eaaRate);
        return reward;
    }

    /// @notice Returns an integer value as a string.
    /// @param value The integer value to have a type change.
    /// @return A string of the inputted integer value.
    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}
