pragma solidity 0.6.7;

abstract contract Setter {
  function addAuthorization(address) external virtual;
  function removeAuthorization(address) external virtual;
  function setOwner(address) external virtual;
  function setRoot(address) external virtual;
}

contract Proposal {
  address constant GEB_PAUSE_PROXY = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;
  address constant GEB_UNGOVERNOR_PAUSE_PROXY = 0xd62bDdFe85b8BB7EE7e092eBBFF07BAC0bB07bf8;
  address constant GEB_UNGOVERNOR = 0x7a6BBe7fDd793CC9ab7e0fc33605FCd2D19371E8;
  address constant GEB_PROT_MINTER = 0xB5B59Ed1C679B5A955BF7eFfC6628d5f4b7CA7f3;
  address constant LIQUIDATION_ENGINE_OVERLAY_NEW = 0xa10C1e933C21315DfcaA8C8eDeDD032BD9b0Bccf;
  address constant LIQUIDATION_ENGINE_OVERLAY_OLD = 0xA0a169a7b8aA07C849CfD12C08D499BeAcb15bb7;
  address constant ACCOUNTING_ENGINE_OVERLAY_NEW = 0xBEEb7701233eb6c9fcF34D2dd70c2a7ad66bbD2f;
  address constant ACCOUNTING_ENGINE_OVERLAY_OLD = 0x458c1c0D9238652b657EbDC0F08e5023079D7664;
  address constant GLOBAL_SETTLEMENT_OVERLAY_NEW = 0x329C0042C1F2BCD147ea78E7B009EabE74D2E254;
  address constant RATE_SETTER_OVERLAY_NEW = 0x67E38536d8b1eFad846a030B797C00e43364372E;
  address constant RATE_SETTER_OVERLAY_OLD = 0x02bEab987F36B6b71B4510C1C024bE9Da2AB569E;
  address constant GEB_COLLATERAL_AUCTION_HOUSE_ETH_A_OVERLAY_NEW = 0x9a1667B2577A86F0B938E625D65A229430A7c781;
  address constant GEB_COLLATERAL_AUCTION_HOUSE_ETH_A_OVERLAY_OLD = 0x71Ba7a26721D916f82383d386Cc4C5748D9aEf67;
  address constant STAKING_OVERLAY_NEW = 0xcC8169c51D544726FB03bEfD87962cB681148aeA;
  address constant STAKING_OVERLAY_OLD = 0xE3c80D0e60027BbAf403fAA8A9CF6775C4D416F6;
  address constant STAKING_AUCTION_HOUSE_OVERLAY_NEW = 0x9cC1Fc8fea20b4924Be191527E9f11A1C078b983;

  Setter constant GEB_ACCOUNTING_ENGINE = Setter(0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE);
  Setter constant GEB_LIQUIDATION_ENGINE = Setter(0x4fFbAA89d648079Faafc7852dE49EA1dc92f9976);
  Setter constant GEB_GLOBAL_SETTLEMENT = Setter(0xee4Cf96e5359D9619197Fd82B6eF2a9EaE7B91e1);
  Setter constant GEB_RRFM_SETTER = Setter(0x7Acfc14dBF2decD1c9213Db32AE7784626daEb48);
  Setter constant GEB_COLLATERAL_AUCTION_HOUSE_ETH_A = Setter(0x7fFdF1Dfef2bfeE32054C8E922959fB235679aDE);
  Setter constant GEB_STAKING = Setter(0x69c6C08B91010c88c95775B6FD768E5b04EFc106);
  Setter constant GEB_STAKING_AUCTION_HOUSE = Setter(0x12806f5784ee31494f4B9CD81b5E2E397500DFCa);
  Setter constant COLLATERAL_AUCTION_THROTTLER = Setter(0x709310eB91d1902A9b5EDEdf793b057f0da8DECb);
  Setter constant PROTOCOL_TOKEN_AUTHORITY = Setter(0xcb8479840A5576B1cafBb3FA7276e04Df122FDc7);
  Setter constant GEB_PAUSE_AUTHORITY = Setter(0x1490a828957f1E23491c8d69273d684B15c6E25A);
  Setter constant GEB_SAFE_ENGINE = Setter(0xCC88a9d330da1133Df3A7bD823B95e52511A6962);
  Setter constant GEB_RRFM_SETTER_RELAYER = Setter(0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB);
  Setter constant GEB_DAO_STREAM_VAULT = Setter(0x0FA9c7Ad448e1a135228cA98672A0250A2636a47);
  Setter constant GEB_DEBT_FLOOR_ADJUSTER = Setter(0x2de894805e1c8F955a81219F1D32b902E919a855);
  Setter constant GEB_AUTO_SURPLUS_BUFFER = Setter(0x5376BC11C92189684B4B73282F8d6b30a434D31C);
  Setter constant GEB_DAO_TREASURY = Setter(0x7a97E2a5639f172b543d86164BDBC61B25F8c353);

  function execute(bool) external {

    // --- OVERLAYS ---

    // REPLACE THE CURRENT GOV OVERLAY WITH LATEST ONE, THEN REMOVE DS PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalLiquidationEngineOverlay.sol)
    GEB_LIQUIDATION_ENGINE.removeAuthorization(LIQUIDATION_ENGINE_OVERLAY_OLD);
    GEB_LIQUIDATION_ENGINE.addAuthorization(LIQUIDATION_ENGINE_OVERLAY_NEW);
    GEB_LIQUIDATION_ENGINE.removeAuthorization(GEB_PAUSE_PROXY);

    // DEPLOY THE GOV OVERLAY FOR IT AND REMOVE DS PAUSE PROXY AUTH (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalAccountingEngineOverlay.sol)
    GEB_ACCOUNTING_ENGINE.removeAuthorization(ACCOUNTING_ENGINE_OVERLAY_OLD);
    GEB_ACCOUNTING_ENGINE.addAuthorization(ACCOUNTING_ENGINE_OVERLAY_NEW);
    GEB_ACCOUNTING_ENGINE.removeAuthorization(GEB_PAUSE_PROXY);

    // AUTH THE GOV OVERLAY FOR IT AND THEN REMOVE DS PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalGlobalSettlementOverlay.sol)
    GEB_GLOBAL_SETTLEMENT.addAuthorization(GLOBAL_SETTLEMENT_OVERLAY_NEW);
    GEB_GLOBAL_SETTLEMENT.removeAuthorization(GEB_PAUSE_PROXY);

    // AUTH THE GOV OVERLAY FOR IT AND THEN REMOVE DS PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalRateSetterOverlay.sol)
    GEB_RRFM_SETTER.addAuthorization(RATE_SETTER_OVERLAY_NEW);
    GEB_RRFM_SETTER.removeAuthorization(RATE_SETTER_OVERLAY_OLD);
    GEB_RRFM_SETTER.removeAuthorization(GEB_PAUSE_PROXY);

    // REPLACE THE CURRENT OVERLAY WITH THE LATEST ONE AND THEN DEAUTH DS PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalDiscountCollateralAuctionHouseOverlay.sol)
    GEB_COLLATERAL_AUCTION_HOUSE_ETH_A.removeAuthorization(GEB_COLLATERAL_AUCTION_HOUSE_ETH_A_OVERLAY_OLD);
    GEB_COLLATERAL_AUCTION_HOUSE_ETH_A.addAuthorization(GEB_COLLATERAL_AUCTION_HOUSE_ETH_A_OVERLAY_NEW);
    GEB_COLLATERAL_AUCTION_HOUSE_ETH_A.removeAuthorization(GEB_PAUSE_PROXY);

    // ADD OVERLAY; DEAUTH PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalLenderFirstResortOverlay.sol)
    GEB_STAKING.addAuthorization(STAKING_OVERLAY_NEW);
    GEB_STAKING.removeAuthorization(STAKING_OVERLAY_OLD);
    GEB_STAKING.removeAuthorization(GEB_PAUSE_PROXY);

    // ADD OVERLAY; DEAUTH PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalStakedTokenAuctionHouseOverlay.sol)
    GEB_STAKING_AUCTION_HOUSE.addAuthorization(STAKING_AUCTION_HOUSE_OVERLAY_NEW);
    GEB_STAKING_AUCTION_HOUSE.removeAuthorization(GEB_PAUSE_PROXY);

    // DEPLOY OVERLAY?; DEAUTH PAUSE PROXY
    COLLATERAL_AUCTION_THROTTLER.removeAuthorization(GEB_PAUSE_PROXY);

    // -- DEAUTH PAUSE_PROXY AND OTHER CONTRACTS --
    // REMOVE DS PAUSE PROXY
    GEB_SAFE_ENGINE.removeAuthorization(GEB_PAUSE_PROXY);

    // NO OVERLAY NEEDED, REMOVE DS PAUSE PROXY
    GEB_RRFM_SETTER_RELAYER.removeAuthorization(GEB_PAUSE_PROXY);

    // DEAUTH PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalSingleDebtFloorAdjusterOverlay.sol)
    GEB_DEBT_FLOOR_ADJUSTER.removeAuthorization(GEB_PAUSE_PROXY);

    // DEAUTH PAUSE PROXY (https://github.com/reflexer-labs/geb-gov-minimization-overlay/blob/master/src/overlays/minimal/MinimalAutoSurplusBufferSetterOverlay.sol)
    GEB_AUTO_SURPLUS_BUFFER.removeAuthorization(GEB_PAUSE_PROXY);

    // REMOVE OLD GOVERNOR PAUSE PROXY
    GEB_DAO_TREASURY.removeAuthorization(GEB_UNGOVERNOR_PAUSE_PROXY);

    // REMOVE OLD GOVERNOR PAUSE PROXY
    GEB_DAO_STREAM_VAULT.removeAuthorization(GEB_UNGOVERNOR_PAUSE_PROXY);

    // REMOVE THE ONE TIME MINTER FROM AUTHED ACCOUNTS
    PROTOCOL_TOKEN_AUTHORITY.removeAuthorization(GEB_PROT_MINTER);
    PROTOCOL_TOKEN_AUTHORITY.setOwner(address(0));
    PROTOCOL_TOKEN_AUTHORITY.setRoot(address(0));
  }
}