# @version 0.3.10
"""
@title Layer Zero Block Hash Sender
@license MIT
@author Curve Finance
"""

interface LZEndpoint:
    def estimateFees(
        _dstChainId: uint16,
        _userApplication: address,
        _payload: Bytes[64],
        _payInZRO: bool,
        _adapterParams: Bytes[34]
    ) -> uint256: view
    def send(
        _dstChainId: uint16,
        _destination: Bytes[40],
        _payload: Bytes[64],
        _refund_address: address,
        _zroPaymentAddress: address,
        _adapterParams: Bytes[34]
    ): payable


event SetGasLimit:
    gas_limit: uint256

event TransferOwnership:
    owner: indexed(address)


LZ_ENDPOINT: public(constant(address)) = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675


ENCODED_DESTINATION: immutable(Bytes[40])

LZ_CHAIN_ID: public(immutable(uint16))


gas_limit: public(uint256)

owner: public(address)
future_owner: public(address)


@external
def __init__(_gas_limit: uint256, _lz_chain_id: uint16):
    self.gas_limit = _gas_limit
    log SetGasLimit(_gas_limit)

    self.owner = msg.sender
    log TransferOwnership(msg.sender)

    ENCODED_DESTINATION = concat(
        slice(convert(self, bytes32), 12, 20),
        slice(convert(self, bytes32), 12, 20)
    )

    LZ_CHAIN_ID = _lz_chain_id


@payable
@external
def transmit(_block_number: uint256, _refund_address: address = msg.sender):
    """
    @notice Transmit the block hash of a finalized block
    @param _block_number The block number of the block to transmit the hash of
    @param _refund_address The address to refund excess ETH to
    """
    assert block.number - 256 <= _block_number and _block_number < block.number - 64  # dev: invalid block

    LZEndpoint(LZ_ENDPOINT).send(
        LZ_CHAIN_ID,
        ENCODED_DESTINATION,
        _abi_encode(_block_number, blockhash(_block_number)),
        _refund_address,
        empty(address),
        concat(b"\x00\x01", convert(self.gas_limit, bytes32)),
        value=msg.value
    )


@view
@external
def quote() -> uint256:
    """
    @notice Quote the price in ETH to attach when calling the `transmit` function
    """
    return LZEndpoint(LZ_ENDPOINT).estimateFees(
        LZ_CHAIN_ID,
        self,
        empty(Bytes[64]),
        False,
        concat(b"\x00\x01", convert(self.gas_limit, bytes32))
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