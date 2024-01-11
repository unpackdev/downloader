// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox.fi, 2021
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC20.sol";

import "./AddressProvider.sol";
import "./ContractsRegister.sol";
import "./ACL.sol";

import "./DieselToken.sol";
import "./LinearInterestRateModel.sol";
import "./PoolService.sol";
import "./CreditManager.sol";
import "./ICreditFilter.sol";
import "./Errors.sol";

contract GIP678 is Ownable {
    address constant ADDRESS_PROVIDER =
        0xcF64698AFF7E5f27A11dff868AF228653ba53be0;

    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    address constant FTM = 0x4E15361FD6b4BB609Fa63C81A2be19d873717870;
    address constant LUNA = 0xd2877702675e6cEb975b4A1dFf9fb7BAF4C91ea9;

    struct AllowedToken {
        address token;
        uint256 liquidationThreshold;
    }

    struct CreditLimit {
        address creditManager;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 poolLimit;
    }

    AddressProvider public addressProvider;
    address public immutable root;

    constructor() {
        addressProvider = AddressProvider(ADDRESS_PROVIDER);

        root = ACL(addressProvider.getACL()).owner();
    }

    function configure() external onlyOwner {
        ACL acl = ACL(addressProvider.getACL());
        ContractsRegister cr = ContractsRegister(
            addressProvider.getContractsRegister()
        );

        AllowedToken[] memory tokens = new AllowedToken[](5);

        tokens[0] = AllowedToken( { token: CRV, liquidationThreshold: 7750 });
        tokens[1] = AllowedToken( { token: SUSHI, liquidationThreshold: 7750 });
        tokens[2] = AllowedToken( { token: LDO, liquidationThreshold: 7500 });
        tokens[3] = AllowedToken( { token: FTM, liquidationThreshold: 7250 });
        tokens[4] = AllowedToken( { token: LUNA, liquidationThreshold: 7250 });


        uint256 cmLen = cr.getCreditManagersCount();
        uint256 tokenLen = tokens.length;

        for (uint256 j; j < tokenLen; j++) {
            for (uint256 i; i < cmLen; i++) {
                ICreditFilter cf = CreditManager(cr.creditManagers(i))
                    .creditFilter();
                cf.allowToken(tokens[j].token, tokens[j].liquidationThreshold);
            }
        }

        CreditLimit[] memory limits = new CreditLimit[](4);

        // CreditManager DAI
        limits[0] = CreditLimit({
            creditManager: 0x777E23A2AcB2fCbB35f6ccF98272d03C722Ba6EB,
            minAmount: 1000*10**18,
            maxAmount: 125000*10**18,
            poolLimit: 6* 10**6 * 10**18
        });

        // CreditManager USDC
        limits[1] = CreditLimit({
            creditManager: 0x2664cc24CBAd28749B3Dd6fC97A6B402484De527,
            minAmount: 1000*10**6,
            maxAmount: 125000 * 10**6,
            poolLimit: 6*10**6 * 10**6
        });

        // CreditManager WETH
        limits[2] = CreditLimit({
            creditManager: 0x968f9a68a98819E2e6Bb910466e191A7b6cf02F0,
            minAmount: 3 * 10**17,
            maxAmount: 125* 10**18,
            poolLimit: 1200 * 10**18
        });

        // CreditManager WBTC
        limits[3] = CreditLimit({
            creditManager: 0xC38478B0A4bAFE964C3526EEFF534d70E1E09017,
            minAmount: 2 * 10**6,
            maxAmount: 10 * 10**8,
            poolLimit: 100 * 10**8
        });

        cmLen = limits.length;

        for (uint256 i = 0; i < cmLen; i++) {
            CreditManager cm = CreditManager(limits[i].creditManager);
            // function setParams(
            //     uint256 _minAmount,
            //     uint256 _maxAmount,
            //     uint256 _maxLeverageFactor,
            //     uint256 _feeInterest,
            //     uint256 _feeLiquidation,
            //     uint256 _liquidationDiscount
            // )
            cm.setParams(
                limits[i].minAmount,
                limits[i].maxAmount,
                cm.maxLeverageFactor(),
                cm.feeInterest(),
                cm.feeLiquidation(),
                cm.liquidationDiscount()
            );

            PoolService ps = PoolService(cm.poolService());
            ps.setExpectedLiquidityLimit(limits[i].poolLimit);
        }

        acl.transferOwnership(root); // T:[PD-2]
    }

    // Will be used in case of configure() revert
    function getRootBack() external onlyOwner {
        ACL acl = ACL(addressProvider.getACL()); // T:[PD-3]
        acl.transferOwnership(root);
    }

    function destoy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
