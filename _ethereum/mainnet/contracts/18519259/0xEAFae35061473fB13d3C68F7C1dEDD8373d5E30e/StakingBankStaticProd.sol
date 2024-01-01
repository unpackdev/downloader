// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./StakingBankStatic.sol";

contract StakingBankStaticProd is StakingBankStatic {
    address public constant VALIDATOR_0 = 0x977Ba523420110e230643B772Fe9cF955e11dA7B;
    address public constant VALIDATOR_1 = 0xe2422b23e52bc13ebA04d7FbB9F332Deb43360fB;

    // external order is based on validators submits on AVAX for Apr 2023
    address public constant VALIDATOR_2 = 0x57F404aD75e371c1A539589C1eFCA12e0C6980AD;
    address public constant VALIDATOR_3 = 0xD56C6A4f64E0bD70260472d1DB6Cf5825858CB0d;
    address public constant VALIDATOR_4 = 0x220230Eda8f50067Dd9e4729345dabCCe0C61542;
    address public constant VALIDATOR_5 = 0x93FdcAB283b0BcAc48157590af482E1CFd6af6aC;
    address public constant VALIDATOR_6 = 0xCd733E06B06083d52fC5867E8E3432aA5c103A38;
    address public constant VALIDATOR_7 = 0x42e210b110c6aa49CdfA7ceF1444Aa4719653111;
    address public constant VALIDATOR_8 = 0x501731c6a69803a53Ec6c3e12f293c247cE1092B;
    address public constant VALIDATOR_9 = 0x8bF9661F1b247522C75DD0FE84355aD2EfF27144;
    address public constant VALIDATOR_10 = 0x281754Ab58391A478B7aA4E7f39991CfB41118c4;
    address public constant VALIDATOR_11 = 0xB9C63a350A04d8BD245d18928a26EE036352dDd8;
    address public constant VALIDATOR_12 = 0x57A51D5BDcE188c2295fCA3b4687475a54E65A02;
    address public constant VALIDATOR_13 = 0x777FbA3666fa7747476a34577FcCC404b263E09F;
    address public constant VALIDATOR_14 = 0x2F85824B2B38F179E451988670935d315b5b9692;
    address public constant VALIDATOR_15 = 0xA7241994267682de4dE7Ef62f52dc2C783d1784B;
    address public constant VALIDATOR_16 = 0x6eEd457C20603EDAE50C3A112CAA1a9425321bD0;
    address public constant VALIDATOR_17 = 0xC5a7650c2725a7B6A39f15cb9FbffC7af357AFeb;
    address public constant VALIDATOR_18 = 0xFEd95453678920c1b7b3A81F033Ca02a27225556;

    constructor(uint256 _validatorsCount) StakingBankStatic(_validatorsCount) {}

    // solhint-disable-next-line code-complexity
    function validators(address _id) external pure override returns (address id, string memory location) {
        if (_id == VALIDATOR_0) return (_id, "https://validator.umb.network");
        if (_id == VALIDATOR_1) return (_id, "https://validator2.umb.network");
        if (_id == VALIDATOR_2) return (_id, "https://umbrella.artemahr.tech");
        if (_id == VALIDATOR_3) return (_id, "https://umb.vtabsolutions.com:3030");
        if (_id == VALIDATOR_4) return (_id, "https://umb.stakers.world");
        if (_id == VALIDATOR_5) return (_id, "https://umbrella.crazywhale.es");
        if (_id == VALIDATOR_6) return (_id, "https://umbrella-node.gateomega.com");
        if (_id == VALIDATOR_7) return (_id, "https://umb.anorak.technology");
        if (_id == VALIDATOR_8) return (_id, "https://umbrella.validator.infstones.io");
        if (_id == VALIDATOR_9) return (_id, "https://umb.hashquark.io");
        if (_id == VALIDATOR_10) return (_id, "http://umbrella.staking4all.org:3000");
        if (_id == VALIDATOR_11) return (_id, "https://umbrella-api.validatrium.club");
        if (_id == VALIDATOR_12) return (_id, "http://5.161.78.230:3000");
        if (_id == VALIDATOR_13) return (_id, "https://umbnode.blockchainliverpool.com");
        if (_id == VALIDATOR_14) return (_id, "https://umb-api.staking.rocks");
        if (_id == VALIDATOR_15) return (_id, "https://rpc.urbanhq.net");
        if (_id == VALIDATOR_16) return (_id, "https://umbrella-node.ankastake.com");
        if (_id == VALIDATOR_17) return (_id, "https://umbrella.tchambrella.com");
        if (_id == VALIDATOR_18) return (_id, "https://umbrella-node.cmt13.eu");

        return (address(0), "");
    }

    function _addresses() internal view override returns (address[] memory) {
        address[] memory list = new address[](NUMBER_OF_VALIDATORS);

        list[0] = VALIDATOR_0;
        list[1] = VALIDATOR_1;
        list[2] = VALIDATOR_2;
        list[3] = VALIDATOR_3;
        list[4] = VALIDATOR_4;
        list[5] = VALIDATOR_5;
        list[6] = VALIDATOR_6;
        list[7] = VALIDATOR_7;
        list[8] = VALIDATOR_8;
        list[9] = VALIDATOR_9;
        list[10] = VALIDATOR_10;
        list[11] = VALIDATOR_11;
        list[12] = VALIDATOR_12;
        list[13] = VALIDATOR_13;
        list[14] = VALIDATOR_14;
        list[15] = VALIDATOR_15;
        list[16] = VALIDATOR_16;
        list[17] = VALIDATOR_17;
        list[18] = VALIDATOR_18;

        return list;
    }

    function _isValidator(address _validator) internal pure override returns (bool) {
        return (
            _validator == VALIDATOR_0
            || _validator == VALIDATOR_1
            || _validator == VALIDATOR_2
            || _validator == VALIDATOR_3
            || _validator == VALIDATOR_4
            || _validator == VALIDATOR_5
            || _validator == VALIDATOR_6
            || _validator == VALIDATOR_7
            || _validator == VALIDATOR_8
            || _validator == VALIDATOR_9
            || _validator == VALIDATOR_10
            || _validator == VALIDATOR_11
            || _validator == VALIDATOR_12
            || _validator == VALIDATOR_13
            || _validator == VALIDATOR_14
            || _validator == VALIDATOR_15
            || _validator == VALIDATOR_16
            || _validator == VALIDATOR_17
            || _validator == VALIDATOR_18
        );
    }
}
