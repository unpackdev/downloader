pragma solidity =0.8.15;

import "./Common.sol";

// MAINNET CONFIGS
string constant NAME = "Alongside Crypto Market Index";
string constant SYMBOL = "AMKT";
uint256 constant VERSION = 0;

// timelock is measured in seconds
uint256 constant CANCELLATION_PERIOD = 1 days;

// governor measured in blocks
uint256 constant AVG_BLOCK_TIME = 12; // seconds
uint256 constant VOTE_DELAY = 1 days / AVG_BLOCK_TIME;
uint256 constant VOTE_PERIOD = 1 days / AVG_BLOCK_TIME;
uint256 constant PROPOSAL_THRESHOLD = 100e18; // Number of votes required to create a proposal
uint256 constant GOVERNOR_NUMERATOR = 5;

address constant MULTISIG = address(0x95347f70dEC9B8Dc92446a9aace5f76509941223);

address constant FEE_RECEIPIENT = address(
    0xC19a5b6E0a923519603985153515222D59cb3F2e
);

uint256 constant FEE_SCALED = 26151474053915;

address constant PROXY = address(0x9E227C8c3eaF717370C4fF8562638Cc95FDC0c37);
address constant PROXY_ADMIN = address(
    0x7459066C61e5Cff6b4B452406aFB2F7236c6877d
);

address constant AMKT = address(0x9E227C8c3eaF717370C4fF8562638Cc95FDC0c37);

contract InitialBountyHelper {
    // Native
    address constant BTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address constant ETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant MATIC =
        address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
    address constant FTM = address(0x4E15361FD6b4BB609Fa63C81A2be19d873717870);
    address constant SHIB = address(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
    address constant LINK = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    address constant UNI = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    address constant LDO = address(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    address constant MNT = address(0x3c3a81e81dc49A522A592e7622A7E711c06bf354);
    address constant CRO = address(0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b);
    address constant QNT = address(0x4a220E6096B25EADb88358cb44068A3248254675);
    address constant ARB = address(0xB50721BCf8d664c30412Cfbc6cf7a15145234ad1);
    address constant MKR = address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    address constant AAVE = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    address constant GRT = address(0xc944E90C64B2c07662A292be6244BDf05Cda44a7);

    // Wormhole Bridge
    address constant BNB = address(0x418D75f65a02b3D53B2418FB8E1fe493759c7605);
    address constant SOL = address(0xD31a59c85aE9D8edEFeC411D448f90841571b89c);
    address constant AVAX = address(0x85f138bfEE4ef8e540890CFb48F620571d67Eda3);
    address constant OP = address(0x1df721D242E0783F8fCab4A9FfE4F35bdf329909);

    // Rainbow Bridge
    address constant NEAR = address(0x85F17Cf997934a597031b2E18a9aB6ebD4B9f6a4);

    function tokens() public returns (TokenInfo[] memory) {
        TokenInfo[] memory tokens = new TokenInfo[](15);

        // The amounts will be determined shortly before the bounty is proposed.
        // The goal is to have the bounty be equivalent the net asset value of AMKT at the time of proposal.
        // 15 assets to be included in the index
        tokens[0] = TokenInfo(BTC, 210);
        tokens[1] = TokenInfo(ETH, 12980246277916);
        tokens[2] = TokenInfo(BNB, 16610096756786);
        tokens[3] = TokenInfo(SOL, 44425);
        tokens[4] = TokenInfo(MATIC, 1006170768659484);
        tokens[5] = TokenInfo(SHIB, 63628478585332960000);
        tokens[6] = TokenInfo(LINK, 60119965915770);
        tokens[7] = TokenInfo(AVAX, 38219619929347);
        tokens[8] = TokenInfo(UNI, 62349545016248);
        tokens[9] = TokenInfo(LDO, 96083216750009);
        tokens[10] = TokenInfo(MNT, 349198078783677);
        tokens[11] = TokenInfo(CRO, 272750);
        tokens[12] = TokenInfo(MKR, 105549335976);
        tokens[13] = TokenInfo(QNT, 1303425762023);
        tokens[14] = TokenInfo(OP, 86211424079488);
        // tokens[15] = TokenInfo(NEAR, 1);
        // tokens[16] = TokenInfo(OP, 1);
        // tokens[17] = TokenInfo(AAVE, 1);
        // tokens[18] = TokenInfo(GRT, 1);

        return tokens;
    }
}
