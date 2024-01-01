// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./PausableUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";
import {SafeERC20Upgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "./IConnext.sol";

contract Bridge is Initializable, Ownable2StepUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    error InvalidBridgeType();
    error BridgeContractNotSet(BridgeType _bridgeType);
    error DestinationChainNotSupported(uint32 _destinationChainId);
    error FeeOutOfBounds(uint32 _fee);
    error LengthsMustMatch(uint256 _length1, uint256 _length2);

    uint32 public fee;

    enum BridgeType {Connext}

    mapping(BridgeType => address) public bridges;

    mapping(uint32 => uint32) public connextChainIdToDomain;

    function initialize(
        uint32 _fee, // BPS, i.e. 40 = 0.4%
        BridgeType[] calldata _bridgeTypes,
        address[] calldata _bridges
    ) public initializer {
        __Pausable_init();
        __Ownable2Step_init();
        __ReentrancyGuard_init();
        if (_fee > 10000) revert FeeOutOfBounds(_fee);
        fee = _fee;
        if (_bridgeTypes.length != _bridges.length) revert LengthsMustMatch(_bridgeTypes.length, _bridges.length);
        for (uint256 i = 0; i < _bridgeTypes.length; i++) {
            bridges[_bridgeTypes[i]] = _bridges[i];
        }

        uint32[] memory chains = new uint32[](6);
        chains[0] = 1;
        chains[1] = 10;
        chains[2] = 56;
        chains[3] = 100;
        chains[4] = 137;
        chains[5] = 42161;

        uint32[] memory domains = new uint32[](6);
        domains[0] = 6648936;
        domains[1] = 1869640809;
        domains[2] = 6450786;
        domains[3] = 6778479;
        domains[4] = 1886350457;
        domains[5] = 1634886255;

        setDomains(chains, domains);
    }

    // ADMIN FUNCTIONS
    function setFee(uint32 _fee) external onlyOwner {
        if (_fee < 0 || _fee > 10000) revert FeeOutOfBounds(_fee);
        fee = _fee;
    }

    function setBridge(BridgeType _bridgeType, address _bridge) external onlyOwner {
        bridges[_bridgeType] = _bridge;
    }

    function setDomains(uint32[] memory _chainId, uint32[] memory _connextDomain) public onlyOwner {
        if (_chainId.length != _connextDomain.length) revert LengthsMustMatch(_chainId.length, _connextDomain.length);
        for (uint256 i = 0; i < _chainId.length; i++) {
            connextChainIdToDomain[_chainId[i]] = _connextDomain[i];
        }
    }

    function withdraw(address _token, address _recipient, uint256 _amount) external nonReentrant onlyOwner {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _recipient, _amount);
    }

    // EXTERNAL FUNCTIONS
    function sendThroughBridge(
        address _token,
        address _recipient,
        uint32 _destinationChainId,
        uint256 _amount,
        bytes calldata _data,
        BridgeType _bridgeType,
        bytes calldata _extraData
    ) external payable whenNotPaused {
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_token), msg.sender, address(this), _amount);
        uint256 _amountAfterFee = _amount - ((_amount * fee) / (10000));
        // example: 100 * 40 * 1000 / (10000 * 1000) = .4

        if (_bridgeType == BridgeType.Connext) {
            _sendThroughConnext(_token, _recipient, _destinationChainId, _amountAfterFee, _data, _extraData);
        } else {
            revert InvalidBridgeType();
        }
    }

    // INTERNAL FUNCTIONS
    function _sendThroughConnext(
        address _token,
        address _recipient,
        uint32 _destinationChainId,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _extraData
    ) internal {
        if (bridges[BridgeType.Connext] == address(0)) {
            revert BridgeContractNotSet(BridgeType.Connext);
        }
        if (connextChainIdToDomain[_destinationChainId] == 0) {
            revert DestinationChainNotSupported(_destinationChainId);
        }
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_token), bridges[BridgeType.Connext], _amount);
        (address _delegate, uint256 _slippage) = abi.decode(_extraData, (address, uint256));
        IConnext(bridges[BridgeType.Connext]).xcall{value: msg.value}(
            connextChainIdToDomain[_destinationChainId], _recipient, _token, _delegate, _amount, _slippage, _data
        );
    }

    // ============ Upgrade Gap ============
    uint256[49] private __GAP; // gap for upgrade safety
}
