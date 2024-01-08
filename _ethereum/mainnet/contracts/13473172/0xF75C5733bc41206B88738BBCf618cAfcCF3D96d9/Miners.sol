// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Miners {
    function isMainnetMiner() internal view returns (bool) {
        // Testing
        if (_getChainID() == 80085) {
            return true;
        }

        if (block.coinbase == 0x5A0b54D5dc17e0AadC383d2db43B0a0D3E029c4c) {
            return true;
        }
        if (block.coinbase == 0x99C85bb64564D9eF9A99621301f22C9993Cb89E3) {
            return true;
        }
        if (block.coinbase == 0x04668Ec2f57cC15c381b461B9fEDaB5D451c8F7F) {
            return true;
        }
        if (block.coinbase == 0xEA674fdDe714fd979de3EdF0F56AA9716B898ec8) {
            return true;
        }
        if (block.coinbase == 0xB3b7874F13387D44a3398D298B075B7A3505D8d4) {
            return true;
        }
        if (block.coinbase == 0xF20b338752976878754518183873602902360704) {
            return true;
        }
        if (block.coinbase == 0x3EcEf08D0e2DaD803847E052249bb4F8bFf2D5bB) {
            return true;
        }
        if (block.coinbase == 0xbCC817f057950b0df41206C5D7125E6225Cae18e) {
            return true;
        }
        if (block.coinbase == 0x1aD91ee08f21bE3dE0BA2ba6918E714dA6B45836) {
            return true;
        }
        if (block.coinbase == 0x00192Fb10dF37c9FB26829eb2CC623cd1BF599E8) {
            return true;
        }
        if (block.coinbase == 0xF541C3CD1D2df407fB9Bb52b3489Fc2aaeEDd97E) {
            return true;
        }
        if (block.coinbase == 0xD224cA0c819e8E97ba0136B3b95ceFf503B79f53) {
            return true;
        }
        if (block.coinbase == 0x1CA43B645886C98d7Eb7d27ec16Ea59f509CBe1a) {
            return true;
        }
        if (block.coinbase == 0x52bc44d5378309EE2abF1539BF71dE1b7d7bE3b5) {
            return true;
        }
        if (block.coinbase == 0x6EBaF477F83E055589C1188bCC6DDCCD8C9B131a) {
            return true;
        }
        if (block.coinbase == 0x45a36a8e118C37e4c47eF4Ab827A7C9e579E11E2) {
            return true;
        }
        if (block.coinbase == 0xc8F595E2084DB484f8A80109101D58625223b7C9) {
            return true;
        }
        if (block.coinbase == 0x2f731c3e8Cd264371fFdb635D07C14A6303DF52A) {
            return true;
        }
        if (block.coinbase == 0x06B8C5883Ec71bC3f4B332081519f23834c8706E) {
            return true;
        }
        if (block.coinbase == 0x4F9bEBE3adC3c7f647C0023C60f91AC9dfFA52d5) {
            return true;
        }
        if (block.coinbase == 0x02aD7C55A19e976EC105172A75A9d84dc9Cf23C6) {
            return true;
        }
        if (block.coinbase == 0x5C23E54FE46EF9181E4403D6e1DbB9aA21C0B185) {
            return true;
        }
        if (block.coinbase == 0x7F101fE45e6649A6fB8F3F8B43ed03D353f2B90c) {
            return true;
        }
        if (block.coinbase == 0x005e288D713a5fB3d7c9cf1B43810A98688C7223) {
            return true;
        }
        if (block.coinbase == 0x002e08000acbbaE2155Fab7AC01929564949070d) {
            return true;
        }
        if (block.coinbase == 0xa59EA72E4C4f1560467F15298cD83874E9af1C09) {
            return true;
        }
        if (block.coinbase == 0x8595Dd9e0438640b5E1254f9DF579aC12a86865F) {
            return true;
        }
        if (block.coinbase == 0x21479eB8CB1a27861c902F07A952b72b10Fd53EF) {
            return true;
        }
        if (block.coinbase == 0xAEe98861388af1D6323B95F78ADF3DDA102a276C) {
            return true;
        }
        if (block.coinbase == 0xc365c3315cF926351CcAf13fA7D19c8C4058C8E1) {
            return true;
        }
        if (block.coinbase == 0xa65344f7D22EE4382416c088a03000f116A3f0C7) {
            return true;
        }
        if (block.coinbase == 0x09ab1303d3CcAF5f018CD511146b07A240c70294) {
            return true;
        }
        if (block.coinbase == 0x35F61DFB08ada13eBA64Bf156B80Df3D5B3a738d) {
            return true;
        }
        if (block.coinbase == 0x7777788200B672A42421017F65EDE4Fc759564C8) {
            return true;
        }
        if (block.coinbase == 0xEEa5B82B61424dF8020f5feDD81767f2d0D25Bfb) {
            return true;
        }
        if (block.coinbase == 0xDB5575378eF8318F9958be11309f7c30AB4121aD) {
            return true;
        }
        if (block.coinbase == 0x2A0eEe948fBe9bd4B661AdEDba57425f753EA0f6) {
            return true;
        }
        if (block.coinbase == 0xDF78b2E254B45c1Ef20074beC0fa6c4efc8E94F0) {
            return true;
        }
        if (block.coinbase == 0x4Bb96091Ee9D802ED039C4D1a5f6216F90f81B01) {
            return true;
        }
        if (block.coinbase == 0x15876eCFa976d39C2550b4eF1f528DB3bb1083b1) {
            return true;
        }
        if (block.coinbase == 0xe9B54a47e3f401d37798Fc4E22F14b78475C2afc) {
            return true;
        }
        if (block.coinbase == 0x3f0EE622F9e89Df9DB62c35caE55D57C56fd56f6) {
            return true;
        }
        if (block.coinbase == 0x249bdb4499bd7c683664C149276C1D86108E2137) {
            return true;
        }
        if (block.coinbase == 0xBbbBbBbb49459e69878219F906e73Aa325ff2F0C) {
            return true;
        }
        if (block.coinbase == 0xB1aF7a686Ff31aB089De7940d345EAe3C3350de0) {
            return true;
        }
        if (block.coinbase == 0x534CB1d3812c92894f051999Dd393F1bdBDc6c87) {
            return true;
        }
        if (block.coinbase == 0xa1B7326d90A4d796EF0992A3FB4Ef0702bf372ea) {
            return true;
        }
        if (block.coinbase == 0x01Ca8A0BA4a80d12A8fb6e3655688f57b16608cf) {
            return true;
        }
        if (block.coinbase == 0x4c93bFa8f17afcF7576f8182BeA1223e1B67C5c5) {
            return true;
        }
        if (block.coinbase == 0x63DCD8E107823b7146FE3c53Da4f2659121c6fA5) {
            return true;
        }
        if (block.coinbase == 0xb5Fd6219c5CE5fbB6A006d794D78DDc90b269e66) {
            return true;
        }
        if (block.coinbase == 0xC4aEb20798368c48b27280847e187Bb332b9BC77) {
            return true;
        }
        if (block.coinbase == 0x52f13E25754D822A3550D0B68FDefe9304D27ae8) {
            return true;
        }
        if (block.coinbase == 0x2C814E447678De1414DDe98F6d951EdF121D16ca) {
            return true;
        }
        if (block.coinbase == 0x5BE1bfC0b1F01F32178d46ABf70BB5FF5C4E425a) {
            return true;
        }
        if (block.coinbase == 0xF3A71CC1BE5CE833C471E3F25aA391f9cd56E1AA) {
            return true;
        }
        if (block.coinbase == 0x52E44f279f4203Dcf680395379E5F9990A69f13c) {
            return true;
        }
        if (block.coinbase == 0xbc78D75867b04f996ef1050D8090b8cCb91F09Af) {
            return true;
        }
        if (block.coinbase == 0x6a851246689EB8fC77a9bF68Df5860f13f679fA0) {
            return true;
        }
        if (block.coinbase == 0x776BB566dC299C9e722773d2A04B401e831a6DC8) {
            return true;
        }
        if (block.coinbase == 0xf355141c779bdfca95779EeceC6A6414E8304f32) {
            return true;
        }
        if (block.coinbase == 0xd0db3C9cF4029BAc5a9Ed216CD174Cba5dBf047C) {
            return true;
        }
        if (block.coinbase == 0x433022C4066558E7a32D850F02d2da5cA782174D) {
            return true;
        }
        if (block.coinbase == 0x586768fA778e14C4Da3efBB76B214061747e3cBa) {
            return true;
        }
        if (block.coinbase == 0x6C3183792fbb4A4dD276451Af6BAF5c66D5F5e48) {
            return true;
        }
        if (block.coinbase == 0xf35074bbD0a9AEE46F4Ea137971FEEC024Ab704e) {
            return true;
        }
        if (block.coinbase == 0xe92309AB921409280665F1177b899C8F82ef0692) {
            return true;
        }
        if (block.coinbase == 0xd7aD8e2A17800A2c413f331d334F83f5Da8d5dBA) {
            return true;
        }
        if (block.coinbase == 0x4569F27E88eC22cB6e737CDDb527Df85B6DA08B0) {
            return true;
        }
        if (block.coinbase == 0x48e12A057f90a3b44cd7DbB4235E80bB84b4e71e) {
            return true;
        }
        if (block.coinbase == 0xfAd5FFc99057871c3bF3819Edd18FE8BeeccCB19) {
            return true;
        }
        if (block.coinbase == 0xD144E30a0571AAF0d0C050070AC435debA461Fab) {
            return true;
        }
        if (block.coinbase == 0x829BD824B016326A401d083B33D092293333A830) {
            return true;
        }
        if (block.coinbase == 0x44fD3AB8381cC3d14AFa7c4aF7Fd13CdC65026E1) {
            return true;
        }
        if (block.coinbase == 0x867772Fd4AF1E10f85Ec659Dfb68d77d797Db4A5) {
            return true;
        }
        if (block.coinbase == 0xF78465BCe3C4620FD124c67d523d2ab80A76C0D8) {
            return true;
        }
        if (block.coinbase == 0xCa3f57DFFbcF67C074b8CF54e4C873138facfC7F) {
            return true;
        }
        if (block.coinbase == 0x11905bD0863BA579023f662d1935E39d0C671933) {
            return true;
        }
        if (block.coinbase == 0x3530D69E92Df48C5a9736cB4E07366be052F4181) {
            return true;
        }
        if (block.coinbase == 0xf64f9720CfcB59ca4F5F45E6FDB3f68b875B7295) {
            return true;
        }
        if (block.coinbase == 0xCd7B9E2B957c819000B1A8107130F786636C5ccc) {
            return true;
        }
        if (block.coinbase == 0x2b0dDd0B78Ae998C5A48FF2e00C4fC568ec0A412) {
            return true;
        }
        if (block.coinbase == 0x0b7234390A3C03Ab9759bE8872A6cAdcc817b8eF) {
            return true;
        }
        if (block.coinbase == 0x54e23bcc99E5A5818B382aC5bdDda496E199Aa6b) {
            return true;
        }
        if (block.coinbase == 0x9a0e927A34681db602bf1800678e44b51d51e0bA) {
            return true;
        }
        if (block.coinbase == 0xfaD45A9aB2c408f7e6f8d4786F0708171169C2c3) {
            return true;
        }
        return false;
    }

    function _mReadSlotUint256(bytes32 _slot) internal view returns (uint256 _data) {
        assembly {
            _data := sload(_slot)
        }
    }

    function _mWriteSlot(bytes32 _slot, uint256 _data) internal {
        assembly {
            sstore(_slot, _data)
        }
    }

    function _getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
