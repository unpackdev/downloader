// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./IVEGoMiningToken.sol";


contract MarketingVoting is PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for int256;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using ECDSAUpgradeable for bytes32;

    IVEGoMiningToken public veToken;

    struct Option {
        string name;
        bool active;
    }


    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant SNAPSHOTER_ROLE = keccak256("SNAPSHOTER_ROLE");
    bytes32 public constant PROXY_VOTER_ROLE = keccak256("PROXY_VOTER_ROLE");

    string public question;

    Option[] public options;
    uint256 public snapshotsCount;

    uint256 public optionsCount;

    mapping(uint256 => address[]) public optionVoters;
    mapping(uint256 => mapping(address => uint256)) public optionMapVoters;
    mapping(address => uint256) public votersOption;

    event GivenVote(address indexed account, uint256 indexed optionIndex);
    event RevokedVote(address indexed account, uint256 indexed optionIndex);
    event SnapshottedResult(uint256 indexed index, uint256[] votes);


    function initialize(address _veToken) initializer public {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_veToken != address(0), "MintReward: _veToken is zero address");
        veToken = IVEGoMiningToken(_veToken);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(CONFIGURATOR_ROLE, _msgSender());
        _grantRole(SNAPSHOTER_ROLE, _msgSender());
        _grantRole(PROXY_VOTER_ROLE, _msgSender());

        options.push(Option('', false));

    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // @notice set the main question
    // @param `_question` is question
    function setQuestion(string memory _question) external onlyRole(CONFIGURATOR_ROLE) {
        require(!_isStringEmpty(_question), "MarketingVoting: question is an empty string");

        question = _question;
    }

    // @notice Add an option
    // @param `_option` is an option of answers on question
    function addOption(string memory _option) external onlyRole(CONFIGURATOR_ROLE) {
        require(!_isStringEmpty(_option), "MarketingVoting: option is an empty string");

        Option memory option = Option(_option, true);
        options.push(option);
        optionsCount++;
    }


    // @notice Deactivate an option by name
    // @param `_option` is an option of answers on question
    function deactivateOption(uint256 index) external onlyRole(CONFIGURATOR_ROLE) {
        require(options[index].active, "MarketingVoting: option is not active");
        options[index].active = false;
    }


    function getOptions() external view returns (Option[] memory) {
        return options;
    }

    // @notice Get vote by account
    // @param `account` is an address
    function getVote(address account) public view returns (uint256) {
        uint256 index = votersOption[account];

        if (options[index].active) {
            return index;
        } else {
            return 0;
        }

    }

    // @notice Vote for option
    // @param `_option` is an option of answers on question
    function voteForOption(uint256 index) external nonReentrant {
        require(options[index].active, "MarketingVoting: option is not active");

        address account = _msgSender();
        require(getVote(account) == 0, "MarketingVoting: sender has already voted");
        require(veToken.balanceOf(account) > 0,  "MarketingVoting: sender doesn't have votes");

        _voteForOption(index, account);
    }

    function voteForOption(uint256 index, bytes memory signature, address account) external nonReentrant onlyRole(PROXY_VOTER_ROLE) {
        require(options[index].active, "MarketingVoting: option is not active");

        require(getVote(account) == 0, "MarketingVoting: sender has already voted");
        require(veToken.balanceOf(account) > 0,  "MarketingVoting: sender doesn't have votes");

        _isDataValid(index, signature, account);

        _voteForOption(index, account);
    }

    function _voteForOption(uint256 index, address account) internal {
        optionMapVoters[index][account] = optionVoters[index].length;
        optionVoters[index].push(account);
        votersOption[account] = index;

        emit GivenVote(account, index);
    }

    // @notice Revoke a vote
    // @param `_option` is an option of answers on question
    function revokeVote() external nonReentrant {

        address account = _msgSender();
        require(getVote(account) != 0, "MarketingVoting: sender has not voted yet");

        uint256 index = votersOption[account];
        delete votersOption[account];


        address[] memory _optionVoters = optionVoters[index];

        uint256 indexInOV = optionMapVoters[index][account];
        require(optionVoters[index][indexInOV] == account, "MarketingVoting: incorrect index");

        optionVoters[index][indexInOV] = _optionVoters[_optionVoters.length - 1];
        optionVoters[index].pop();

        delete optionMapVoters[index][account];

        emit RevokedVote(account, index);

    }

    function resetVotes() external onlyRole(CONFIGURATOR_ROLE) {
        for (uint256 i = 0; i <= optionsCount; i++) {
            address[] memory _optionVoters = optionVoters[i];
            for (uint256 j = 0; j < _optionVoters.length; j++) {
                address account = _optionVoters[j];

                delete votersOption[account];
            }

            delete optionVoters[i];
        }
    }

    // @notice Create snapshot of voting results
    // @param `_option` is an option of answers on question
    function createVoteSnapshot() external onlyRole(SNAPSHOTER_ROLE) {
        uint256[] memory results = new uint256[](options.length);

        for (uint256 i = 0; i < options.length; i++) {

            if (options[i].active) {
                address[] memory _optionVoters = optionVoters[i];
                uint256 votes;
                for (uint256 j = 0; j < _optionVoters.length; j++) {
                    address account = _optionVoters[j];
                    if (votersOption[account] == i) {
                        votes += veToken.balanceOf(account);
                    }
                }
                results[i] = votes;
            } else {
                results[i] = 0;
            }
        }
        emit SnapshottedResult(snapshotsCount, results);

        snapshotsCount++;
    }


    function getCurrentVoteResult() external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](options.length);

        for (uint256 i = 0; i < options.length; i++) {

            if (options[i].active) {
                address[] memory _optionVoters = optionVoters[i];
                uint256 votes;
                for (uint256 j = 0; j < _optionVoters.length; j++) {
                    address account = _optionVoters[j];
                    if (votersOption[account] == i) {
                        votes += veToken.balanceOf(account);
                    }
                }
                results[i] = votes;
            } else {
                results[i] = 0;
            }
        }

        return results;
    }


    function updateVeToken(address _veToken) external onlyRole(CONFIGURATOR_ROLE) whenPaused {
        require(_veToken != address(0), "MarketingVoting: veToken is zero address");
        veToken = IVEGoMiningToken(_veToken);
    }

    function _isStringEmpty(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        return strBytes.length == 0;
    }

    function _isValidSignature(bytes32 hash, bytes memory signature, address account) internal pure returns (bool) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == account;
    }

    function _isDataValid(uint256 index, bytes memory signature, address account) internal view {
        // Build the hash and check the sig
        // We only accept sigs from the system
        bytes32 msgHash = keccak256(abi.encodePacked(account, index));
        require(
            _isValidSignature(msgHash, signature, account),
            "MarketingVoting: invalid signature"
        );
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

}
