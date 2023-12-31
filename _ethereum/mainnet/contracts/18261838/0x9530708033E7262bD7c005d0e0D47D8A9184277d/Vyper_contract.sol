# @version 0.2.12
# @author skozin <info@lido.fi>
# @licence MIT
# @notice  The Lido DAO stops maintaining the Anchor <> stETH integration. Minting and rewards distribution are discontinued.
#          Withdrawals continue to work.
#          More about here https://research.lido.fi/t/sunsetting-lido-on-terra/2367
from vyper.interfaces import ERC20

interface Burnable:
    def burn(owner: address, amount: uint256): nonpayable

interface Lido:
    def getPooledEthByShares(shares_amount: uint256) -> uint256: view

event Deposited:
    sender: indexed(address)
    amount: uint256
    terra_address: bytes32
    beth_amount_received: uint256

event Withdrawn:
    recipient: indexed(address)
    amount: uint256
    steth_amount_received: uint256

event Refunded:
    recipient: indexed(address)
    beth_amount: uint256
    steth_amount: uint256
    comment: String[1024]

event RefundedBethBurned:
    beth_amount: uint256


event RewardsCollected:
    steth_amount: uint256
    ust_amount: uint256

event AdminChanged:
    new_admin: address

event EmergencyAdminChanged:
    new_emergency_admin: address

event BridgeConnectorUpdated:
    bridge_connector: address

event RewardsLiquidatorUpdated:
    rewards_liquidator: address

event InsuranceConnectorUpdated:
    insurance_connector: address

event LiquidationConfigUpdated:
    liquidations_admin: address
    no_liquidation_interval: uint256
    restricted_liquidation_interval: uint256

event AnchorRewardsDistributorUpdated:
    anchor_rewards_distributor: bytes32

event VersionIncremented:
    new_version: uint256

event OperationsStopped:
    pass

event OperationsResumed:
    pass

# WARNING: since this contract is behind a proxy, don't change the order of the variables
# and don't remove variables during the code upgrades. You can only append new variables
# to the end of the list.

admin: public(address)

beth_token: public(address)
steth_token: public(address)
bridge_connector: public(address)
rewards_liquidator: public(address)
insurance_connector: public(address)
anchor_rewards_distributor: public(bytes32)

liquidations_admin: public(address)
no_liquidation_interval: public(uint256)
restricted_liquidation_interval: public(uint256)

last_liquidation_time: public(uint256)
last_liquidation_share_price: public(uint256)
last_liquidation_shares_burnt: public(uint256)

# The contract version. Used to mark backwards-incompatible changes to the contract
# logic, including installing delegates with an incompatible API. Can be changed
# in `_initialize_vX` after implementation.
#
# The following functions revert unless the value of the `_expected_version` argument
# matches the one stored in this state variable:
#
# * `withdraw`
#
# It's recommended for any external code interacting with this contract, both onchain
# and offchain, to have the current version set as a configurable parameter to make
# sure any incompatible change to the contract logic won't produce unexpected results,
# reverting the transactions instead until the compatibility is manually checked and
# the configured version is updated.
#
version: public(uint256)

emergency_admin: public(address)
operations_allowed: public(bool)

total_beth_refunded: public(uint256)

@internal
def _assert_version(_expected_version: uint256):
    assert _expected_version == self.version, "unexpected contract version"

@internal
def _assert_admin(addr: address):
    assert addr == self.admin # dev: unauthorized

@external
def __init__():
    # dev: Prevents initialization of an implementation sitting behind a proxy.
    assert self.version == 0 # dev: already initialized
    self.version = MAX_UINT256

@external
def pause():
    """
    @dev Stops the operations of the contract. Can only be called
    by the contract' admin.

    While contract is in the stopped state, the following functions revert:

    * `withdraw`

    See `resume`.
    """
    self._assert_admin(msg.sender)
    assert self.operations_allowed # dev: stopped
    self.operations_allowed = False
    log OperationsStopped()

@external
def resume():
    """
    @dev Resumes normal operations of the contract. Can only be called
    by the contract' admin.

    See `pause`.
    """
    self._assert_admin(msg.sender)
    assert not self.operations_allowed # dev: not stopped
    self.operations_allowed = True
    log OperationsResumed()

@external
def change_admin(new_admin: address):
    """
    @dev Changes the admin address. Can only be called by the contract' admin.

    Setting the admin to zero ossifies the contract, i.e. makes it irreversibly non-administrable.
    """
    self._assert_admin(msg.sender)
    # we're explicitly allowing zero admin address for ossification
    self.admin = new_admin
    log AdminChanged(new_admin)

@internal
@view
def _get_rate() -> uint256:
    steth_balance: uint256 = ERC20(self.steth_token).balanceOf(self)
    beth_supply: uint256 = ERC20(self.beth_token).totalSupply() - self.total_beth_refunded
    if steth_balance >= beth_supply:
        return 10**18

    return (steth_balance * 10**18) / beth_supply

@external
@view
def get_rate() -> uint256:
    """
    @dev How much bETH one needs to provide to withdraw one stETH, 10**18 being the 1:1 rate.

    This rate is normally 10**18 (1:1) but might be different after severe penalties inflicted
    on the Lido validators.
    """
    return self._get_rate()

@external
@payable
def submit(
    _amount: uint256,
    _terra_address: bytes32,
    _extra_data: Bytes[1024],
    _expected_version: uint256
) -> (uint256, uint256):
    """
    @dev The Lido DAO stops maintaining the Anchor <> stETH integration. Minting and rewards distribution are discontinued.
         Withdrawals continue to work.

    Context: https://research.lido.fi/t/sunsetting-lido-on-terra/2367.
    """
    raise "Minting is discontinued"

@internal
def _withdraw(recipient: address, beth_amount: uint256, steth_rate: uint256) -> uint256:
    steth_amount: uint256 = (beth_amount * steth_rate) / 10**18
    ERC20(self.steth_token).transfer(recipient, steth_amount)
    return steth_amount

@external
def withdraw(
    _beth_amount: uint256,
    _expected_version: uint256,
    _recipient: address = msg.sender
) -> uint256:
    """
    @dev Burns the `_beth_amount` of provided Ethereum-side bETH tokens in return for stETH
         tokens transferred to the `_recipient` Ethereum address.

    To withdraw Terra-side bETH, you should firstly transfer the tokens to the Ethereum
    blockchain.

    The conversion rate from stETH to bETH should normally be 1 but might be different after
    severe penalties inflicted on the Lido validators.
    """
    assert self.operations_allowed, "contract stopped"
    self._assert_version(_expected_version)

    steth_rate: uint256 = self._get_rate()
    Burnable(self.beth_token).burn(msg.sender, _beth_amount)
    steth_amount: uint256 = self._withdraw(_recipient, _beth_amount, steth_rate)

    log Withdrawn(_recipient, _beth_amount, steth_amount)

    return steth_amount

@external
def finalize_upgrade_v4():
    """
    @dev Performs state changes required for proxy upgrade from version 3 to version 4.

    Can only be called by the contract' admin.
    """
    self._assert_admin(msg.sender)
    self._assert_version(3)

    self.version = 4
    self.emergency_admin = ZERO_ADDRESS
    self.bridge_connector = ZERO_ADDRESS
    self.rewards_liquidator = ZERO_ADDRESS
    self.insurance_connector = ZERO_ADDRESS
    self.anchor_rewards_distributor = empty(bytes32)
    self.liquidations_admin = ZERO_ADDRESS
    self.no_liquidation_interval = 0
    self.restricted_liquidation_interval = 0

    self.last_liquidation_time = 0
    self.last_liquidation_share_price = 0
    self.last_liquidation_shares_burnt = 0

    log VersionIncremented(4)
    log EmergencyAdminChanged(ZERO_ADDRESS)
    log BridgeConnectorUpdated(ZERO_ADDRESS)
    log RewardsLiquidatorUpdated(ZERO_ADDRESS)
    log InsuranceConnectorUpdated(ZERO_ADDRESS)
    log AnchorRewardsDistributorUpdated(empty(bytes32))
    log LiquidationConfigUpdated(
        ZERO_ADDRESS,
        0,
        0
    )

@external
def collect_rewards() -> uint256:
    """
    @dev The Lido DAO stops maintaining the Anchor <> stETH integration. Minting and rewards distribution are discontinued.
         Withdrawals continue to work.
    """
    raise "Collect rewards stopped"