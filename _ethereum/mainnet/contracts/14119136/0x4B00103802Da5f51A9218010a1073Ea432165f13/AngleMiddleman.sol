// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IAngleDistributor.sol";
import "./IAngleMiddlemanGauge.sol";

interface ICurveGauge {
    function deposit_reward_token(address _reward_token, uint256 _amount) external; // solhint-disable-line
}

interface IPolygonBridge {
    function depositFor(
        address user,
        address rootToken,
        bytes memory depositData
    ) external;

    function tokenToType(address) external view returns (bytes32);

    function typeToPredicate(bytes32) external view returns (address);
}

contract AngleMiddleman is AccessControl, IAngleMiddlemanGauge {
    using SafeERC20 for IERC20;

    /// @notice Types of contracts the middleman will forward the tokens to
    enum RecipientType {
        Curve,
        Anyswap,
        PolygonPoS
    }

    /// @notice `recipient`: Address receiving the tokens. bridge: address of the bridge (if applicable) where the tokens will go through
    struct Recipient {
        address recipient;
        address bridge;
        RecipientType recipientType;
    }

    /// @notice Most likely ANGLE token (currently: 0x31429d1856aD1377A8A0079410B297e1a9e214c2)
    IERC20 public immutable rewardToken;
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Maps a gauge address (as defined in `AngleDistributor`) to its parameters
    mapping(address => Recipient) public gaugeToRecipient;

    event AddGauge(
        address indexed gauge,
        address indexed recipient,
        address indexed bridge,
        RecipientType recipientType
    );
    event RemoveGauge(address indexed gauge);
    event NotifyReward(address indexed gauge, address indexed recipient, uint256 amount);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);

    /// @notice Deploys `AngleMiddleman` used to route reward tokens (ANGLE) from `AngleDistributor` to gauges
    /// @param guardians array of address of admins for this contract. Guardians are allowed to add new gauges or remove them, and recover tokens from the contract
    /// @param distributor address of `AngleDistributor`. Notifies the contract that new rewards should be distributed
    constructor(address[] memory guardians, IAngleDistributor distributor) {
        require(address(distributor) != address(0), "0");
        require(guardians.length > 0, "5");

        rewardToken = distributor.rewardToken();

        for (uint256 i = 0; i < guardians.length; i++) {
            require(guardians[i] != address(0), "0");
            _setupRole(GUARDIAN_ROLE, guardians[i]);
        }

        _setupRole(DISTRIBUTOR_ROLE, address(distributor));
        _setRoleAdmin(DISTRIBUTOR_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
    }

    receive() external payable {}

    /// @notice Allows the Governor to add new gauges of type "Curve"
    /// @param gauges Array of gauges, as defined in `AngleDistributor`
    /// @param recipients Array of addresses ultimately meant to receive the tokens
    /// @param bridges Array of addresses of the bridging contracts
    /// @param recipientType Curve, Polygon or Anyswap
    /// @dev Addresses of gauges within the Angle Protocol corresponding to Curve pools or multichain staking contracts are identifiers to be used only for voting purposes.
    /// @dev This is the reason we map them to the "real" `recipient` contract
    function addGauges(
        address[] memory gauges,
        address[] memory recipients,
        address[] memory bridges,
        RecipientType[] memory recipientType
    ) external onlyRole(GUARDIAN_ROLE) {
        require(gauges.length > 0, "5");
        require(
            gauges.length == recipients.length &&
                gauges.length == bridges.length &&
                gauges.length == recipientType.length,
            "104"
        );

        for (uint256 i = 0; i < gauges.length; i++) {
            require(gauges[i] != address(0) && recipients[i] != address(0), "0");

            if (recipientType[i] == RecipientType.Curve) {
                require(bridges[i] == address(0), "113");
            }
            if (recipientType[i] == RecipientType.PolygonPoS || recipientType[i] == RecipientType.Anyswap) {
                require(bridges[i] != address(0), "0");
            }

            Recipient storage _recipient = gaugeToRecipient[gauges[i]];
            require(_recipient.recipient == address(0), "112");

            _recipient.recipient = recipients[i];
            _recipient.recipientType = recipientType[i];
            _recipient.bridge = bridges[i];

            // auto approve
            if (recipientType[i] == RecipientType.Curve) {
                rewardToken.safeApprove(recipients[i], type(uint256).max);
            } else if (recipientType[i] == RecipientType.PolygonPoS) {
                address spender = _getSpenderPolygon(bridges[i]);
                uint256 currentAllowance = rewardToken.allowance(address(this), spender);
                // the spender is the "predicate", so we check if it wasnt already approved
                if (currentAllowance == 0) {
                    rewardToken.safeApprove(spender, type(uint256).max);
                }
            }

            emit AddGauge(gauges[i], recipients[i], bridges[i], recipientType[i]);
        }
    }

    /// @notice Gets the address of the "predicate": the contract ultimately holding the tokens on mainnet. The predicate contract needs to be approved by `AngleMiddleman`
    /// @param bridge Address of the bridge contract, from there we can retrieve the address of the predicate
    function _getSpenderPolygon(address bridge) internal view returns (address spender) {
        bytes32 tokenType = IPolygonBridge(bridge).tokenToType(address(rewardToken));
        spender = IPolygonBridge(bridge).typeToPredicate(tokenType);
    }

    /// @notice Sends the tokens to the recipient contract using the appropriate method (direct transfer or bridging)
    /// @param gauge Address of the gauge, as defined in `AngleDistributor`
    /// @param amount Amount of tokens to be sent
    function notifyReward(address gauge, uint256 amount) external override onlyRole(DISTRIBUTOR_ROLE) {
        Recipient memory _recipient = gaugeToRecipient[gauge];
        require(_recipient.recipient != address(0), "110");

        if (_recipient.recipientType == RecipientType.Curve) {
            // Curve gauges implement a `deposit_reward_token` method
            // The contract needs to be approved for the rewardToken
            // Approval should have been done in `addGauges` method
            ICurveGauge(_recipient.recipient).deposit_reward_token(address(rewardToken), amount);
        } else if (_recipient.recipientType == RecipientType.PolygonPoS) {
            // Polygon PoS bridge uses a `depositFor` method
            // `depositFor` transfers the tokens to the "predicate" contract and then emits an event for bridging the tokens
            // The "predicate" needs to be approved, which is done in the `addGauges` method
            IPolygonBridge(_recipient.bridge).depositFor(
                _recipient.recipient,
                address(rewardToken),
                abi.encodePacked(amount)
            );
        } else if (_recipient.recipientType == RecipientType.Anyswap) {
            // For Anyswap, tokens just need to be transfered to the right contract and are bridged to the same address on the other network
            rewardToken.safeTransfer(_recipient.bridge, amount);
        }

        emit NotifyReward(gauge, _recipient.recipient, amount);
    }

    /// @notice Ability to revoke approval for a contract. Approvals are given in the `addGauges` methods
    /// @param spender Address of the contract that was approved
    function revokeApproval(address spender) public onlyRole(GUARDIAN_ROLE) {
        rewardToken.safeApprove(spender, 0);
    }

    /// @notice Ability to change allowance for a contract. Approvals are given in the `addGauges` methods
    /// @param spender Address of the contract that was approved
    /// @param approvedAmount Amount that we want to approve
    function changeAllowance(address spender, uint256 approvedAmount) public onlyRole(GUARDIAN_ROLE) {
        uint256 currentAllowance = rewardToken.allowance(address(this), spender);
        if (currentAllowance < approvedAmount) {
            rewardToken.safeIncreaseAllowance(spender, approvedAmount - currentAllowance);
        } else if (currentAllowance > approvedAmount) {
            rewardToken.safeDecreaseAllowance(spender, currentAllowance - approvedAmount);
        }
    }

    /// @notice Deletes a gauge. Removes the parameters from `gaugeToRecipient` and revokes approvals
    /// @param gauge Address of the gauge (found in `AngleDistributor`)
    function removeGauge(address gauge) external onlyRole(GUARDIAN_ROLE) {
        Recipient memory _recipient = gaugeToRecipient[gauge];
        require(_recipient.recipient != address(0), "110");
        if (_recipient.recipientType == RecipientType.Curve) {
            revokeApproval(_recipient.recipient);
        } else if (_recipient.recipientType == RecipientType.PolygonPoS) {
            revokeApproval(_getSpenderPolygon(_recipient.bridge));
        }
        // else: There is no approval for Anyswap, so no need to do anything

        delete gaugeToRecipient[gauge];
        emit RemoveGauge(gauge);
    }

    /// @notice Recovers ERC20 tokens from the contract
    /// @param token Address of the token
    /// @param amount Amount to be recovered
    function recoverERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(GUARDIAN_ROLE) {
        IERC20(token).safeTransfer(to, amount);
        emit Recovered(token, to, amount);
    }

    /// @notice Recovers ETH from the contract
    /// @param amount Amount to be recovered
    function recoverETH(address to, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        require(payable(to).send(amount), "98");
        emit Recovered(address(0), to, amount);
    }
}
