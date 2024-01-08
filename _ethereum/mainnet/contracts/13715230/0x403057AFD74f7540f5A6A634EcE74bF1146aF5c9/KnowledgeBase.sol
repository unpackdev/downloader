// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library Grimoire {
    bytes32 constant public SUBDAO_KEY_ETHEREANSOS_V1 = 0x1d3784c94477427ee3ebf963dc80bcdc1be400c47ff2754fc2a9cd7328837eb4;
}

library ComponentsGrimoire {
    bytes32 constant public COMPONENT_KEY_TOKEN_MINTER = 0x4668877ff569021c2e8188be2e797f8aa73265eac3479789edfd2531e130b1a1;
    bytes32 constant public COMPONENT_KEY_TOKEN_MINTER_AUTH = 0x9c4db151be7222e332a1dcdb260c7b85b81f214f6b6d83d96c94f814d48a75a5;
    bytes32 constant public COMPONENT_KEY_DIVIDENDS_FARMING = 0x3104750b9808e498d0ff489ed3bdbb01b8ea8018a22c284a054db2dc8fc580a7;
    bytes32 constant public COMPONENT_KEY_OS_FARMING = 0x8ec6626208f22327b5df97db347dd390d4bbb54909af6bc9e8b044839ff9c2ef;
}

library State {
    string constant public STATEMANAGER_ENTRY_NAME_FACTORY_OF_FACTORIES_FEE_PERCENTAGE_FOR_TRANSACTED = "factoryOfFactoriesFeePercentageTransacted";
    string constant public STATEMANAGER_ENTRY_NAME_FACTORY_OF_FACTORIES_FEE_PERCENTAGE_FOR_BURN = "factoryOfFactoriesFeePercentageBurn";

    string constant public STATEMANAGER_ENTRY_NAME_FARMING_FEE_PERCENTAGE_FOR_TRANSACTED = "farmingFeePercentageTransacted";
    string constant public STATEMANAGER_ENTRY_NAME_FARMING_FEE_FOR_BURNING_OS = "farmingFeeBurnOS";

    string constant public STATEMANAGER_ENTRY_NAME_INFLATION_FEE_PERCENTAGE_FOR_TRANSACTED = "inflationFeePercentageTransacted";

    string constant public STATEMANAGER_ENTRY_NAME_DELEGATIONS_ATTACH_INSURANCE = "delegationsAttachInsurance";
}