// SPDX-License-Identifier: UNLICENSED
// Modified from https://github.com/gelatodigital/w3f-solidity-synthetix

pragma solidity ^0.8.20;

import "./AddressResolver.sol";
import "./DelegateApprovals.sol";
import "./OpsProxyFactory.sol";
import "./Synthetix.sol";
import "./SystemSettings.sol";

contract MaxMint {
    // @notice Configuration for minting
    // @custom:mode 0 for disabled, 1 for using C-ratio, 2 for using minimum issued sUSD
    // @custom:minimumCRatio C-ratio to mint, in form of WAD (1e18) and as debt/collateral (1/n from the UI)
    // @custom:minimumIssuedsUSD minimum sUSD before it can be minted, in form of WAD
    struct Configuation {
        uint8 mode;
        uint120 minimumCRatio;
        uint120 minimumIssuedsUSD;
    }

    // @notice: Name of Synthetix contracts to resolve

    bytes32 private constant SYNTHETIX = "Synthetix";
    bytes32 private constant DELEGATE_APPROVALS = "DelegateApprovals";
    bytes32 private constant SYSTEM_SETTINGS = "SystemSettings";

    AddressResolver immutable SNXAddressResolver;
    OpsProxyFactory private constant OPS_PROXY_FACTORY =
        OpsProxyFactory(0xC815dB16D4be6ddf2685C201937905aBf338F5D7);
    DelegateApprovals private delegateApprovals;
    Synthetix private SNX;
    SystemSettings private systemSettings;

    mapping(address _account => Configuation) public config;

    error ZeroAddressResolved(bytes32 name);
    error InvalidConfig();

    constructor(address _SNXAddressResolver) {
        SNXAddressResolver = AddressResolver(_SNXAddressResolver);
        _rebuildCaches();
    }

    function checker(
        address _account
    ) external view returns (bool, bytes memory execPayload) {
        (address dedicatedMsgSender, ) = OPS_PROXY_FACTORY.getProxyOf(_account);

        uint256 cRatio = SNX.collateralisationRatio(_account);
        uint256 issuanceRatio = systemSettings.issuanceRatio();
        Configuation memory currentConfig = config[_account];

        if (currentConfig.mode == 0) {
            execPayload = bytes("Disabled");
            return (false, execPayload);
        }

        else if (currentConfig.mode == 1) {
            if (cRatio >= currentConfig.minimumCRatio || currentConfig.minimumCRatio > issuanceRatio) {
                execPayload = bytes("C-Ratio is lower than set threshold");
                return (false, execPayload);
            }
        }
        else if (currentConfig.mode == 2) {
            (uint256 maxIssuable,, ) = SNX.remainingIssuableSynths(_account);
            if(maxIssuable == 0) {
                execPayload = bytes("Account already below max issuable");
                return (false, execPayload);
            }
            else if(currentConfig.minimumIssuedsUSD > maxIssuable) {
                execPayload = bytes("sUSD avaliable is lower than set threshold");
                return (false, execPayload);
            }
        }

        if (!delegateApprovals.canIssueFor(_account, dedicatedMsgSender)) {
            execPayload = bytes("Not approved for issuing");
            return (false, execPayload);
        }

        execPayload = abi.encodeWithSelector(
            SNX.issueMaxSynthsOnBehalf.selector,
            _account
        );

        return (true, execPayload);
    }

    function setConfig(Configuation calldata _config) external {
        if(_config.mode > 2) revert InvalidConfig();
        config[msg.sender] = _config;
    }

    function rebuildCaches() external {
        _rebuildCaches();
    }

    function _rebuildCaches() internal {
        SNX = Synthetix(getAddress(SYNTHETIX));
        delegateApprovals = DelegateApprovals(getAddress(DELEGATE_APPROVALS));
        systemSettings = SystemSettings(getAddress(SYSTEM_SETTINGS));
    }

    function getAddress(bytes32 name) internal view returns (address) {
        address resolved = SNXAddressResolver.getAddress(name);
        if (resolved == address(0)) {
            revert ZeroAddressResolved(name);
        }
        return resolved;
    }
}
