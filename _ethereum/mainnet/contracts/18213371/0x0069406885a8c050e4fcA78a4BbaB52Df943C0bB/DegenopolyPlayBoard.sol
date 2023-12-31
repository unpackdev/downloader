// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IAddressProvider.sol";
import "./IDegenopoly.sol";
import "./IDegenopolyNode.sol";
import "./IDegenopolyNodeManager.sol";

contract DegenopolyPlayBoard is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ======== STORAGE ======== */

    enum CaseType {
        Start,
        Event,
        DevWallet,
        NFT
    }

    struct Case {
        CaseType caseType;
        bytes info;
    }

    enum EventType {
        None,
        Bullish,
        CEX,
        FUD,
        Airdrop,
        Jeet
    }

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @notice play board cases
    Case[] public cases;

    /// @notice number of cases
    uint256 public numberOfCases;

    /// @notice fee of roll dice
    uint256 public fee;

    /// @notice fee ratio for dev wallet and others for treasury wallet
    uint256 public devFeeRatio;

    /// @notice mapping account => position at play board
    mapping(address => uint256) public positionOf;

    /// @notice mapping account => last dice
    mapping(address => uint256) public diceOf;

    /// @dev mapping account => last roll block number
    mapping(address => uint256) private lastRollBlockOf;

    /// @dev mapping account => last event type from roll dice
    mapping(address => EventType) public lastEventTypeOf;

    /// @dev mapping account => mintable node
    mapping(address => address) public mintableNode;

    /* ======== ERRORS ======== */

    error NOT_MANAGER();
    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error INVALID_FEE_RATIO();
    error INVALID_ROLL();
    error EXISTING_CHOICE();
    error NO_CEX_CHOICE();
    error NO_AIRDROP_CHOICE();
    error INVALID_CEX_CHOICE();

    /* ======== EVENTS ======== */

    event AddressProvider(address addressProvider);
    event Fee(uint256 fee);
    event DevFeeRatio(uint256 devFeeRatio);
    event RollDice(
        address account,
        uint256 dice,
        uint256 position,
        Case nowCase,
        EventType eventType
    );
    event CEXChoice(address account, Case nowCase, EventType eventType);
    event AirdropChoice(address account, address node);
    event RejectMintableNode(address account, address node);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _addressProvider) external initializer {
        // address provider
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);

        // fee 50 DPLOY
        fee = 50 ether;

        // fee ratio (50% to dev wallet, 50% to treasury)
        devFeeRatio = MULTIPLIER / 2;

        // init
        __Ownable_init();
    }

    /* ======== MODIFIERS ======== */

    modifier onlyManager() {
        if (msg.sender != addressProvider.getDegenopolyNodeManager())
            revert NOT_MANAGER();
        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();

        addressProvider = IAddressProvider(_addressProvider);

        emit AddressProvider(_addressProvider);
    }

    function setCases(Case[] calldata _cases) external onlyOwner {
        delete cases;

        numberOfCases = _cases.length;

        for (uint256 i = 0; i < numberOfCases; i++) {
            cases.push(_cases[i]);
        }
    }

    function setFee(uint256 _fee) external onlyOwner {
        if (_fee == 0) revert ZERO_AMOUNT();

        fee = _fee;

        emit Fee(_fee);
    }

    function setDevFeeRatio(uint256 _devFeeRatio) external onlyOwner {
        if (_devFeeRatio >= MULTIPLIER) revert INVALID_FEE_RATIO();

        devFeeRatio = _devFeeRatio;

        emit DevFeeRatio(_devFeeRatio);
    }

    /* ======== MANAGER FUNCTIONS ======== */

    function setNodeMinted(address _account) external onlyManager {
        mintableNode[_account] = address(0);
    }

    /* ======== PUBLIC FUNCTIONS ======== */

    function rollDice() external {
        if (lastEventTypeOf[msg.sender] != EventType.None)
            revert EXISTING_CHOICE();
        if (lastRollBlockOf[msg.sender] >= block.number) revert INVALID_ROLL();
        lastRollBlockOf[msg.sender] = block.number;

        // fee to move forward
        IERC20 degenopoly = IERC20(addressProvider.getDegenopoly());
        uint256 devFee = (fee * devFeeRatio) / MULTIPLIER;
        uint256 treasuryFee = fee - devFee;

        degenopoly.safeTransferFrom(msg.sender, address(this), devFee);
        degenopoly.safeTransferFrom(
            msg.sender,
            addressProvider.getTreasury(),
            treasuryFee
        );

        // reset mintable node
        if (mintableNode[msg.sender] != address(0)) {
            emit RejectMintableNode(msg.sender, mintableNode[msg.sender]);
            mintableNode[msg.sender] = address(0);
        }

        // roll dice
        uint256 dice = (block.prevrandao % 6) + 1;
        diceOf[msg.sender] = dice;

        // position
        bool passedStart = false;
        if (positionOf[msg.sender] + dice > numberOfCases)
            passedStart = true;
        
        uint256 position = (positionOf[msg.sender] + dice) % numberOfCases;
        positionOf[msg.sender] = position;

        // case
        Case memory nowCase = cases[position];

        // handle
        EventType eventType = _handleCase(msg.sender, nowCase, passedStart);

        // event
        emit RollDice(msg.sender, dice, position, nowCase, eventType);
    }

    function moveCase(uint256 _caseIndex) external {
        // CEX Choice
        if (lastEventTypeOf[msg.sender] != EventType.CEX)
            revert NO_CEX_CHOICE();
        lastEventTypeOf[msg.sender] = EventType.None;

        bool passedStart = false;
        if (positionOf[msg.sender] > _caseIndex)
            passedStart = true;

        // case
        Case memory nowCase = cases[_caseIndex];
        if (nowCase.caseType == CaseType.DevWallet) revert INVALID_CEX_CHOICE();
        
        positionOf[msg.sender] = _caseIndex;
        // handle
        EventType eventType = _handleCase(msg.sender, nowCase, passedStart);

        // event
        emit CEXChoice(msg.sender, nowCase, eventType);
    }

    function getFreeNode(address _node) external {
        // Airdrop Choice
        if (lastEventTypeOf[msg.sender] != EventType.Airdrop)
            revert NO_AIRDROP_CHOICE();
        lastEventTypeOf[msg.sender] = EventType.None;

        // mint
        IDegenopolyNode(_node).mint(msg.sender);

        // event
        emit AirdropChoice(msg.sender, _node);
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0)
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}('');
            require(success);
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getPlayboardCases() external view returns (Case[] memory) {
        return cases;
    }

    function getLastEventType(
        address _account
    ) external view returns (EventType) {
        return lastEventTypeOf[_account];
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _handleCase(
        address _account,
        Case memory _nowCase,
        bool _passedStart
    ) internal returns (EventType eventType) {
        IDegenopoly degenopoly = IDegenopoly(addressProvider.getDegenopoly());
        IDegenopolyNodeManager degenopolyNodeManager = IDegenopolyNodeManager(
            addressProvider.getDegenopolyNodeManager()
        );

        // Start Case: x1.05 (5%) bonus on your rewards
        if (_passedStart) {
            degenopolyNodeManager.addMultiplier(_account, 10500);
        }
        // Start Case: x1.05 (5%) bonus on your rewards
        else if (_nowCase.caseType == CaseType.Start) {
            degenopolyNodeManager.addMultiplier(_account, 10500);
        }
        // Event Cases
        else if (_nowCase.caseType == CaseType.Event) {
            uint256 randomEvent = (block.prevrandao / 6) % 100;

            // Bullish News (40% chance):  10% bonus on all your rewards
            if (randomEvent < 40) {
                lastEventTypeOf[_account] = EventType.Bullish;
                degenopolyNodeManager.addMultiplier(_account, 11000);
                eventType = EventType.Bullish;
            }
            // CEX Listing (30% chance): free to move to the case of your choice, except Dev Wallet
            else if (randomEvent < 70) {
                lastEventTypeOf[_account] = EventType.CEX;
                eventType = EventType.CEX;
            }
            // FUD Campaign (20% chance): 10% malus on your rewards
            else if (randomEvent < 90) {
                lastEventTypeOf[_account] = EventType.FUD;
                degenopolyNodeManager.addMultiplier(_account, 9000);
                eventType = EventType.FUD;
            }
            // Airdrop (5% chance): get one NFT of the dashboard for free
            else if (randomEvent < 95) {
                lastEventTypeOf[_account] = EventType.Airdrop;
                eventType = EventType.Airdrop;
            }
            // Jeet Shill (5% chance): 0.1%* of $DPOLY supply for free
            else {
                lastEventTypeOf[_account] = EventType.Jeet;
                degenopoly.mint(_account, degenopoly.totalSupply() / 1000);
                eventType = EventType.Jeet;
            }
        }
        // Dev Wallet: receive all $DPOLY that has been accumulated so fa
        else if (_nowCase.caseType == CaseType.DevWallet) {
            IERC20(address(degenopoly)).safeTransfer(
                _account,
                degenopoly.balanceOf(address(this))
            );
        }
        // NFT Case: mintable
        else {
            address node = abi.decode(_nowCase.info, (address));
            mintableNode[_account] = node;
        }
    }
}
