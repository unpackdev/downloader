# @version 0.3.10
"""
@title CCIP Block Hash Sender
@license MIT
@author Curve Finance
"""

# https://github.com/smartcontractkit/ccip/blob/ccip-develop/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol
interface Router:
    def getFee(_destinationChainSelector: uint64, _message: EVM2AnyMessage) -> uint256: view
    def ccipSend(_destinationChainSelector: uint64, _message: EVM2AnyMessage) -> bytes32: payable


event Transmission:
    message_id: bytes32

event TransferOwnership:
    owner: indexed(address)

event SetGasLimit:
    gas_limit: uint256

event SetReceiver:
    destination_chain_selector: indexed(uint64)
    receiver: address


# https://github.com/smartcontractkit/ccip/blob/ccip-develop/contracts/src/v0.8/ccip/libraries/Client.sol#L7-L10
struct EVMTokenAmount:
    token: address
    amount: uint256

# https://github.com/smartcontractkit/ccip/blob/ccip-develop/contracts/src/v0.8/ccip/libraries/Client.sol#L20-L27
struct EVM2AnyMessage:
    receiver: Bytes[32]
    data: Bytes[64]
    token_amounts: DynArray[EVMTokenAmount, 1]
    fee_token: address
    extra_args: Bytes[68]

# https://etherscan.io/address/0xd0B5Fc9790a6085b048b8Aa1ED26ca2b3b282CF2#code#F9#L30
struct EVMExtraArgsV1:
    gas_limit: uint256
    strict: bool


CCIP_ROUTER: public(immutable(address))


EVM_EXTRA_ARGS_V1_TAG: constant(bytes4) = 0x97a657c9


selector_to_receiver: public(HashMap[uint64, address])

gas_limit: public(uint256)

owner: public(address)
future_owner: public(address)


@external
def __init__(_ccip_router: address, _gas_limit: uint256):
    self.gas_limit = _gas_limit
    log SetGasLimit(_gas_limit)

    self.owner = msg.sender
    log TransferOwnership(msg.sender)

    CCIP_ROUTER = _ccip_router


@payable
@external
def transmit(_destination_chain_selector: uint64, _block_number: uint256):
    """
    @dev See https://docs.chain.link/ccip/supported-networks/mainnet for chain selectors
    """
    assert block.number - 256 <= _block_number and _block_number < block.number - 64  # dev: invalid block

    message: EVM2AnyMessage = EVM2AnyMessage({
        receiver: _abi_encode(self.selector_to_receiver[_destination_chain_selector]),
        data: _abi_encode(_block_number, blockhash(_block_number)),
        token_amounts: empty(DynArray[EVMTokenAmount, 1]),
        fee_token: empty(address),
        extra_args: _abi_encode(EVMExtraArgsV1({gas_limit: self.gas_limit, strict: False}), method_id=EVM_EXTRA_ARGS_V1_TAG)
    })

    Router(CCIP_ROUTER).ccipSend(_destination_chain_selector, message, value=msg.value)


@view
@external
def quote(_destination_chain_selector: uint64) -> uint256:
    return Router(CCIP_ROUTER).getFee(
        _destination_chain_selector,
        EVM2AnyMessage({
            receiver: _abi_encode(self.selector_to_receiver[_destination_chain_selector]),
            data: _abi_encode(block.number, max_value(uint256)),
            token_amounts: empty(DynArray[EVMTokenAmount, 1]),
            fee_token: empty(address),
            extra_args: _abi_encode(EVMExtraArgsV1({gas_limit: self.gas_limit, strict: False}), method_id=EVM_EXTRA_ARGS_V1_TAG)
        })
    )


@external
def set_gas_limit(_gas_limit: uint256):
    """
    @notice Set the gas limit to use for cross-chain transactions
    @param _gas_limit The gas limit for cross-chain transactions
    """
    assert msg.sender == self.owner  # dev: only owner

    self.gas_limit = _gas_limit
    log SetGasLimit(_gas_limit)


@external
def set_receiver(_destination_chain_selector: uint64, _receiver: address):
    """
    @notice Set the receiver for cross chain transactions
    @param _destination_chain_selector The unique CCIP destination chain selector
    @param _receiver The address on the destination chain to transmit messages to
    """
    assert msg.sender == self.owner

    self.selector_to_receiver[_destination_chain_selector] = _receiver
    log SetReceiver(_destination_chain_selector, _receiver)


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership to `_future_owner`
    @param _future_owner The account to commit as the future owner
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership
    @dev Only the committed future owner can call this function
    """
    assert msg.sender == self.future_owner  # dev: only future owner

    self.owner = msg.sender
    log TransferOwnership(msg.sender)