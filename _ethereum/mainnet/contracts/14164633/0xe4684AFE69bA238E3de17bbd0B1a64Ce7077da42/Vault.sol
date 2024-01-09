// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

/**
 * @title Vault Contract
 */
contract Vault is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    /// @notice Event emitted on construction.
    event VaultDeployed();

    /// @notice Event emitted when new teller is added to vault.
    event NewTellerAdded(address newTeller, uint256 priority);

    /// @notice Event emitted when current priority is changed.
    event TellerPriorityChanged(address teller, uint256 newPriority);

    /// @notice Event emitted when tokens are paid to provider.
    event ProviderPaid(address indexed provider, uint256 indexed vidyaAmount);

    /// @notice Event emitted when token rate is calculated.
    event VidyaRateCalculated(uint256 vidyaRate);

    IERC20 public Vidya;

    mapping(address => bool) public teller;
    mapping(address => uint256) public tellerPriority;
    mapping(address => uint256) public priorityFreeze;

    uint256 public totalPriority;
    uint256 public vidyaRate;
    uint256 public timeToCalculateRate;
    uint256 public totalDistributed;

    modifier onlyTeller() {
        require(teller[msg.sender], "Vault: Caller is not a teller.");
        _;
    }

    /**
     * @dev Constructor function
     * @param _Vidya Interface of Vidya token => 0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30
     */
    constructor(IERC20 _Vidya) {
        Vidya = _Vidya;

        emit VaultDeployed();
    }

    /**
     * @dev External function to add a teller. This function can be called only by the owner.
     * @param _teller Address of teller
     * @param _priority Priority of teller
     */
    function addTeller(address _teller, uint256 _priority) external onlyOwner {
        require(
            _teller.isContract() == true,
            "Vault: Address is not a contract."
        );
        require(!teller[_teller], "Vault: Caller is already a teller.");
        require(_priority > 0, "Vault: Priority should be greater than zero.");

        teller[_teller] = true;
        tellerPriority[_teller] = _priority;
        totalPriority += _priority;
        priorityFreeze[_teller] = block.timestamp + 7 days;

        emit NewTellerAdded(_teller, _priority);
    }

    /**
     * @dev External function to change the priority of a teller. This function can be called only by the owner.
     * @param _teller Address of teller
     * @param _newPriority New priority of teller
     */
    function changePriority(address _teller, uint256 _newPriority)
        external
        onlyOwner
    {
        require(
            _teller.isContract() == true,
            "Vault: Address is not a contract."
        );
        require(teller[_teller], "Vault: Provided address is not a teller.");
        require(
            priorityFreeze[_teller] <= block.timestamp,
            "Vault: Priority freeze is still in effect."
        );

        uint256 _oldPriority = tellerPriority[_teller];
        totalPriority = (totalPriority - _oldPriority) + _newPriority;
        tellerPriority[_teller] = _newPriority;

        priorityFreeze[_teller] = block.timestamp + 1 weeks;

        emit TellerPriorityChanged(_teller, _newPriority);
    }

    /**
     * @dev External function to pay depositors. This function can be called only by a teller.
     * @param _provider Address of provider
     * @param _providerTimeWeight Weight time of provider
     * @param _totalWeight Sum of provider weight
     */
    function payProvider(
        address _provider,
        uint256 _providerTimeWeight,
        uint256 _totalWeight
    ) external onlyTeller {
        uint256 numerator = vidyaRate *
            _providerTimeWeight *
            tellerPriority[msg.sender];
        uint256 denominator = _totalWeight * totalPriority;

        uint256 amount;
        if (denominator != 0) {
            amount = numerator / denominator;
        }

        if (timeToCalculateRate <= block.timestamp) {
            _calculateRate();
        }
        totalDistributed += amount;
        Vidya.safeTransfer(_provider, amount);

        emit ProviderPaid(_provider, amount);
    }

    /**
     * @dev Internal function to calculate the token Rate.
     */
    function _calculateRate() internal {
        vidyaRate = Vidya.balanceOf(address(this)) / 26 weeks; // 6 months
        timeToCalculateRate = block.timestamp + 1 weeks;

        emit VidyaRateCalculated(vidyaRate);
    }

    /**
     * @dev External function to calculate the token Rate.
     */
    function calculateRate() external nonReentrant {
        require(
            timeToCalculateRate <= block.timestamp,
            "Vault: Rate calculation not yet possible."
        );
        _calculateRate();
    }
}