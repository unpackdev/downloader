// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";

contract RightToken is ERC20, Ownable { // can stop mint

    uint256 public maxSupply;

    constructor(
    ) ERC20("Right", "Right") {
        _init();
        maxSupply = 10000000000 ether; // max 10 billion RIGHT Token
    }


    function batchMint(address[] memory accountList, uint256[] memory amountList) public virtual onlyOwner{
        uint256 amount;
        for(uint256 i = 0; i < amountList.length; i++){
            amount = amount + amountList[i];
        }
        require(totalSupply() + amount < maxSupply, "token amounts exceeds max");
        _batchMint(accountList, amountList);
    }
    
    function _batchMint(address[] memory accountList, uint256[] memory amountList) internal virtual{
        require(accountList.length == amountList.length, "mint params don't match");
        for(uint256 i = 0; i < accountList.length; i++){
            _mint(accountList[i], amountList[i]);
        }
    }
    
    function _init() internal{
        _mint(0xfE925d32edc1FAA5F0Ec93fb00a3d0f15aC747D3, 220000 ether);
        _mint(0xC581d65F4F2fdaB7e8cC331730C7d9ed6428C162, 105200 ether);
        _mint(0xD6528A689a54ABDaC4946Fa9f0D637ad18C3c312, 2000 ether);
        _mint(0x46C370b57D63a4328cC068EeB0233136A4666666, 1000 ether);
        _mint(0xea6f0eBc0358B40118Ee7D937a07e8cE9b0DAE41, 20 ether);
        _mint(0x351Db4fBa6A40e932D4f1803041EAD4Dd638BfaC, 2800 ether);
        _mint(0x6862dcAA3490493d41018eA935ae4a4cA4120862, 500 ether);
        _mint(0xBb8f12f4080816f933F0fb80E11b17DE32A3B32E, 10000 ether);
        _mint(0xCfC7bF5B9D4Aa6Ed90C219891f229e52c83070Bd, 30 ether);
        _mint(0x8bb8bCf5EE6Ff0278e4315DB409E1a8f26E51fD0, 500 ether);
        _mint(0xf819c075cd8d68E877073FFEDa6982aAc35BD726, 12000 ether);
        _mint(0x4cc40ddcB757E01A5326e07aBA4709D81B66599A, 29000 ether);
        _mint(0x07DE7F43EF5441E592F98D20ad47a33d4dA985b6, 11990 ether);
        _mint(0x7Ccbae5844eC7434dAA281e787bf1592E64D8901, 1000 ether);
        _mint(0xC567cA38efF4cef63745436f8eB07ccCF300571D, 10000 ether);
        _mint(0xb9C84645ddB24060f71963F90ec170f810E294A7, 50 ether);
        _mint(0xD004846f7676672414F50b39BcfD39c283C870Cc, 1000 ether);
        _mint(0x70fbF2f80005C7399dbAe1eC09AD25F41bc5eF1c, 300 ether);
        _mint(0x1bB77E121B1Ac9083c3C958437086D93BAB4b128, 300 ether);
        _mint(0x361A58532a16a660E6312B50E9066b6828531081, 3000 ether);
        _mint(0x7A2d3De69eDB1C584c465DB319fF597e12fE49A7, 10000 ether);
        _mint(0x3908e83DD741c35a025FAdC8bD6ec6b51fa84Da3, 2000 ether);
        _mint(0xF92f5d4Ff40277B870299A97711d054fF510BB0D, 7000 ether);
        _mint(0x452E762EC62b8F471776B7346201330F47b9d052, 20000 ether);
        _mint(0x7f71c92A1d3E885bA43af85aB0082C5244e3C364, 100000 ether);
        _mint(0xC9F77e99E83d93ed1E7E07Cb431E56F10ad1458C, 10000 ether);
        _mint(0x04A87558A4C58426Ebe2d97e32161600CCE0f9AD, 8000 ether);
        _mint(0xec4d6033f2b0296cd9A860cf2fBEF820ba64488d, 3100 ether);
        _mint(0x860268a00314c382480f1258D378589c492d9E7b, 1000 ether);
        _mint(0x1C772B9854E2C421f13f3A7e6a3D521C0510eDE0, 700350 ether);
        _mint(0xE947a586EBeFe01b9644133e89C1e38d7EeA6946, 10000 ether);
        _mint(0x01d51155Ebb3715ffD215b4Ce4B18Cf4AA8C9f76, 750000 ether);
        _mint(0xd821BF4193ba1F7044886F2b5C40e6a9597907A3, 80000 ether);
        _mint(0x1d3efff53ea9552f5C1cC046CddE5A7FE98DA7d6, 10000 ether);
        _mint(0xFa2E625542F2436E4ca64A1357aB5d440F407e0e, 200000 ether);
        _mint(0xeCe9Faaab3886115378Ce7ef362fD5417F3f74B6, 1930 ether);
        _mint(0x82aBe0456AFBD32aBf1f0c5ADd8c4199dC4a3bC3, 1000 ether);
        _mint(0x8b13205227aF504148b59fA67004b01Ec560Dc21, 2000 ether);
        _mint(0x36eF63784e89134a9b18812322139dDffEae5a24, 20000 ether);
        _mint(0xEce70e37e97931881cE50c6ce0aFd0f853702808, 55000 ether);
        _mint(0x63aB19bBaD984ee1B1866a130A4386a646537a40, 600000 ether);
        _mint(0xe18C212dc18567B887C53f89890B52CebCD8b9F3, 5000 ether);
        _mint(0x13BBC6c42cf29a9db1c043E3cC275E4d28A85F77, 130000 ether);
        _mint(0x3717Df2e0971fA64FcAA2eb78C93A033389de78A, 100 ether);
        _mint(0x7a6F44464Bf5bFBb4ce2852CC7E7B173D89c5fd5, 10000 ether);
        _mint(0x0052BBdd26c78d5046a3d5EaA47EB84dA78332a3, 15000 ether);
        _mint(0x17D7F34Bd782f9AfA72A303010BBe3dBF84B2892, 5000 ether);
        _mint(0x6033ab9fD630Cd5f77f16E2b75bC48826E052B4f, 963100 ether);
        _mint(0x8a5d335F9B2789f7db40d8f79cB59a401B268b33, 5000 ether);
        _mint(0xE985A1A1248b995266869258CD965F1dE11111EC, 5000 ether);
        _mint(0xf5648868058A62cA721e06b4177A46B9F84cc93A, 2300 ether);
        _mint(0xbB6B8AEfA6338934371Bd936B5dbaba2Da94b487, 50 ether);
        _mint(0x6693DA2C25f18a8AAc0B7F9d1CF197Ab2B29B006, 800 ether);
        _mint(0xf36E7a3fa8d4E71563253D11e1d0FBaf3ab12C57, 2000 ether);
        _mint(0x99E205965f446c1Ff578f56Cb439F5dF0D84B017, 430000 ether);
        _mint(0xBCF4FC59f7c1b50b14Bd73Ca4C1D284d1de718dE, 34000 ether);
        _mint(0x553EE04aD4b04A381d69545c84012EA2e2Df1fEE, 20000 ether);
        _mint(0x0B0975DAb21e0ADBa31C65380d5bB90dDAA7a781, 250000 ether);
        _mint(0x82148E2F318c3C607Fedbc0D2Ab470667A6a338D, 80000 ether);
        _mint(0xA2942cf26Ce71E87b74bff01aDBEDDe2EE147C59, 45000 ether);
        _mint(0x4adee4906e1011ED89A5F170DE1244f8E7007122, 500000 ether);
        _mint(0x5d2832C2AaFDB87d7F661EA707Ae1CfDbfF7269A, 74500 ether);
        _mint(0xd71bC416c9D7B2aCFceAA4038FB441839F7E2459, 130000 ether);
        _mint(0x1d82C175E43EbF0b03ea5F50F2A26A4EE6465e68, 10000 ether);
        _mint(0xf0226D8Ef8c1C0766817584e4e7F6EA6F05C279A, 96000 ether);
        _mint(0xFEB1231112D7bCd447671248f05Fb580E3836A71, 200 ether);
        _mint(0x4759C2AA030878ea0ABE3cEEBbfAe5035451139C, 1000 ether);
        _mint(0x0a4258445df9dAA2D8589E15D102d8EB9319E554, 200 ether);
        _mint(0x7268Ae58AB54955f1BD683Bf96113a0Ed33F30C9, 2000 ether);
        _mint(0x5e3D085eafEeaA3D6Dff1aB29142bAA1a640f78a, 2500000 ether);
    }
}