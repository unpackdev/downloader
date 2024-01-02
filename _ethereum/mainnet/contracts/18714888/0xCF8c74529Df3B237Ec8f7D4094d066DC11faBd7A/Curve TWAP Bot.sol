#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version shanghai
"""
@title Curve TWAP Bot
@license Apache 2.0
@author Volume.finance
"""

struct Deposit:
    depositor: address
    route: address[11]
    swap_params: uint256[5][5]
    pools: address[5]
    input_amount: uint256
    number_trades: uint256
    interval: uint256
    remaining_counts: uint256
    starting_time: uint256

struct SwapInfo:
    route: address[11]
    swap_params: uint256[5][5]
    amount: uint256
    pools: address[5]

interface WrappedEth:
    def deposit(): payable

interface CurveSwapRouter:
    def exchange(_route: address[11], _swap_params: uint256[5][5], _amount: uint256, _expected: uint256, _pools: address[5], _receiver: address) -> uint256: payable

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
ROUTER: immutable(address)
MAX_SIZE: constant(uint256) = 8
DENOMINATOR: constant(uint256) = 10 ** 18
compass_evm: public(address)
deposit_list: HashMap[uint256, Deposit]
next_deposit: public(uint256)
refund_wallet: public(address)
fee: public(uint256)
paloma: public(bytes32)
service_fee_collector: public(address)
service_fee: public(uint256)

event Deposited:
    deposit_id: uint256
    token0: address
    token1: address
    input_amount: uint256
    number_trades: uint256
    interval: uint256
    starting_time: uint256
    depositor: address

event Swapped:
    deposit_id: uint256
    remaining_counts: uint256
    amount: uint256
    out_amount: uint256

event Canceled:
    deposit_id: uint256

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event UpdateFee:
    old_fee: uint256
    new_fee: uint256

event SetPaloma:
    paloma: bytes32

event UpdateServiceFeeCollector:
    old_service_fee_collector: address
    new_service_fee_collector: address

event UpdateServiceFee:
    old_service_fee: uint256
    new_service_fee: uint256

@external
def __init__(_compass_evm: address, router: address, _refund_wallet: address, _fee: uint256, _service_fee_collector: address, _service_fee: uint256):
    self.compass_evm = _compass_evm
    ROUTER = router
    self.refund_wallet = _refund_wallet
    self.fee = _fee
    self.service_fee_collector = _service_fee_collector
    assert _service_fee < DENOMINATOR
    self.service_fee = _service_fee
    log UpdateCompass(empty(address), _compass_evm)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateFee(0, _fee)
    log UpdateServiceFeeCollector(empty(address), _service_fee_collector)
    log UpdateServiceFee(0, _service_fee)

@external
@payable
@nonreentrant('lock')
def deposit(swap_infos: DynArray[SwapInfo, MAX_SIZE], number_trades: uint256, interval: uint256, starting_time: uint256):
    _value: uint256 = msg.value
    assert self.paloma != empty(bytes32), "Paloma not set"
    _fee: uint256 = self.fee
    if _fee > 0:
        _fee = _fee * number_trades
        assert _value >= _fee, "Insufficient fee"
        send(self.refund_wallet, _fee)
        _value = unsafe_sub(_value, _fee)
    _next_deposit: uint256 = self.next_deposit
    for swap_info in swap_infos:
        last_index: uint256 = 0
        for i in range(5):
            last_index = unsafe_sub(10, unsafe_add(i, i))
            if swap_info.route[last_index] != empty(address):
                break
        assert swap_info.amount > 0, "Insufficient deposit"
        token1: address = swap_info.route[last_index]
        if swap_info.route[0] == VETH:
            assert _value >= swap_info.amount, "Insufficient deposit"
            _value = unsafe_sub(_value, swap_info.amount)
        else:
            assert ERC20(swap_info.route[0]).transferFrom(msg.sender, self, swap_info.amount, default_return_value = True), "failed transferFrom"
        _starting_time: uint256 = starting_time
        if starting_time <= block.timestamp:
            _starting_time = block.timestamp
        assert number_trades > 0, "Wrong trade count"
        self.deposit_list[_next_deposit] = Deposit({
            depositor: msg.sender,
            route: swap_info.route,
            swap_params: swap_info.swap_params,
            pools: swap_info.pools,
            input_amount: swap_info.amount,
            number_trades: number_trades,
            interval: interval,
            remaining_counts: number_trades,
            starting_time: _starting_time
        })
        log Deposited(_next_deposit, swap_info.route[0], swap_info.route[last_index], swap_info.amount, number_trades, interval, _starting_time, msg.sender)
        _next_deposit = unsafe_add(_next_deposit, 1)
    self.next_deposit = _next_deposit
    if _value > 0:
        send(msg.sender, _value)

@internal
def _swap(deposit_id: uint256, remaining_count: uint256, amount_out_min: uint256, count_check: bool = True) -> uint256:
    _deposit: Deposit = self.deposit_list[deposit_id]
    if count_check:
        assert _deposit.remaining_counts == remaining_count, "wrong count"
    _amount: uint256 = _deposit.input_amount / _deposit.remaining_counts
    _deposit.input_amount = unsafe_sub(_deposit.input_amount, _amount)
    _deposit.remaining_counts = unsafe_sub(_deposit.remaining_counts, 1)
    self.deposit_list[deposit_id] = _deposit
    _out_amount: uint256 = 0
    last_index: uint256 = 0
    for i in range(5):
        last_index = unsafe_sub(10, unsafe_add(i, i))
        if _deposit.route[last_index] != empty(address):
            break
    if _deposit.route[0] == VETH:
        _out_amount = CurveSwapRouter(ROUTER).exchange(_deposit.route, _deposit.swap_params, _amount, amount_out_min, _deposit.pools, self, value=_amount)
    else:
        assert ERC20(_deposit.route[0]).approve(ROUTER, _amount, default_return_value = True), "failed approve"
        _out_amount = CurveSwapRouter(ROUTER).exchange(_deposit.route, _deposit.swap_params, _amount, amount_out_min, _deposit.pools, self)
    actual_amount: uint256 = _out_amount
    service_fee_amount: uint256 = 0
    _service_fee: uint256 = self.service_fee
    if _service_fee > 0:
        service_fee_amount = unsafe_div(_out_amount * _service_fee, DENOMINATOR)
        actual_amount = unsafe_sub(actual_amount, service_fee_amount)
    if _deposit.route[last_index] == VETH:
        send(_deposit.depositor, actual_amount)
        if service_fee_amount > 0:
            send(self.service_fee_collector, service_fee_amount)
    else:
        assert ERC20(_deposit.route[last_index]).transfer(_deposit.depositor, actual_amount, default_return_value = True), "failed transfer"
        if service_fee_amount > 0:
            assert ERC20(_deposit.route[last_index]).transfer(self.service_fee_collector, service_fee_amount, default_return_value = True), "failed transfer"
    log Swapped(deposit_id, _deposit.remaining_counts, _amount, _out_amount)
    return _out_amount

@external
@nonreentrant('lock')
def multiple_swap(deposit_id: DynArray[uint256, MAX_SIZE], remaining_counts: DynArray[uint256, MAX_SIZE], amount_out_min: DynArray[uint256, MAX_SIZE]):
    assert msg.sender == self.compass_evm, "Unauthorized"
    _len: uint256 = len(deposit_id)
    assert _len == len(amount_out_min) and _len == len(remaining_counts), "Validation error"
    _len = unsafe_add(unsafe_mul(unsafe_add(_len, 2), 96), 36)
    assert len(msg.data) == _len, "invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(_len, 32), 32), bytes32), "invalid paloma"
    for i in range(MAX_SIZE):
        if i >= len(deposit_id):
            break
        self._swap(deposit_id[i], remaining_counts[i], amount_out_min[i])

@external
def multiple_swap_view(deposit_id: DynArray[uint256, MAX_SIZE], remaining_counts: DynArray[uint256, MAX_SIZE]) -> DynArray[uint256, MAX_SIZE]:
    assert msg.sender == empty(address) # only for view function
    _len: uint256 = len(deposit_id)
    res: DynArray[uint256, MAX_SIZE] = []
    for i in range(MAX_SIZE):
        if i >= len(deposit_id):
            break
        res.append(self._swap(deposit_id[i], remaining_counts[i], 1, False))
    return res

@external
@nonreentrant('lock')
def cancel(deposit_id: uint256):
    _deposit: Deposit = self.deposit_list[deposit_id]
    assert _deposit.depositor == msg.sender, "Unauthorized"
    assert _deposit.input_amount > 0, "all traded"
    if _deposit.route[0] == VETH:
        send(msg.sender, _deposit.input_amount)
    else:
        assert ERC20(_deposit.route[0]).transfer(msg.sender, _deposit.input_amount, default_return_value = True), "failed transfer"
    _deposit.input_amount = 0
    _deposit.remaining_counts = 0
    self.deposit_list[deposit_id] = _deposit
    log Canceled(deposit_id)

@external
@nonreentrant('lock')
def multiple_cancel(deposit_ids: DynArray[uint256, MAX_SIZE]):
    for deposit_id in deposit_ids:
        _deposit: Deposit = self.deposit_list[deposit_id]
        assert _deposit.depositor == msg.sender, "Unauthorized"
        assert _deposit.input_amount > 0, "all traded"
        if _deposit.route[0] == VETH:
            send(msg.sender, _deposit.input_amount)
        else:
            assert ERC20(_deposit.route[0]).transfer(msg.sender, _deposit.input_amount, default_return_value = True), "failed transfer"
        _deposit.input_amount = 0
        _deposit.remaining_counts = 0
        self.deposit_list[deposit_id] = _deposit
        log Canceled(deposit_id)

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    self.compass_evm = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_refund_wallet(new_refund_wallet: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_fee(new_fee: uint256):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_fee: uint256 = self.fee
    self.fee = new_fee
    log UpdateFee(old_fee, new_fee)

@external
def set_paloma():
    assert msg.sender == self.compass_evm and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def update_service_fee_collector(new_service_fee_collector: address):
    assert msg.sender == self.service_fee_collector, "Unauthorized"
    self.service_fee_collector = new_service_fee_collector
    log UpdateServiceFeeCollector(msg.sender, new_service_fee_collector)

@external
def update_service_fee(new_service_fee: uint256):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    assert new_service_fee < DENOMINATOR, "Wrong service fee"
    old_service_fee: uint256 = self.service_fee
    self.service_fee = new_service_fee
    log UpdateServiceFee(old_service_fee, new_service_fee)

@external
@payable
def __default__():
    pass