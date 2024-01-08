// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ETHWalkersPayments is Ownable{
    using SafeMath for uint256;
    
    receive() external payable {
    }
    
    fallback () external payable{
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    function withdraw() public onlyOwner {
        uint balanceToMultiply = uint(address(this).balance) / uint(1000000); // 100% in millionths
        uint apeShare = uint(3334); // ~0.3334%, total of 60 apes ~= 20.004%
        uint extraShare = uint(2000); // 0.2% for extra assistance
        uint oneSixthForFounder = (uint(1000000) - ((apeShare.mul(60)) + extraShare)) / uint(5); // Update when ape number increases

        _safeTransferETH(payable(address(0x6ac5DEd5906C5eBe69ad00151f199bBf637C4707)), balanceToMultiply.mul(oneSixthForFounder)); // ~15.9592% to Derek
        _safeTransferETH(payable(address(0xCEE06e0CD4d21aD17487Df7a896b8CB77A36DDfc)), balanceToMultiply.mul(oneSixthForFounder)); // ~15.9592% to Matt
        _safeTransferETH(payable(address(0xAC937BCd2C0e11f639C25a38b2794Ac939FFeE1f)), balanceToMultiply.mul(oneSixthForFounder)); // ~15.9592% to Max
        _safeTransferETH(payable(address(0x44C4482652BD9fa04F5b3d3E4Ef76b8512BCaF35)), balanceToMultiply.mul(oneSixthForFounder)); // ~15.9592% to Stephen
        _safeTransferETH(payable(address(0xB1aCd7f40a13022f0DD458769aD555FB99615d10)), balanceToMultiply.mul(oneSixthForFounder)); // ~15.9592% to Chase
        _safeTransferETH(payable(address(0x9cD4177604c6732818c0647346C275B35cD956F0)), balanceToMultiply.mul(extraShare)); // ~0.2% to Courtney

        _safeTransferETH(payable(address(0x34af7292E817c6AF135B6e49399f3012674c4c48)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xeb298223F82EcB1e8b21C9F0cA5E7ba7a98C732e)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xF1e82BCeCD8A5770C0BB3731A76ac0199F912cA6)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xEee899B6521DB73E94F4B9224Cdf3db0010Fa334)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x230FcED7feAeD9DfFC256B93B8F0c9195a743c89)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xb67167d3f3d4a8c385C132592CE681dFD98ee2e8)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x900b7ce829E58F284C46Db1fA468Dde519f485e3)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xaf469C4a0914938e6149CF621c54FB4b1EC0c202)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xC0eB311C2f846BD359ed8eAA9a766D5E4736846A)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x9ad3c05B3FAA93575e4F91F1B1eDff7B337d528F)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x17A77D63765963d0Cb9deC12Fa8F62E68Fee8fD4)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xF07bD3a1e2E84bFc1897C4433189590bd8c80b19)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xB2861cD1eCBc01b4Cf239491F8b951CA652B53C0)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x6371D2309B7F79bB0FCaa6e7E8CeEEf8f1D4C484)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x591F8a2deCC1c86cce0c7Bea22Fa921c2c72fb95)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x12CCdf3513f8f09f4C0E6Ad7821988a7A8Ac0bE1)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x87EF4444C8E86AC65D356FfC2174fCa6ebdA0303)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xCFc9E5258A8773cEa0440077779a17096A045BF2)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x72FAe93d08A060A7f0A8919708c0Db74Ca46cbB6)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x1a677d15b8f28c26ad3cF257518AC69cc1ab5178)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xB1Ce2c57A6f8816113fd172A75fC3B9803320228)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xD30B579Be7da30C903c96c7dE3729F8977e614E4)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xf0c55dA3a8274f6843434dF0da437eD4AC0Dd310)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x797bE6e98861C39b89f7B8BFfe492d26C29af84F)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x790d5818D56F5a7a8e214A42797752822117BF3D)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x59f42EdA42Eb551a17A59E2C6549F18229A35c3e)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xeB08809976E7688A41378af8e8AC1CBBCf9C9Ef8)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xd950b9a4f667184c386b0C57311784C762D591b6)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xB75959df7B0dD6F9dfEa69b3e1661E7b07B79600)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x756624F2c0816bFb6a09E6d463c695b39a146629)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x6530dd1aABD45FbFB97a9368820FBB6ef561b765)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x9Dfd400201b905dc343cf0EAAE5f68F4DA342b60)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xf76982fe0C2AC32C9126002b8988F5946421Ce4c)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x46b2bD5C888E6d57a839c559FD6076F2c15A8cB1)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x3584fE4F1e719FD0cC0F814a4A675181438B45DD)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xc968416370639A9B74B077A4a8f97076e4Ae1D9E)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x0F73622476E604d34dDF24ef4D709968a264A259)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x9AaE5b185f764c5F1E06Ea3967bbaE3ADf39b0f5)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x906b346A7d88d8EC5EB0749fEd160702f58BF425)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xd887C683ae148B622c42235D7c2395F9b22c6777)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x543bBa29d7CF8dAB00D0dA3A86ff1c6C5B4418d3)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x8A3fECD0348da48d5fe4dC05b2897d2758942abf)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x80B1b33a888924EE204b27553D270B3ae6a22ac4)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x2d7B25436eAF47e63214900061F1bb6269B840dd)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xE859d127b7e68E1C8B1212e1b7925B84B2D2CE7b)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x1Cd7E71A6C81a576Fb9ec00B58175b086CAf1504)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xFd4938b02074DF1d3Aa15a97Ee561f40704b2195)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xEC36697c3C8C8E385b37e17Df40dBCbE2dbd9ffC)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x9Dae5b7E7b13fb95fF83c4c617E9a1BCe60d383A)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x050515e0D42d1Dca9dC8f6E9D890A9E29417Fb9e)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x1fcb4Fb1c8C239CfDE95c833fE5e3564d218733b)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xD3C6E4583BCc33339D733cb35034362D134A6749)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xFfA628eAd5a8fa81531D50A6b571287f588C9dA1)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x4265D230d2D54010d853b107848FC6e0B64c9c24)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0x3e6cA480f9f474c5f495bAf8263d5Ff284d3bbc1)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xDef36C661A609421Bc2441BEf51F99783593bbdF)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xD80a3F1C31cCF19ea14c69250D5cDFF7e8D305b5)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xef8e27BAD0F2eEE4e691e5B1eaAb3c019e369557)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xF7D993147f69F3812f5f1eF50067dd7EbDe93E8b)), balanceToMultiply.mul(apeShare));
        _safeTransferETH(payable(address(0xd3AefE3c531E3E2eB0689206E7D495843c943550)), balanceToMultiply.mul(apeShare));
    }
}