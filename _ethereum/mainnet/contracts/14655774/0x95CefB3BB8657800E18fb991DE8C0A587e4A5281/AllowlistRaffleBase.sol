//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

error AlreadyDrawn();
error ExceedsMaxEntriesPerEntrant();
error ExceedsTotalMaxEntries();
error MaxUniqueEntrantsReached();
error NotDrawn();
error DrawScriptNotSet();

/**
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOkxxddddddxxkOO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdoodddooddxxkkkkkkxxddoodddooxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdooooxOKNWMMMMMMMMMMMMMMMMMMMMWNKOxoooodkKWMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMNOooookKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkooookNMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMXkoloxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkolokXMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMNOoloONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOoloONMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMXxllkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxllxXMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMXxcl0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ocdXMMMMMMMMMMMMMM
 * MMMMMMMMMMMWNxco0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo:xNMMMMMMMMMMMM
 * MMMMMMMMMMWOcc0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ccOWMMMMMMMMMM
 * MMMMMMMMMXd:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:dXWMMMMMMMM
 * MMMMMMMM0clKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKk0WMMMMMMMKlc0MMMMMMMM
 * MMMMMMWO:dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;. .xWMMMMMMMNd:OWMMMMMM
 * MMMMMWk;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'      .dNMMMMMMMWx;kWMMMMM
 * MMMMWx;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.          .oXMMMMMMMWx;xWMMMM
 * MMMWO;dWMMMMMMMMMMWkc:::::::::::::::::::::::::::::::::::::::::::::'                cXMMMMMMMWd;OMMMM
 * MWMK:lNMMMMMMMMMMNo.                                                                :XMMMMMMMNl:KMMM
 * MMNl:XMMMMMMMMMMXc                                                               .;lONMMMMMMMMK:lNMM
 * MMk;xMMMMMMMMMMK:                                                             'cxKWMMMMMMMMMMMMx;kMM
 * MNccNMMMMMMMMM0,                                                          .;oONMMMMMMMMMMMMMMMMNccNM
 * MO;dMMMMMMMMMMK;                                                       'cxKWMMMMMMMMMMMMMMMMMMMMx;OM
 * Md;0MMMMMMMMMMMK:            ':::::::::augminted labs, llc:::::::::oolONMMMMMMMMMMMMMMMMMMMMMMMM0;dM
 * Wl:NMMMMMMMMMMMMXc          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMX:lW
 * N:lWMMMMMMMMMMMMMNo.        cNMWk:::::::::::::::ckXNMMXd:::::::::::::cOWMMMMMMMMMMMMMMMMMMMMMMMMWc:N
 * X:lWMMMMMMMMMMMMMMNd.      .OMM0'               :KMMWK;             .lXMMMMMMMMMMMMMMMMMMMMMMMMMWl:X
 * X:lWMMMMMMMMMMMMMMMWx.     lWMNl              .oNMMWk'             .xNMMMMMMMMMMMMMMMMMMMMMMMMMMWl:N
 * NccNMMMMMMMMMMMMMMMMWO'   ,0MMk.             'kWMNXd.             ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMNccN
 * Mo;KMMMMMMMMMMMMMMMMMM0, .dWMX:             ;0WMKc.              :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:oM
 * Mx;kMMMMMMMMMMMMMMMMMMMK:cXMWk.           .lXMW0,              .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk;xM
 * MK:oWMMMMMMMMMMMMMMMMMMMNNMMWXOdoc;'.    .xNWWx.              .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo:KM
 * MWd:0MMMMMMMMMMMMMMMMMMMMMN00XNMMMWNX0kdo0WMXo.              ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;oWM
 * MMK:lWMMMMMMMMMMMMMMMMMMMMNx'.';coxO0XWMMMMK:               cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo:KMM
 * MMWx;kMMMMMMMMMMMMMMMMMMMMMWk.      ..,:coo'              .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk;xMMM
 * MMMNo:KMMMMMMMMMMMMMMMMMMMMMWO'                          'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:oWMMM
 * MMMMXccKMMMMMMMMMMMMMMMMMMMMMW0,                        :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKccXMMMM
 * MMMMMXccKMMMMMMMMMMMMMMMMMMMMMMK:                     .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXccXMMMMM
 * MMMMMMXccKMMMMMMMMMMMMMMMMMMMMMMXc                   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKclXMMMMMM
 * MMMMMMMNo:OWMMMMMMMMMMMMMMMMMMMMMNo.                ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:oNMMMMMMM
 * MMMMMMMMWk:dNMMMMMMMMMMMMMMMMMMMMMWd.             .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:kWMMMMMMMM
 * MMMMMMMMMMKlcOWMMMMMMMMMMMMMMMMMMMMWx'          .dXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOclKMMMMMMMMMM
 * MMMMMMMMMMMWkcl0WMMMMMMMMMMMMMMMMMMMWKOOOOOOOOOOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0lckWMMMMMMMMMMM
 * MMMMMMMMMMMMMNxco0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ocxXMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWMXxclONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOlcxXMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMNklldKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdlokNMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWKdlld0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdlldKWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMW0doookKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkoood0WMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMWXkdoooxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxooodkXWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxooooddkO0KXNWWWMMMMMWWNXK0OxdoddooxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxdooddddddddddddddoodxkOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXXXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * @title Base contract for allowlist raffle
 * @author Augminted Labs, LLC
 * @notice Winners are calculated deterministically off-chain using a provided script
 */
abstract contract AllowlistRaffleBase is Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Address for address;

    struct VrfRequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    uint256 public immutable NUMBER_OF_WINNERS;
    uint256 public immutable MAX_UNIQUE_ENTRANTS;
    uint256 public immutable MAX_ENTRIES_PER_ENTRANT;
    uint256 public immutable MAX_TOTAL_ENTRIES;
    VrfRequestConfig public vrfRequestConfig;
    string public drawScriptURI;
    bool public drawn;
    uint256 public seed;
    uint256 public totalEntrants;
    uint256 public totalEntries;
    mapping(uint256 => address) public entrants;
    mapping(address => uint256) public addressEntries;

    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    constructor(
        uint256 numberOfWinners,
        uint256 maxUniqueEntrants,
        uint256 maxEntriesPerEntrant,
        uint256 maxTotalEntries,
        address vrfCoordinator
    )
        VRFConsumerBaseV2(vrfCoordinator)
    {
        NUMBER_OF_WINNERS = numberOfWinners;
        MAX_UNIQUE_ENTRANTS = maxUniqueEntrants;
        MAX_ENTRIES_PER_ENTRANT = maxEntriesPerEntrant;
        MAX_TOTAL_ENTRIES = maxTotalEntries;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @param _vrfRequestConfig Struct with updated configuration values
     */
    function setVrfRequestConfig(VrfRequestConfig memory _vrfRequestConfig) public onlyOwner {
        vrfRequestConfig = _vrfRequestConfig;
    }

    /**
     * @notice Set URI for script used to determine winners
     * @param uri IPFS URI for determining the winners
     */
    function setDrawScriptURI(string calldata uri) public onlyOwner {
        if (drawn) revert AlreadyDrawn();

        drawScriptURI = uri;
    }

    /**
     * @notice Flip paused state to disable entry
     */
    function flipPaused() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @notice Purchase specified amount of entries into the raffle
     * @param amount Amount of entries to purchase
     */
    function enter(uint256 amount) public virtual payable whenNotPaused nonReentrant {
        if (drawn) revert AlreadyDrawn();

        if (
            MAX_UNIQUE_ENTRANTS > 0
            && MAX_UNIQUE_ENTRANTS == totalEntrants
            && addressEntries[_msgSender()] == 0
        ) revert MaxUniqueEntrantsReached();

        if (
            MAX_TOTAL_ENTRIES > 0
            && totalEntries + amount > MAX_TOTAL_ENTRIES
        ) revert ExceedsTotalMaxEntries();

        if (
            MAX_ENTRIES_PER_ENTRANT > 0
            && addressEntries[_msgSender()] + amount > MAX_ENTRIES_PER_ENTRANT
        ) revert ExceedsMaxEntriesPerEntrant();

        pay(amount);

        if (addressEntries[_msgSender()] == 0) {
            entrants[totalEntrants] = _msgSender();
            totalEntrants += 1;
        }

        addressEntries[_msgSender()] += amount;
        totalEntries += amount;
    }

    /**
     * @notice Abstract function to set payment functionality
     * @param amount Amount of entries being purchased
     */
    function pay(uint256 amount) internal virtual;

    /**
     * @notice Set seed for drawing winners
     * @dev Must set the deterministic draw script before to ensure fairness
     */
    function draw() public onlyOwner {
        if (drawn) revert AlreadyDrawn();
        if (bytes(drawScriptURI).length == 0) revert DrawScriptNotSet();

        COORDINATOR.requestRandomWords(
            vrfRequestConfig.keyHash,
            vrfRequestConfig.subId,
            vrfRequestConfig.requestConfirmations,
            vrfRequestConfig.callbackGasLimit,
            1 // number of random words
        );
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        seed = randomWords[0];
        drawn = true;
    }
}