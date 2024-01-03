pragma solidity 0.8.17;

struct DLNData {
    address takeTokenAddress;
    uint256 takeAmount;
    uint256 actualInputAmount;
    uint256 nativeFee;
}

struct OrderCreation {
    address giveTokenAddress; // => src input token address
    uint256 giveAmount;
    bytes takeTokenAddress; // => dst final receive token address
    uint256 takeAmount;
    uint256 takeChainId;
    bytes receiverDst; // => if only bridge, user addr, otherwhise contract
    address givePatchAuthoritySrc; // => if only bridge, user addr, otherwhise contract
    bytes orderAuthorityAddressDst; // => if only bridge, user addr, otherwhise contract
    bytes allowedTakerDst; // => 0x
    bytes externalCall; // => 0x
    bytes allowedCancelBeneficiarySrc; // => 0x
}

interface IDLN {
    function createOrder(
        OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee, // => 0x
        uint32 _referralCode, // => 0
        bytes calldata _permitEnvelope // => 0x
    ) external payable returns (bytes32);
}
