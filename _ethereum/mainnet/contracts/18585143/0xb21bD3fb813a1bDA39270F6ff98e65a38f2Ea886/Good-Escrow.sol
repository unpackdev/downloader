// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ITreasury.sol";
import "./ReentrancyGuardUpgradeable.sol";


contract GoodEscrow is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public treasuryContractAddress;

    uint256 public allowancePerHour;
    mapping(address => uint256) private _deposits;

    event ReceivedEther(address payer, uint amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    event UpdatedTreasuryAddress(address treasuryAddress);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event EmergencyFundWithdrawn(address token, address to, uint256 weiAmount);
    event UpdatedAllowancePerHour(uint256 weiAllowance);
    event UpdatedVolunteerAllowance(
        address payee,
        uint256 hoursCompleted,
        uint256 weiAmount
    );

    modifier isAdmin() {
        require(
            TreasuryContract(treasuryContractAddress).isAdmin(_msgSender()),
            "Not authorized"
        );
        _;
    }

    modifier isVolunteerAdmin() {
        require(
            TreasuryContract(treasuryContractAddress).isVolunteerAdmin(
                _msgSender()
            ),
            "Not authorized"
        );
        _;
    }

    function initialize(
        address _treasuryContractAddress,
        uint256 _allowancePerHour
    ) public initializer {
        _updateTreasuryAddress(_treasuryContractAddress);
        _updateAllowancePerHour(_allowancePerHour);
    }

    function withdrawalAmountFor(
        address volunteer
    ) public view returns (uint256) {
        return _deposits[volunteer];
    }

    function updateVolunteerAllowance(
        address _volunteer,
        uint256 _hoursCompleted
    ) external isVolunteerAdmin {
        require(
            _volunteer != address(0),
            "GoodEscrow: Address zero not allowed"
        );
        require(
            _hoursCompleted > 0,
            "GoodEscrow: hours should be greater than 0"
        );
        uint256 totalAllowance = _hoursCompleted * allowancePerHour;
        _deposits[_volunteer] += totalAllowance;
        emit UpdatedVolunteerAllowance(
            _volunteer,
            _hoursCompleted,
            totalAllowance
        );
    }

    function withdraw(uint256 _amount) external nonReentrant{
        uint256 amountAvailable = _deposits[_msgSender()];
        require(
            (_amount > 0) &&
                (amountAvailable > 0) &&
                (_amount <= amountAvailable),
            "GoodEscrow: Invalid withdraw amount"
        );
        _deposits[_msgSender()] -= _amount;
        bool withdrawStatus = _sendEthersTo(_msgSender(), _amount);
        require(withdrawStatus, "GoodEscrow: withdraw send failed");
        emit Withdrawn(_msgSender(), _amount);
    }

    function EmergencyWithdrawFunds(
        address _tokenAddress,
        address payable _to,
        uint _amount
    ) external isAdmin nonReentrant{
        require(
            (_to != address(0)),
            "GoodEscrow: address zero not allowed"
        );
        uint256 amount;
        if (_tokenAddress == address(0)) {
            uint256 balance = address(this).balance;
            amount = _amount == 0 ? balance : _amount;
            bool sent = _sendEthersTo(_to, amount);
            require(sent, "GoodNFTMarket: Failed to send Ether");
        } else {
            uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(
                address(this)
            );
            amount = _amount == 0 ? balance : _amount;
            require(balance > 0, "GoodNFTMarket: Insufficient balance");
            IERC20Upgradeable(_tokenAddress).safeTransfer(_to, amount);
        }
        emit EmergencyFundWithdrawn(_tokenAddress, _to, amount);
    }

    /**
     * @notice Provides functionality to update treasury contract address,caller must have Admin role .
     * @param   _treasuryContractAddress  .
     */
    function updateTreasuryAddress(
        address _treasuryContractAddress
    ) external isAdmin {
        require(
            _treasuryContractAddress != address(0),
            "GoodEscrow: address zero"
        );
        _updateTreasuryAddress(_treasuryContractAddress);
    }

    function updateAllowancePerHour(uint256 _newAllowance) external isAdmin {
        _updateAllowancePerHour(_newAllowance);
    }

    /**
     * @notice Internal function to send given amount of ethers to provided receiver address
     * @param _receiver .
     * @param _amount .
     */
    function _sendEthersTo(
        address _receiver,
        uint256 _amount
    ) internal returns (bool) {
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        return sent;
    }

    function _updateTreasuryAddress(address _treasuryContractAddress) internal {
        treasuryContractAddress = _treasuryContractAddress;
        emit UpdatedTreasuryAddress(_treasuryContractAddress);
    }

    function _updateAllowancePerHour(uint256 _newAllowance) internal {
        require(
            _newAllowance > 0,
            "GoodEscrow: Allowance should be greater than 0"
        );
        allowancePerHour = _newAllowance;
        emit UpdatedAllowancePerHour(_newAllowance);
    }

    /**
     * @dev Receive function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }

    /**
     * @notice  Upgrades the contracts by adding new implementation contract,caller needs to have Admin role .
     * @param   newImplementation  .
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override isAdmin {}
}
