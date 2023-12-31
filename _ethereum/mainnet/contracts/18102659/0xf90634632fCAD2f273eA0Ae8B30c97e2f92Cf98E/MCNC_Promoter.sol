// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MCNC_Promoter {
    IERC20 public mainToken;
    address public mainTokenAddress = 0x3Aa9EBdCF5aff192F1759F35CFD6aFe0b898FB6F;
    address public rescueAddress = 0x718914A81855B7694275c5Fc452f39613CfA7990;

    uint256 public startTime;

    address public owner;
    address[40] public promoterWallets;  // Array to store promoter wallet addresses

    mapping(address => uint256) public lastRewardTime;

    uint256 constant public ONE_MONTH = 30 days;

    constructor(IERC20 _mainToken) {
        require(address(_mainToken) == mainTokenAddress, "Provided token is not the expected token.");

        mainToken = _mainToken;
        owner = msg.sender;
        startTime = 1685984400; // Fixed UNIX timestamp

        // Initialize the promoter wallet addresses
        promoterWallets = [
        0x55d12607aCfa334f30d759891608FF761CA6f205, 
        0x8Df47Bace432Ab834641de24C98207eDB2BBf7CA, 
        0x2E3eB1E581932c1DCDd1981ba3d513DbbCFE3e8F, 
        0x3B777b5A840b8A03e927bD8C827840554CF4b02A, 
        0x482Bc10b5CcA4EAE113D0a609820342528016Fe8, 
        0x47Df4C4d7b617D5dBc79F64d38dB85269a1ce327, 
        0x3514be4C3933e47D055ec73413994a28e05fC7B2, 
        0xFB2d862c5E36c4123aB6fb954B4b3e6b1ADA835e, 
        0x96dCe5EF95bF48430aF39759FE9970417B081970, 
        0x912A593fddb251B164fcdE977Bc17b666C555e72, 
        0x07a2746948631E761F53defC8ca8B720289A31ff, 
        0xc98370959401AeC3F34e22938DD702e7DdAA3a1e, 
        0xfb9f6d34DDeD9CcB5a9dB881eC423160943C32cC, 
        0x74F965f9338655ae430b397E5b70c7BB26312f93, 
        0xd29C30Dce00822DabaecE47E96d459450b423504, 
        0x4e7ACDA2C7F76ecDF631149152c1Ad60E0968024, 
        0x0f89E4185318DCa5Df42A4EAF5093B096aF13bF6, 
        0xE1c646CE01EA5A77e0Fbd2dba7c0BDFb0d16b630, 
        0x3F827316B87ff23d43c3a32777855583aa358e94, 
        0xE8164cBeA6a525b8f701c305322Ce1bF5eBaB708, 
        0xfCA5F698740960741F9257186917717a88A89238, 
        0x500EF28688715a2D7EAACb7A2048ACdefd438af8, 
        0xB2a383d4de90d5a2d02152B185d2705A54924B39, 
        0x59820f7D77A8FF403934a34Afc152757D425DA57, 
        0x11Eb5F9A9bc9a57dF3b1432184401694c8a813bE, 
        0xc65c78021773Ae9Fc5002Fe2Dc10Ba7f18e4E3e5, 
        0xC94b10fD18F44cF7D50c113054e7D2436C5E656a, 
        0x849E5747381D41B8CF7676a2964f26B58909bF68, 
        0x0C6573419638E3c86e3d5b6f9BFF75e095a1b306, 
        0x70491f8c27ec11466D840cef34Cd05d447cC06d9, 
        0x1A0fBF5538D68C0Af74f90346c30f2fC750338Cc, 
        0x04B360531b5404DdA0c1A5D947A7B2cBDe28D684, 
        0xc80e1d48836fbED7f7C39F6Fd3F0Ad000DA0938f, 
        0xA5927315eA3B066dF86bf4d599d639B3C250dc8A, 
        0xf6A3204C0F1b97dc4816a6a35d1451213B54cbD2, 
        0xb0b10AE297B791DD835C5Aa0d2c32485E9104D18, 
        0xD65C2199E14eFa490f359870B522309DCF051ca5, 
        0x8f91c9DBe1A2C6b3d0EE05E5b623a249C0A6CB90, 
        0x77dD5C73f3322b378A29f3E1C34d1Aa29332Eb86, 
        0xE8164cBeA6a525b8f701c305322Ce1bF5eBaB708
        ];

        // Initialize the last reward times for each wallet
        for (uint256 i = 0; i < promoterWallets.length; i++) {
            lastRewardTime[promoterWallets[i]] = startTime;
        }
    }

    function release() public {
        uint256 currentTime = block.timestamp;
        uint256 periodsElapsed;

        for (uint256 i = 0; i < promoterWallets.length; i++) {
            address wallet = promoterWallets[i];
            periodsElapsed = (currentTime - lastRewardTime[wallet]) / ONE_MONTH;
            if (periodsElapsed > 0) {
                lastRewardTime[wallet] += periodsElapsed * ONE_MONTH;
                releaseTokens(wallet, 10150 * 10**18);
            }
        }
    }

    function releaseTokens(address recipient, uint256 amount) private {
        bool success = mainToken.transfer(recipient, amount);
        require(success, "MCNC transfer failed.");
    }

    function rescueTokens(IERC20 token) public {
        require(address(token) != mainTokenAddress, "Cannot rescue the main token.");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to rescue.");
        bool success = token.transfer(rescueAddress, balance);
        require(success, "Token rescue failed.");
    }
}