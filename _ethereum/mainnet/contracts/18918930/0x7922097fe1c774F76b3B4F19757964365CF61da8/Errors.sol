// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


library Errors {

    string public constant OK = '0'; // 'ok'
    string public constant PROXY_ID_NOT_EXIST = '1'; // 'proxy not exist'
    string public constant PROXY_ID_ALREADY_EXIST = '2'; // 'proxy id already exists'
    string public constant LPAD_ONLY_COLLABORATOR_OWNER = '3'; // 'only collaborator,owner can call'
    string public constant LPAD_ONLY_CONTROLLER_COLLABORATOR_OWNER = '4'; //  'only controller,collaborator,owner'
    string public constant LPAD_ONLY_AUTHORITIES_ADDRESS = '5'; // 'only authorities can call'
    string public constant TRANSFER_ETH_FAILED = '6'; // 'transfer eth failed'
    string public constant SENDER_MUST_TX_CALLER = '7'; // 'sender must transaction caller'

    string public constant LPAD_INVALID_ID  = '10';  // 'launchpad invalid id'
    string public constant LPAD_ID_EXISTS   = '11';  // 'launchpadId exists'
    string public constant LPAD_RECEIPT_ADDRESS_INVALID = '12'; // 'receipt must be valid address'
    string public constant LPAD_REFERRAL_FEE_PCT_LIMIT = '13'; // 'referral fee upper limit'
    string public constant LPAD_RECEIPT_MUST_NOT_CONTRACT = '14'; // 'receipt can't be contract address'
    string public constant LPAD_NOT_ENABLE = '15'; // 'launchpad not enable'
    string public constant LPAD_TRANSFER_TO_RECEIPT_FAIL = '16'; // 'transfer to receipt address failed'
    string public constant LPAD_TRANSFER_TO_REFERRAL_FAIL = '17'; // 'transfer to referral address failed'
    string public constant LPAD_TRANSFER_BACK_TO_SENDER_FAIL = '18'; // 'transfer back to sender address failed'
    string public constant LPAD_INPUT_ARRAY_LEN_NOT_MATCH = '19'; // 'input array len not match'
    string public constant LPAD_FEES_PERCENT_INVALID = '20'; // 'fees total percent is not 100%'
    string public constant LPAD_PARAM_LOCKED = '21'; // 'launchpad param locked'
    string public constant LPAD_TRANSFER_TO_LPAD_PROXY_FAIL = '22'; // 'transfer to lpad proxy failed'

    string public constant LPAD_SIMULATE_BUY_OK = '28'; // 'simulate buy ok'
    string public constant LPAD_SIMULATE_OPEN_OK = '29'; // 'simulate open ok'

    string public constant LPAD_SLOT_IDX_INVALID = '30'; // 'launchpad slot idx invalid'
    string public constant LPAD_SLOT_MAX_SUPPLY_INVALID = '31'; // 'max supply invalid'
    string public constant LPAD_SLOT_SALE_QUANTITY = '32'; // 'initial sale quantity must 0'
    string public constant LPAD_SLOT_TARGET_CONTRACT_INVALID = '33'; // "slot target contract address not valid"
    string public constant LPAD_SLOT_ABI_ARRAY_LEN = '34'; // "invalid abi selector array not equal max"
    string public constant LPAD_SLOT_MAX_BUY_QTY_INVALID = '35'; // "max buy qty invalid"
    string public constant LPAD_SLOT_FLAGS_ARRAY_LEN = '36'; // 'flag array len not equal max'
    string public constant LPAD_SLOT_TOKEN_ADDRESS_INVALID = '37';  // 'token must be valid address'
    string public constant LPAD_SLOT_BUY_DISABLE = '38'; // 'launchpad buy disable now'
    string public constant LPAD_SLOT_BUY_FROM_CONTRACT_NOT_ALLOWED = '39'; // 'buy from contract address not allowed)
    string public constant LPAD_SLOT_SALE_NOT_START = '40'; // 'sale not start yet'
    string public constant LPAD_SLOT_MAX_BUY_QTY_PER_TX_LIMIT = '41'; // 'max buy quantity one transaction limit'
    string public constant LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY = '42'; // 'quantity not enough to buy'
    string public constant LPAD_SLOT_PAYMENT_NOT_ENOUGH = '43'; // "payment not enough"
    string public constant LPAD_SLOT_PAYMENT_ALLOWANCE_NOT_ENOUGH = '44'; // 'allowance not enough'
    string public constant LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT = '45'; // "account max buy num limit"
    string public constant LPAD_SLOT_ACCOUNT_BUY_INTERVAL_LIMIT = '46'; // 'account buy interval limit'
    string public constant LPAD_SLOT_ACCOUNT_NOT_IN_WHITELIST = '47'; // 'not in whitelist'
    string public constant LPAD_SLOT_OPENBOX_DISABLE = '48'; // 'launchpad openbox disable now'
    string public constant LPAD_SLOT_OPENBOX_FROM_CONTRACT_NOT_ALLOWED = '49'; // 'not allowed to open from contract address'
    string public constant LPAD_SLOT_ABI_BUY_SELECTOR_INVALID = '50'; // 'buy selector invalid '
    string public constant LPAD_SLOT_ABI_OPENBOX_SELECTOR_INVALID = '51'; // 'openbox selector invalid '
    string public constant LPAD_SLOT_SALE_START_TIME_INVALID = '52'; // 'sale time invalid'
    string public constant LPAD_SLOT_OPENBOX_TIME_INVALID = '53'; // 'openbox time invalid'
    string public constant LPAD_SLOT_PRICE_INVALID = '54'; // 'price must > 0'
    string public constant LPAD_SLOT_CALL_BUY_CONTRACT_FAILED = '55'; // 'call buy contract fail'
    string public constant LPAD_SLOT_CALL_OPEN_CONTRACT_FAILED = '56'; // 'call open contract fail'
    string public constant LPAD_SLOT_CALL_0X_ERC20_PROXY_FAILED = '57'; // 'call 0x erc20 proxy fail'
    string public constant LPAD_SLOT_0X_ERC20_PROXY_INVALID = '58'; // '0x erc20 asset proxy invalid'
    string public constant LPAD_SLOT_ONLY_OPENBOX_WHEN_SOLD_OUT = '59'; // 'only can open box when sold out all'
    string public constant LPAD_SLOT_ERC20_BLC_NOT_ENOUGH = '60'; // "erc20 balance not enough"
    string public constant LPAD_SLOT_PAY_VALUE_NOT_ENOUGH = '61'; // "eth send value not enough"
    string public constant LPAD_SLOT_PAY_VALUE_NOT_NEED = '62'; // 'eth send value not need'
    string public constant LPAD_SLOT_PAY_VALUE_UPPER_NEED = '63'; // 'eth send value upper need value'
    string public constant LPAD_SLOT_OPENBOX_NOT_SUPPORT = '64'; // 'openbox not support'
    string public constant LPAD_SLOT_ERC20_TRANSFER_FAILED = '65'; // 'call erc20 transfer fail'
    string public constant LPAD_SLOT_OPEN_NUM_INIT = '66'; // 'initial open number must 0'
    string public constant LPAD_SLOT_ABI_NOT_FOUND = '67'; // 'not found abi to encode'
    string public constant LPAD_SLOT_SALE_END = '68'; // 'sale end'
    string public constant LPAD_SLOT_SALE_END_TIME_INVALID = '69'; // 'sale end time invalid'
    string public constant LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT = '70'; // 'whitelist buy number limit'
    string public constant LPAD_CONTROLLER_NO_PERMISSION = '71'; // 'controller no permission'
    string public constant LPAD_SLOT_WHITELIST_SALE_NOT_START = '72'; // 'whitelist sale not start yet'
    string public constant LPAD_NOT_VALID_SIGNER = '73'; // 'not valid signer'
    string public constant LPAD_SLOT_WHITELIST_TIME_INVALID = '74'; // white list time invalid
    string public constant LPAD_INVALID_WHITELIST_SIGNATURE_LEN = '75'; // invalid whitelist signature length

    string public constant LPAD_SEPARATOR = ':'; // seprator :
}

