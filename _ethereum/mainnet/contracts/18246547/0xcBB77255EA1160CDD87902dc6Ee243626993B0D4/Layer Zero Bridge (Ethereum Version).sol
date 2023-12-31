# @version 0.3.9
"""
@title Layer Zero Bridge (Ethereum Version)
@license MIT
@author Curve Finance
"""
from vyper.interfaces import ERC20


interface BERC20:
    def burn(_value: uint256) -> bool: nonpayable

interface Minter:
    def mint(_gauge: address): nonpayable

interface Endpoint:
    def send(
        _dst_chain_id: uint16,
        _destination: Bytes[40],
        _payload: Bytes[64],
        _refund_address: address,
        _zro_payment_address: address,
        _adapter_params: Bytes[86]
    ): payable
    def estimateFees(
        _dst_chain_id: uint16,
        _user_application: address,
        _payload: Bytes[64],
        _pay_in_zro: bool,
        _adapter_params: Bytes[86]
    ) -> uint256: view


event SetKilled:
    killed: bool

event SetDelay:
    delay: uint256

event SetLimit:
    limit: uint256

event Bridged:
    receiver: indexed(address)
    amount: uint256

event Delayed:
    nonce: indexed(uint64)
    receiver: indexed(address)
    amount: uint256

event Issued:
    nonce: indexed(uint64)
    receiver: indexed(address)
    amount: uint256

event TransferOwnership:
    owner: indexed(address)


CRV20: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
MINTER: constant(address) = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0
ISSUANCE_INTERVAL: constant(uint256) = 86400

LZ_ENDPOINT: public(constant(address)) = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675


LZ_CHAIN_ID: public(immutable(uint16))
LZ_ADDRESS: immutable(Bytes[40])
KECCAK_LZ_ADDRESS: immutable(bytes32)


minted: public(uint256)

limit: public(uint256)
delay: public(uint256)
issued: public(HashMap[uint256, uint256])
delayed: public(HashMap[uint64, bytes32])


owner: public(address)
future_owner: public(address)

is_killed: public(bool)


@external
def __init__(_delay: uint256, _limit: uint256, _lz_chain_id: uint16):
    self.delay = _delay
    log SetDelay(_delay)

    self.limit = _limit
    log SetLimit(_limit)

    self.owner = msg.sender
    log TransferOwnership(msg.sender)

    LZ_CHAIN_ID = _lz_chain_id
    LZ_ADDRESS = concat(
        slice(convert(self, bytes32), 12, 20), slice(convert(self, bytes32), 12, 20)
    )
    KECCAK_LZ_ADDRESS = keccak256(LZ_ADDRESS)


@payable
@external
def bridge(
    _amount: uint256,
    _receiver: address = msg.sender,
    _refund_address: address = msg.sender,
    _zro_payment_address: address = empty(address),
    _native_amount: uint256 = 0,
    _native_receiver: address = empty(address)
):
    """
    @notice Bridge CRV
    """
    assert not self.is_killed  # dev: dead
    assert _amount != 0 and _receiver != empty(address)  # dev: invalid

    assert ERC20(CRV20).transferFrom(msg.sender, self, _amount)
    assert BERC20(CRV20).burn(_amount)

    adapter_params: Bytes[86] = b""
    if _native_amount == 0:
        adapter_params = concat(
            b"\x00\x01",
            convert(500_000, bytes32)
        )
    else:
        adapter_params = concat(
            b"\x00\x02",
            convert(500_000, bytes32),
            convert(_native_amount, bytes32),
            slice(convert(_native_receiver, bytes32), 12, 20)
        )

    Endpoint(LZ_ENDPOINT).send(
        LZ_CHAIN_ID,
        LZ_ADDRESS,
        _abi_encode(_receiver, _amount),
        _refund_address,
        _zro_payment_address,
        adapter_params,
        value=msg.value
    )
    log Bridged(_receiver, _amount)


@external
def lzReceive(_lz_chain_id: uint16, _lz_address: Bytes[40], _nonce: uint64, _payload: Bytes[64]):
    """
    @dev LayerZero method which should not revert at all
    """
    assert msg.sender == LZ_ENDPOINT  # dev: invalid caller

    assert _lz_chain_id == LZ_CHAIN_ID  # dev: invalid source chain
    assert keccak256(_lz_address) == KECCAK_LZ_ADDRESS  # dev: invalid source address

    receiver: address = empty(address)
    amount: uint256 = empty(uint256)
    receiver, amount = _abi_decode(_payload, (address, uint256))

    if receiver == empty(address) or amount == 0:
        # precaution
        return

    period: uint256 = block.timestamp / ISSUANCE_INTERVAL
    issued: uint256 = self.issued[period] + amount

    if issued > self.limit or self.is_killed:
        self.delayed[_nonce] = keccak256(_abi_encode(block.timestamp, _payload))
        log Delayed(_nonce, receiver, amount)
    else:
        self.issued[period] = issued
        self.minted += amount

        Minter(MINTER).mint(self)
        ERC20(CRV20).transfer(receiver, amount)

        log Issued(_nonce, receiver, amount)


@external
def retry(_nonce: uint64, _timestamp: uint256, _receiver: address, _amount: uint256):
    """
    @notice Retry a previously delayed bridge attempt
    """
    assert not self.is_killed  # dev: dead

    assert _timestamp < block.timestamp + self.delay  # dev: too soon
    assert self.delayed[_nonce] == keccak256(
        _abi_encode(_timestamp, _abi_encode(_receiver, _amount))
    )  # dev: incorrect

    self.delayed[_nonce] = empty(bytes32)
    self.minted += _amount

    Minter(MINTER).mint(self)
    ERC20(CRV20).transfer(_receiver, _amount)

    log Issued(_nonce, _receiver, _amount)


@view
@external
def quote(_native_amount: uint256 = 0) -> uint256:
    """
    @notice Quote the cost of calling the `bridge` method
    """
    adapter_params: Bytes[86] = b""
    if _native_amount == 0:
        adapter_params = concat(
            b"\x00\x01",
            convert(500_000, bytes32)
        )
    else:
        adapter_params = concat(
            b"\x00\x02",
            convert(500_000, bytes32),
            convert(_native_amount, bytes32),
            b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        )

    return Endpoint(LZ_ENDPOINT).estimateFees(
        LZ_CHAIN_ID,
        self,
        concat(empty(bytes32), empty(bytes32)),
        False,
        adapter_params
    )


@external
def user_checkpoint(_user: address) -> bool:
    assert _user == self  # dev: only gauge

    return True


@view
@external
def integrate_fraction(_user: address) -> uint256:
    """
    @dev The only account permitted to receive CRV via the Minter is this gauge
    """
    assert _user == self  # dev: only gauge

    return self.minted


@external
def set_delay(_delay: uint256):
    """
    @notice Set the delay for retrying a delayed bridge attempt
    """
    assert msg.sender == self.owner

    self.delay = _delay
    log SetDelay(_delay)


@external
def set_limit(_limit: uint256):
    """
    @notice Set the issuance limit for the issuance interval
    """
    assert msg.sender == self.owner

    self.limit = _limit
    log SetLimit(_limit)


@external
def set_killed(_killed: bool):
    """
    @notice Set the kill status of this side of the bridge
    """
    assert msg.sender == self.owner

    self.is_killed = _killed
    log SetKilled(_killed)


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