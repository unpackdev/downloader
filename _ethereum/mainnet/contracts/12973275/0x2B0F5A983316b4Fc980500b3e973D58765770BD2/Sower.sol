//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@%,,,,,,,@#,@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/%,,**,***,*,,,*(#@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*%*,,**********,,/%%@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@*,************,/@(@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@(,**,********,/@/@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,%,,**********,,#*@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.%,,*********,*&(@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&*(#(,,******,,,,,&/@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,&@#,,,*****,***,*%,@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,(***,******************,%&&/&@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@*,**************************,/&(#@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@,%*******************************,*,#,/@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@#&***************************************#%*#@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@*&*******************************************/%(%%%((@
// @@@@@@@@@@@@@@@@@@@@@@@@ %*****************************************************#
// @@@@@@@@@@@@@@@@@@@@@&(%*************************************/&@(***************
// @@@@@@@@@@@@@@@@@@@#%%/***********%(#************************(//(((************#
// @@@@@@@@@@@@@@@@@@/(************@#&&#/***************************************//%
// @@@@@@@@@@@@@@@@#@**********&###@@@@&#&*************************************#/@@
// @@@@@@@@@@@@@@/%**********,%%@@@@@@@@*&************************************/#&@@
// @@@@@@@@@@@@%#/********/(#@@@@@@@@@@@@@(@%********************************&,@@@@
// @@@@@%#%####*********#(#@@@@@@@@@@@@@@@#@(******************************%&#@@@@@
// @@(@%/************@#@@@@@@@@@@@@@@@@@@@%@********************&*******@%,@@@@@@@@
// @/&//*////////*(@/@@@@@@@@@@@@@@@@@@@@&#/*////////////////**@%%(///%@@@@@@@@@@@@
// %(&/////////**%(&@@@@@@@@@@@@@@@@@@@@@(#//////////////////*/@*@@@@@@@@@@@@@@@@@@
// @@@*@@*//*#@&#@@@@@@@@@@@@@@@@@@@@@@@*@#*/////////////////*%@/@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#///////////////////%(%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/%///////////////////@##@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#///////////////////(@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#///////////////////%,@@@@@@@@@@@@@@@@
// @@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(&#////////////////////@/@@@@@@@@@@@@@@@
// @@@,@@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@*&//////////////////////&%@@@@@@@@@@@@@@
// @@@@,@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#&//////////////////////(&(@@@@@@@@@@@@@@
// @@@@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@*///////////////////////%/#@@@@@@@@@@
// @@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@(/////////////////////////&&&@@@@@@@@@
// @@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@(////////////%%/////////////%(@@@@@@@@@
// @@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#(/////////////&/@#////////////(&*@@@@@@@@
// @@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@(((((((((((//#%&@#&/((((((((((((&*@@@@@@@@
// @@@@,@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@%@((((((((((((#(%@@@@(@((((((((((((&/@@@@@@@@
// @@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##((((((((((((&&@@@@#&@((((((((((((&,@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@%(((((((((((&/@@@@@@@(@((((((((((((&@&@@@@@@@
// @@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@%(#(#########(%%@@@@@@@@@#&(#########(&@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%###########@%%@@@@@@@@@/@%##########&/@@@@@@@@
// @@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@/&##########%&#@@@@@@@@@@@/@%###########@#@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%%%%%%%%%%%@#@@@@@@@@@@@@@&%%%%%%%%%%%%@@#@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@&%&%%%%%%%%%%&&#@@@@@@@@@@@@@@&@%%%%%%%%%%%@%@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@/@%%%%%%%%%%%%@#@@@@@@@@@@@@@@%@%%%%%%%%%%%&%@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@/@%%%%%%%%%%%%%&@/%@@@@@@@@@@@@@%%%%%%%%%%%%%@#@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@%&%%%%%%%%%%%@@&@@@@@@@@@%%%%%%%%%%%%%%%&@@#(
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&%%%%%%%%%%&&%@@@@@@&@%%%%%%%%%%%%%%%%%%%%
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##%#@@@@#@@@@@@@@@@@@@@@@@@@#%%%%%%%%%%%

import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./IVariety.sol";
import "./IEarlyBirdRegistry.sol";

/// @title Sower
/// @author Simon Fremaux (@dievardump)
contract Sower is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    event Collected(
        address indexed operator,
        address indexed variety,
        uint256 indexed count,
        uint256 value
    );

    event EarlyBirdSessionAdded(uint256 sessionId, uint256 projectId);
    event EarlyBirdSessionRemoved(uint256 sessionId, uint256 projectId);

    event VarietyAdded(address variety);
    event VarietyChanged(address variety);
    event VarietyEmpty(address variety);

    event DonationRecipientAdded(address recipient);
    event DonationRecipientRemoved(address recipient);

    struct VarietyData {
        uint8 maxPerCollect; // how many can be collected at once. 0 == no limit
        bool active; // if Variety is active or not
        bool curated; // curated Varieties can only be minted by Variety creator
        address location; // address of the Variety contract
        address creator; // creator of the variety (in case the contract opens to more creators)
        uint256 price; // price of collecting
        uint256 available; // how many are available
        uint256 reserve; // how many are reserve for creator
        uint256 earlyBirdUntil; // earlyBird limit timestamp
        uint256 earlyBirdSessionId; // earlyBirdSessionId
    }

    // main donation, we start with nfDAO
    address public mainDonation = 0x37133cda1941449cde7128f0C964C228F94844a8;

    // Varieties list
    mapping(address => VarietyData) public varieties;

    // list of known varieties address
    EnumerableSet.AddressSet internal knownVarieties;

    // list of address to whom I would like to donate
    EnumerableSet.AddressSet internal donations;

    // last generated seed
    bytes32 public lastSeed;

    // address who used their EarlyBird access
    mapping(uint256 => mapping(address => bool)) internal _earlyBirdsConsumed;

    // the early bird registry
    address public earlyBirdRegistry;

    // because I messed up the EarlyBird registration before the launch
    // I have to use EarlyBirdSession containing one or more EarlyBirgProjectID.
    mapping(uint256 => EnumerableSet.UintSet) internal earlyBirdSessions;

    constructor() {
        // Gitcoin Gnosis
        _addDonationRecipient(0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6);

        // WOCA
        _addDonationRecipient(0xCCa88b952976DA313Fb928111f2D5c390eE0D723);

        // Hardhat deploy / Jolly Roger
        _addDonationRecipient(0xF0D7a8198D75e10517f035CF11b928e9E2aB20f4);
    }

    /// @notice Allows collector to collect up to varietyData.maxPerCollect tokens from variety.
    /// @param count the number of tokens to collect
    /// @param variety the variety to collect from
    function plant(uint256 count, address variety)
        external
        payable
        nonReentrant
    {
        require(count > 0, '!count');

        VarietyData storage varietyData = _getVariety(variety);

        // curated varieties have to be created in a specific way, with the seed, only by creator
        require(varietyData.curated == false, "Can't plant this Variety.");

        // varieties can be paused or out of stock
        require(varietyData.active == true, 'Variety paused or out of seeds.');

        // if we are in an earlyBird phase
        if (varietyData.earlyBirdUntil >= block.timestamp) {
            require(
                isUserInEarlyBirdSession(
                    msg.sender,
                    varietyData.earlyBirdSessionId
                ),
                'Not registered for EarlyBirds'
            );

            require(
                _earlyBirdsConsumed[varietyData.earlyBirdSessionId][
                    msg.sender
                ] == false,
                'Already used your EarlyBird'
            );

            // set early bird as consumed
            _earlyBirdsConsumed[varietyData.earlyBirdSessionId][
                msg.sender
            ] = true;

            require(count == 1, 'Early bird can only grab one');
        }

        require(
            // verifies that there are enough tokens available for this variety
            (varietyData.available - varietyData.reserve) >= count &&
                // and that the user doesn't request more than what is allowed in one tx
                (varietyData.maxPerCollect == 0 ||
                    uint256(varietyData.maxPerCollect) >= count),
            'Too many requested.'
        );

        address operator = msg.sender;

        require(msg.value == varietyData.price * count, 'Value error.');

        _plant(varietyData, count, operator);
    }

    /// @notice Owner function to be able to get varieties from the reserve
    /// @param count how many the owner wants
    /// @param variety from what variety
    /// @param recipient might be a giveaway? recipient can be someone else than owner
    function plantFromReserve(
        uint256 count,
        address variety,
        address recipient
    ) external {
        require(count > 0, '!count');

        VarietyData storage varietyData = _getVariety(variety);

        // curated varieties have to be created in a specific way, with the seed, only by creator
        require(varietyData.curated == false, "Can't plant this Variety.");

        // verify that caller is the variety creator
        // or there is no variety creator and the caller is current owner
        require(
            msg.sender == varietyData.creator ||
                (varietyData.creator == address(0) && msg.sender == owner()),
            'Not Variety creator.'
        );

        require(
            varietyData.reserve >= count && varietyData.available >= count,
            'Not enough reserve.'
        );

        varietyData.reserve -= count;

        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        _plant(varietyData, count, recipient);
    }

    /// @notice Some Varieties can not generate aesthetic output with random seeds.
    ///         Those are "curated Varieties" that only the creator can mint from with curated seeds
    ///         The resulting Seedlings will probably be gifted or sold directly on Marketplaces
    ///         (direct sale or auction)
    /// @param variety the variety to create from
    /// @param recipient the recipient of the creation
    /// @param seeds the seeds to create
    function plantFromCurated(
        address variety,
        address recipient,
        bytes32[] memory seeds
    ) external {
        require(seeds.length > 0, '!count');

        VarietyData storage varietyData = _getVariety(variety);

        // verify this variety is indeed a curated one
        require(varietyData.curated == true, 'Variety not curated.');

        // verify that caller is the variety creator
        // or there is no variety creator and the caller is current owner
        require(
            msg.sender == varietyData.creator ||
                (varietyData.creator == address(0) && msg.sender == owner()),
            'Not Variety creator.'
        );

        if (recipient == address(0)) {
            recipient = msg.sender;
        }

        _plantSeeds(varietyData, recipient, seeds);
    }

    /// @notice Helper to list all Varieties
    /// @return list of varieties
    function listVarieties() external view returns (VarietyData[] memory list) {
        uint256 count = knownVarieties.length();
        list = new VarietyData[](count);
        for (uint256 i; i < count; i++) {
            list[i] = varieties[knownVarieties.at(i)];
        }
    }

    /// @notice Adds a new variety to the list
    /// @param newVariety the variety to be added
    /// @param price the collection cost
    /// @param maxPerCollect how many can be collected at once; 0 == no limit
    /// @param active if the variety is active or not
    /// @param creator variety creator
    /// @param available variety supply
    /// @param reserve variety reserve for variety creator
    /// @param curated if the variety is curated; if yes only creator can mint from it
    function addVariety(
        address newVariety,
        uint256 price,
        uint8 maxPerCollect,
        bool active,
        address creator,
        uint256 available,
        uint256 reserve,
        bool curated
    ) external onlyOwner {
        require(
            !knownVarieties.contains(newVariety),
            'Variety already exists.'
        );
        knownVarieties.add(newVariety);

        varieties[newVariety] = VarietyData({
            maxPerCollect: maxPerCollect,
            price: price,
            active: active,
            creator: creator,
            location: newVariety,
            available: available,
            reserve: reserve,
            curated: curated,
            earlyBirdUntil: 0,
            earlyBirdSessionId: 0
        });

        emit VarietyAdded(newVariety);
    }

    /// @notice Allows to toggle a variety active state
    /// @param variety the variety address
    /// @param isActive if active or not
    function setActive(address variety, bool isActive) public onlyOwner {
        VarietyData storage varietyData = _getVariety(variety);
        require(
            !isActive || varietyData.available > 0,
            "Can't activate empty variety."
        );
        varietyData.active = isActive;
        emit VarietyChanged(variety);
    }

    /// @notice Allows to change the max per collect for a variety
    /// @param variety the variety address
    /// @param maxPerCollect new max per collect
    function setMaxPerCollect(address variety, uint8 maxPerCollect)
        external
        onlyOwner
    {
        VarietyData storage varietyData = _getVariety(variety);
        varietyData.maxPerCollect = maxPerCollect;
        emit VarietyChanged(variety);
    }

    /// @notice activate EarlyBird for a Variety.
    ///         When earlyBird, only registered address can plant
    /// @param varieties_ the varieties address
    /// @param earlyBirdDuration duration of Early Bird from now on
    /// @param earlyBirdSessionId the session id containing projects to check on the EarlyBirdRegistry
    /// @param activateVariety if the variety must be automatically activated (meaning early bird starts now)
    function activateEarlyBird(
        address[] memory varieties_,
        uint256 earlyBirdDuration,
        uint256 earlyBirdSessionId,
        bool activateVariety
    ) external onlyOwner {
        require(
            earlyBirdSessions[earlyBirdSessionId].length() > 0,
            'Session id empty'
        );

        for (uint256 i; i < varieties_.length; i++) {
            VarietyData storage varietyData = _getVariety(varieties_[i]);
            varietyData.earlyBirdUntil = block.timestamp + earlyBirdDuration;
            varietyData.earlyBirdSessionId = earlyBirdSessionId;

            if (activateVariety) {
                setActive(varieties_[i], true);
            } else {
                emit VarietyChanged(varieties_[i]);
            }
        }
    }

    /// @notice sets early bird registry
    /// @param earlyBirdRegistry_ the registry
    function setEarlyBirdRegistry(address earlyBirdRegistry_)
        external
        onlyOwner
    {
        require(earlyBirdRegistry_ != address(0), 'Wrong address.');
        earlyBirdRegistry = earlyBirdRegistry_;
    }

    /// @notice Allows to add an early bird project id to an "early bird session"
    /// @dev an early bird session is a group of early bird registrations projects
    /// @param sessionId the session to add to
    /// @param projectIds the projectIds (containing registration in EarlyBirdRegistry) to add
    function addEarlyBirdProjectToSession(
        uint256 sessionId,
        uint256[] memory projectIds
    ) external onlyOwner {
        require(sessionId > 0, "Session can't be 0");
        for (uint256 i; i < projectIds.length; i++) {
            require(
                IEarlyBirdRegistry(earlyBirdRegistry).exists(projectIds[i]),
                'Unknown early bird project'
            );
            earlyBirdSessions[sessionId].add(projectIds[i]);
            emit EarlyBirdSessionAdded(sessionId, projectIds[i]);
        }
    }

    /// @notice Allows to remove an early bird project id from an "early bird session"
    /// @dev an early bird session is a group of early bird registrations projects
    /// @param sessionId the session to remove from
    /// @param projectIds the projectIds (containing registration in EarlyBirdRegistry) to remove
    function removeEarlyBirdProjectFromSession(
        uint256 sessionId,
        uint256[] memory projectIds
    ) external onlyOwner {
        require(sessionId > 0, "Session can't be 0");

        for (uint256 i; i < projectIds.length; i++) {
            earlyBirdSessions[sessionId].remove(projectIds[i]);
            emit EarlyBirdSessionRemoved(sessionId, projectIds[i]);
        }
    }

    /// @notice Helper to know if a user is in any of the early bird list for current session
    /// @param user the user to test
    /// @param sessionId the session to test for
    /// @return if the user is registered or not
    function isUserInEarlyBirdSession(address user, uint256 sessionId)
        public
        view
        returns (bool)
    {
        // get all earlyBirdIds attached to the earlyBirdSession
        EnumerableSet.UintSet storage session = earlyBirdSessions[sessionId];
        uint256 count = session.length();

        for (uint256 i; i < count; i++) {
            // if the address is registered to any of those projectId
            if (
                IEarlyBirdRegistry(earlyBirdRegistry).isRegistered(
                    user,
                    session.at(i)
                )
            ) {
                return true;
            }
        }

        // else it's not an early bird
        return false;
    }

    /// @notice Helper to list all donation recipients
    /// @return list of donation recipients
    function listDonations() external view returns (address[] memory list) {
        uint256 count = donations.length();
        list = new address[](count);
        for (uint256 i; i < count; i++) {
            list[i] = donations.at(i);
        }
    }

    /// @notice Allows to add a donation recipient
    /// @param recipient the recipient
    function addDonationRecipient(address recipient) external onlyOwner {
        _addDonationRecipient(recipient);
    }

    /// @notice Allows to remove a donation recipient
    /// @param recipient the recipient
    function removeDonationRecipient(address recipient) external onlyOwner {
        _removeDonationRecipient(recipient);
    }

    /// @notice Set mainDonation donation address
    /// @param newMainDonation the new address
    function setNewMainDonation(address newMainDonation) external onlyOwner {
        mainDonation = newMainDonation;
    }

    /// @notice This function allows Sower to answer to a seed change request
    ///         in the event where a seed would produce errors of rendering
    ///         1) this function can only be called by Sower if the token owner
    ///         asked for a new seed (see Variety contract)
    ///         2) this function will only be called if there is a rendering error
    /// @param tokenId the tokenId that needs update
    function updateTokenSeed(address variety, uint256 tokenId)
        external
        onlyOwner
    {
        require(knownVarieties.contains(variety), 'Unknown variety.');
        IVariety(variety).changeSeedAfterRequest(tokenId);
    }

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "I don't think so.");

        uint256 count = donations.length();

        // forces mainDonation and donations to not be empty
        // Code is law.
        require(
            mainDonation != address(0) && count > 0,
            'You have to give in order to get.'
        );

        bool success;

        // 10% of current balance
        uint256 ten = address(this).balance / 10;

        // send 10% to mainDonation address
        (success, ) = mainDonation.call{value: ten}('');
        require(success, '!success');

        // share 10% between all other donation recipients
        uint256 parts = ten / count;
        for (uint256 i; i < count; i++) {
            (success, ) = donations.at(i).call{value: parts}('');
            require(success, '!success');
        }

        // send the rest to sender; use call since it might be a contract someday
        (success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, '!success');
    }

    /// @dev Receive function for royalties
    receive() external payable {}

    /// @dev Internal collection method
    /// @param varietyData the varietyData
    /// @param count how many to collect
    /// @param operator Seedlings recipient
    function _plant(
        VarietyData storage varietyData,
        uint256 count,
        address operator
    ) internal {
        bytes32 seed = lastSeed;
        bytes32[] memory seeds = new bytes32[](count);
        bytes32 blockHash = blockhash(block.number - 1);
        uint256 timestamp = block.timestamp;

        // generate next seeds
        for (uint256 i; i < count; i++) {
            seed = _nextSeed(seed, timestamp, operator, blockHash);
            seeds[i] = seed;
        }

        // saves lastSeed before planting
        lastSeed = seed;

        _plantSeeds(varietyData, operator, seeds);
    }

    /// @dev Allows to plant a list of seeds
    /// @param varietyData the variety data
    /// @param collector the recipient of the Seedling
    /// @param seeds the seeds to plant
    function _plantSeeds(
        VarietyData storage varietyData,
        address collector,
        bytes32[] memory seeds
    ) internal {
        IVariety(varietyData.location).plant(collector, seeds);
        uint256 count = seeds.length;

        varietyData.available -= count;
        if (varietyData.available == 0) {
            varietyData.active = false;
            emit VarietyEmpty(varietyData.location);
        }

        emit Collected(collector, varietyData.location, count, msg.value);

        // if Variety has a creator that is not contract owner, send them the value directly
        if (
            varietyData.creator != address(0) &&
            msg.value > 0 &&
            varietyData.creator != owner()
        ) {
            (bool success, ) = varietyData.creator.call{value: msg.value}('');
            require(success, '!success');
        }
    }

    /// @dev Calculate next seed using a few on chain data
    /// @param currentSeed the current seed
    /// @param timestamp current block timestamp
    /// @param operator current operator
    /// @param blockHash last block hash
    /// @return a new bytes32 seed
    function _nextSeed(
        bytes32 currentSeed,
        uint256 timestamp,
        address operator,
        bytes32 blockHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    currentSeed,
                    timestamp,
                    operator,
                    blockHash,
                    block.coinbase,
                    block.difficulty,
                    tx.gasprice
                )
            );
    }

    /// @notice Returns a variety, throws if does not exist
    /// @param variety the variety to get
    function _getVariety(address variety)
        internal
        view
        returns (VarietyData storage)
    {
        require(knownVarieties.contains(variety), 'Unknown variety.');
        return varieties[variety];
    }

    /// @dev Allows to add a donation recipient to the list of donations
    /// @param recipient the recipient
    function _addDonationRecipient(address recipient) internal {
        donations.add(recipient);
        emit DonationRecipientAdded(recipient);
    }

    /// @dev Allows to remove a donation recipient from the list of donations
    /// @param recipient the recipient
    function _removeDonationRecipient(address recipient) internal {
        donations.remove(recipient);
        emit DonationRecipientRemoved(recipient);
    }
}
