# @version 0.3.9
"""
@title Wormhole CRV Bridge
@license MIT
@author Curve Finance
"""
from vyper.interfaces import ERC20


interface BERC20:
    def burn(_amount: uint256) -> bool: nonpayable

interface Minter:
    def mint(_gauge: address): nonpayable

interface Relayer:
    def sendPayloadToEvm(
        _target_chain: uint16,
        _target_addr: address,
        _payload: Bytes[64],
        _receiver_value: uint256,
        _gas_limit: uint256,
        _refund_chain: uint16,
        _refund_address: address
    ) -> uint64: payable
    def quoteEVMDeliveryPrice(
        _target_chain: uint16, _receiver_value: uint256, _gas_limit: uint256
    ) -> uint256: view


event Bridged:
    user: indexed(address)
    target: indexed(address)
    amount: uint256

event Received:
    user: indexed(address)
    amount: uint256

event TransferOwnership:
    owner: indexed(address)


user_checkpoint: public(constant(bool)) = True


TOKEN: public(immutable(address))
MINTER: public(immutable(address))
WORMHOLE_RELAYER: public(immutable(address))
ST_CHAIN_ID: public(immutable(uint16))  # https://docs.wormhole.com/wormhole/blockchain-environments/contracts


integrate_checkpoint: public(HashMap[address, uint256])
delivered: public(HashMap[bytes32, bool])

owner: public(address)
future_owner: public(address)
is_killed: public(bool)


@external
def __init__(_token: address, _minter: address, _relayer: address, _st_chain_id: uint16):
    TOKEN = _token
    MINTER = _minter
    WORMHOLE_RELAYER = _relayer
    ST_CHAIN_ID = _st_chain_id

    self.owner = msg.sender
    log TransferOwnership(msg.sender)


@payable
@external
@nonreentrant('lock')
def bridge(_to: address, _amount: uint256, _gas_limit: uint256 = 250_000, _refund_address: address = msg.sender):
    assert not self.is_killed
    assert _amount != 0

    assert ERC20(TOKEN).transferFrom(msg.sender, self, _amount)
    assert BERC20(TOKEN).burn(_amount)

    quote: uint256 = Relayer(WORMHOLE_RELAYER).quoteEVMDeliveryPrice(ST_CHAIN_ID, 0, _gas_limit)
    Relayer(WORMHOLE_RELAYER).sendPayloadToEvm(
        ST_CHAIN_ID,
        self,
        _abi_encode(_to, _amount),
        0,
        _gas_limit,
        ST_CHAIN_ID,
        _refund_address,
        value=quote,
    )

    if self.balance != 0:
        raw_call(msg.sender, b"", value=self.balance)

    log Bridged(msg.sender, _to, _amount)


@external
@nonreentrant('lock')
def receiveWormholeMessages(
    _payload: Bytes[64],
    _additional_vaas: DynArray[Bytes[8], 8],
    _source_addr: bytes32,
    _source_chain_id: uint16,
    _delivery_hash: bytes32,
):
    assert msg.sender == WORMHOLE_RELAYER  # dev: only relayer
    assert convert(_source_addr, address) == self  # dev: invalid source
    assert _source_chain_id == ST_CHAIN_ID  # dev: invalid source chain
    assert not self.delivered[_delivery_hash]  # dev: already delivered

    user: address = empty(address)
    amount: uint256 = 0
    user, amount = _abi_decode(_payload, (address, uint256))

    if amount != 0:
        self.integrate_checkpoint[self] += amount
        self.delivered[_delivery_hash] = True

        Minter(MINTER).mint(self)
        ERC20(TOKEN).transfer(user, amount)
        log Received(user, amount)


@view
@external
def quote_bridge(_gas_limit: uint256 = 250_000) -> uint256:
    return Relayer(WORMHOLE_RELAYER).quoteEVMDeliveryPrice(ST_CHAIN_ID, 0, _gas_limit)


@external
def set_killed(_is_killed: bool):
    assert msg.sender == self.owner

    self.is_killed = _is_killed


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