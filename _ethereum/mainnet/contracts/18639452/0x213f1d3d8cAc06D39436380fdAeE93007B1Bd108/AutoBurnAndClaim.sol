// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20;

import "./ERC20.sol";

// Gelato Dependency
import "./OpsProxy.sol";
import "./OpsProxyFactory.sol";

// Synthetix Dependency
import "./AddressResolver.sol";
import "./DelegateApprovals.sol";
import "./FeePool.sol";
import "./Issuer.sol";
import "./Synthetix.sol";
import "./SystemSettings.sol";

contract AutoBurnAndClaim {
    bytes32 private constant DELEGATE_APPROVALS = "DelegateApprovals";
    bytes32 private constant SYSTEM_SETTINGS = "SystemSettings";
    bytes32 private constant FEE_POOL = "FeePool";
    bytes32 private constant ISSUER = "Issuer";
    bytes32 private constant SUSD_PROXY = "ProxyERC20sUSD";
    bytes32 private constant SYNTHETIX = "Synthetix";

    AddressResolver immutable SNXAddressResolver;
    OpsProxyFactory private constant OPS_PROXY_FACTORY =
        OpsProxyFactory(0xC815dB16D4be6ddf2685C201937905aBf338F5D7);
    DelegateApprovals private delegateApprovals;
    FeePool private feePool;
    Issuer private issuer;
    ERC20 private sUSD;
    SystemSettings private systemSettings;
    address private SNX;

    mapping(address => uint256) public baseFee;

    error ZeroAddressResolved(bytes32 name);

    constructor(address _SNXAddressResolver) {
        SNXAddressResolver = AddressResolver(_SNXAddressResolver);
        _rebuildCaches();
    }

    function checker(
        address _account
    ) external view returns (bool, bytes memory execPayload) {
        (address dedicatedMsgSender, ) = OPS_PROXY_FACTORY.getProxyOf(_account);

        // first off, check gas price
        uint256 _gasPrice = baseFee[_account];
        if(_gasPrice != 0 && block.basefee > _gasPrice) {
            return (false, "basefee too high");
        }

        //second, check claim permission
        if(!delegateApprovals.canClaimFor(_account, dedicatedMsgSender) ) {
            return (false, "no claim permission for gelato");
        }

        //third, is reward avaliable to claim?
        (uint256 fee, uint256 SNXRewards) = feePool.feesAvailable(_account);
        if((fee + SNXRewards) == 0 && feePool.totalRewardsAvailable() == 0) {
            return (false, "no reward avaliable");
        }

        // forth, check burn permission and if need to burn
        uint256 issuanceRatio = systemSettings.issuanceRatio();
        uint256 cRatio = issuer.collateralisationRatio(_account);

        address[] memory targets;
        bytes[] memory datas;
        uint256[] memory values;

        if(cRatio > issuanceRatio) {
            uint256 threshold = 1e18 + systemSettings.targetThreshold();
            uint256 issuanceAdjusted = issuanceRatio * threshold / 1e18;
            if(cRatio > issuanceAdjusted) {
                bool burnPerms = delegateApprovals.canBurnFor(_account, dedicatedMsgSender);
                if(!burnPerms) {
                    return (false, "no burn permission and c-ratio too low");
                }
                else {
                    uint256 debtBalance = issuer.debtBalanceOf(_account, "sUSD");
                    uint256 maxIssuable = issuer.maxIssuableSynths(_account);
                    uint256 burnAmount = debtBalance - maxIssuable;
                    uint256 sUSDBalance = sUSD.balanceOf(_account);
                    if(sUSDBalance < burnAmount) {
                        return (false, "not enough sUSD to fix c-ratio");
                    }
                    else {
                        targets = new address[](2);
                        datas = new bytes[](2);
                        values = new uint256[](2);
                        targets[0] = SNX;
                        targets[1] = address(feePool);
                        datas[0] = abi.encodeWithSelector(Synthetix.burnSynthsToTargetOnBehalf.selector, _account);
                        datas[1] = abi.encodeWithSelector(feePool.claimOnBehalf.selector, _account);
                        values[0] = 0;
                        values[1] = 0;
                        return (true, 
                            abi.encodeWithSelector(
                                OpsProxy.batchExecuteCall.selector, 
                                targets,
                                datas,
                                values));
                    }
                }
            }
        }

        targets = new address[](1);
        datas = new bytes[](1);
        values = new uint256[](1);
        targets[0] = address(feePool);
        datas[0] = abi.encodeWithSelector(feePool.claimOnBehalf.selector, _account);
        // values[0] = 0;
        return (true,
                abi.encodeWithSelector(
                    OpsProxy.batchExecuteCall.selector,
                    targets,
                    datas,
                    values
                    )
            );
    }

    function setBaseFee(uint256 _baseFee) external {
        baseFee[msg.sender] = _baseFee;
    }

    function rebuildCaches() external {
        _rebuildCaches();
    }

    function _rebuildCaches() internal {
        feePool = FeePool(getAddress(FEE_POOL));
        delegateApprovals = DelegateApprovals(getAddress(DELEGATE_APPROVALS));
        systemSettings = SystemSettings(getAddress(SYSTEM_SETTINGS));
        issuer = Issuer(getAddress(ISSUER));
        SNX = getAddress(SYNTHETIX);
        sUSD = ERC20(getAddress(SUSD_PROXY));
    }

    function getAddress(bytes32 name) internal view returns (address) {
        address resolved = SNXAddressResolver.getAddress(name);
        if (resolved == address(0)) {
            revert ZeroAddressResolved(name);
        }
        return resolved;
    }
}