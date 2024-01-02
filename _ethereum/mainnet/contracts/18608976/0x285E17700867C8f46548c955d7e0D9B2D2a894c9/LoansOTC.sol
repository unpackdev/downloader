# @version 0.3.9

"""
@title LoansOTC
@author [Zharta](https://zharta.io/)
@notice The loans contract exists as the main interface to create peer-to-pool NFT-backed loans
"""

# Interfaces

from vyper.interfaces import ERC165 as IERC165
from vyper.interfaces import ERC721 as IERC721
from vyper.interfaces import ERC20 as IERC20

interface ICollateralVault:
    def storeCollateral(_wallet: address, _collateralAddress: address, _tokenId: uint256, _erc20TokenContract: address, _createDelegation: bool): nonpayable
    def transferCollateralFromLoan(_wallet: address, _collateralAddress: address, _tokenId: uint256, _erc20TokenContract: address): nonpayable
    def isCollateralApprovedForVault(_borrower: address, _collateralAddress: address, _tokenId: uint256) -> bool: view
    def setCollateralDelegation(_wallet: address, _collateralAddress: address, _tokenId: uint256, _erc20TokenContract: address, _value: bool): nonpayable

interface IERC20Symbol:
    def symbol() -> String[100]: view

interface ILendingPool:
    def maxFundsInvestable() -> uint256: view 
    def erc20TokenContract() -> address: view
    def sendFundsEth(_to: address, _amount: uint256): nonpayable
    def sendFunds(_to: address, _amount: uint256): nonpayable
    def receiveFundsEth(_borrower: address, _amount: uint256, _rewardsAmount: uint256): payable
    def receiveFunds(_borrower: address, _amount: uint256, _rewardsAmount: uint256): payable

interface ILiquidations:
    def addLiquidation(_borrower: address, _loanId: uint256, _erc20TokenContract: address): nonpayable

interface ISelf:
    def initialize(
        _owner: address,
        _interestAccrualPeriod: uint256,
        _lendingPoolContract: address,
        _collateralVaultContract: address,
        _genesisContract: address,
        _isPayable: bool
    ): nonpayable


# Structs

struct Collateral:
    contractAddress: address
    tokenId: uint256
    amount: uint256

struct Loan:
    id: uint256
    amount: uint256
    interest: uint256 # parts per 10000, e.g. 2.5% is represented by 250 parts per 10000
    maturity: uint256
    startTime: uint256
    collaterals: DynArray[Collateral, 100]
    paidPrincipal: uint256
    paidInterestAmount: uint256
    started: bool
    invalidated: bool
    paid: bool
    defaulted: bool
    canceled: bool


struct EIP712Domain:
    name: String[100]
    version: String[10]
    chain_id: uint256
    verifying_contract: address

struct ReserveMessageContent:
    amount: uint256
    interest: uint256
    maturity: uint256
    collaterals: DynArray[Collateral, 100]
    delegations: DynArray[bool, 100]
    deadline: uint256


# Events

event ProxyCreated:
    proxyAddress: address
    owner: address
    interestAccrualPeriod: uint256
    lendingPoolContract: address
    collateralVaultContract: address
    genesisContract: address
    isPayable: bool

event OwnershipTransferred:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event OwnerProposed:
    ownerIndexed: indexed(address)
    proposedOwnerIndexed: indexed(address)
    owner: address
    proposedOwner: address
    erc20TokenContract: address

event AdminTransferred:
    currentValue: address
    newValue: address


event InterestAccrualPeriodChanged:
    erc20TokenContractIndexed: indexed(address)
    currentValue: uint256
    newValue: uint256
    erc20TokenContract: address

event LendingPoolPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event CollateralVaultPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event LiquidationsPeripheralAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event LiquidityControlsAddressSet:
    erc20TokenContractIndexed: indexed(address)
    currentValue: address
    newValue: address
    erc20TokenContract: address

event ContractStatusChanged:
    erc20TokenContractIndexed: indexed(address)
    value: bool
    erc20TokenContract: address

event ContractDeprecated:
    erc20TokenContractIndexed: indexed(address)
    erc20TokenContract: address

event LoanCreated:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    erc20TokenContract: address
    apr: uint256 # calculated from the interest to 365 days, in bps
    amount: uint256
    duration: uint256
    collaterals: DynArray[Collateral, 100]
    genesisToken: uint256

event LoanPayment:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    principal: uint256
    interestAmount: uint256
    erc20TokenContract: address

event LoanPaid:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    erc20TokenContract: address

event LoanDefaulted:
    walletIndexed: indexed(address)
    wallet: address
    loanId: uint256
    amount: uint256
    erc20TokenContract: address

event PaymentSent:
    walletIndexed: indexed(address)
    wallet: address
    amount: uint256

event PaymentReceived:
    walletIndexed: indexed(address)
    wallet: address
    amount: uint256


# Global variables

owner: public(address)
admin: public(address)
proposedOwner: public(address)

interestAccrualPeriod: public(uint256)

isAcceptingLoans: public(bool)
isDeprecated: public(bool)

lendingPoolContract: public(ILendingPool)
erc20TokenContract: public(address)
collateralVaultContract: public(ICollateralVault)
liquidationsContract: public(ILiquidations)
genesisContract: public(IERC721)
isPayable: public(bool)

loans: HashMap[address, DynArray[Loan, 2**16]]

ZHARTA_DOMAIN_NAME: constant(String[6]) = "Zharta"
ZHARTA_DOMAIN_VERSION: constant(String[1]) = "1"

COLLATERAL_TYPE_DEF: constant(String[66]) = "Collateral(address contractAddress,uint256 tokenId,uint256 amount)"
RESERVE_TYPE_DEF: constant(String[269]) = "ReserveMessageContent(address borrower,uint256 amount,uint256 interest,uint256 maturity,Collateral[] collaterals," \
                                          "bool delegations,uint256 deadline,uint256 nonce,uint256 genesisToken)" \
                                          "Collateral(address contractAddress,uint256 tokenId,uint256 amount)"
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
COLLATERAL_TYPE_HASH: constant(bytes32) = keccak256(COLLATERAL_TYPE_DEF)
RESERVE_TYPE_HASH: constant(bytes32) = keccak256(RESERVE_TYPE_DEF)

reserve_message_typehash: bytes32
reserve_sig_domain_separator: bytes32

MINIMUM_INTEREST_PERIOD: constant(uint256) = 604800  # 7 days


@external
def __init__():
    self.owner = msg.sender
    self.isAcceptingLoans = False
    self.isDeprecated = True


@external
def initialize(
    _owner: address,
    _interestAccrualPeriod: uint256,
    _lendingPoolContract: address,
    _collateralVaultContract: address,
    _genesisContract: address,
    _isPayable: bool
):
    assert self.owner == empty(address), "already initialized"

    assert _lendingPoolContract != empty(address), "address is the zero address"
    assert _collateralVaultContract != empty(address), "address is the zero address"
    assert _genesisContract != empty(address), "address is the zero address"

    self.owner = _owner
    self.admin = _owner
    self.interestAccrualPeriod = _interestAccrualPeriod
    self.lendingPoolContract = ILendingPool(_lendingPoolContract)
    self.erc20TokenContract = ILendingPool(_lendingPoolContract).erc20TokenContract()
    self.collateralVaultContract = ICollateralVault(_collateralVaultContract)
    self.genesisContract = IERC721(_genesisContract)
    self.isAcceptingLoans = True
    self.isPayable = _isPayable

    self.reserve_sig_domain_separator = keccak256(
        _abi_encode(
            DOMAIN_TYPE_HASH,
            keccak256(ZHARTA_DOMAIN_NAME),
            keccak256(ZHARTA_DOMAIN_VERSION),
            chain.id,
            self
        )
    )


@external
def create_proxy(
    _interestAccrualPeriod: uint256,
    _lendingPoolContract: address,
    _collateralVaultContract: address,
    _genesisContract: address,
    _isPayable: bool
) -> address:
    proxy: address = create_minimal_proxy_to(self)

    ISelf(proxy).initialize(
        msg.sender,
        _interestAccrualPeriod,
        _lendingPoolContract,
        _collateralVaultContract,
        _genesisContract,
        _isPayable
    )

    log ProxyCreated(
        proxy,
        msg.sender,
        _interestAccrualPeriod,
        _lendingPoolContract,
        _collateralVaultContract,
        _genesisContract,
        _isPayable
    )

    return proxy


##### INTERNAL METHODS #####

@view
@internal
def _is_loan_created(_borrower: address, _loanId: uint256) -> bool:
    return _loanId < len(self.loans[_borrower])


@internal
def _are_collaterals_owned(_borrower: address, _collaterals: DynArray[Collateral, 100]) -> bool:
    for collateral in _collaterals:
        if IERC721(collateral.contractAddress).ownerOf(collateral.tokenId) != _borrower:
            return False
    return True


@view
@internal
def _get_loan(_borrower: address, _loanId: uint256) -> Loan:
  if self._is_loan_created(_borrower, _loanId):
    return self.loans[_borrower][_loanId]
  return empty(Loan)


@internal
def _add_loan(
    _borrower: address,
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100]
) -> uint256:

    new_loan: Loan = Loan(
        {
            id: len(self.loans[_borrower]),
            amount: _amount,
            interest: _interest,
            maturity: _maturity,
            startTime: block.timestamp,
            collaterals: _collaterals,
            paidPrincipal: 0,
            paidInterestAmount: 0,
            started: True,
            invalidated: False,
            paid: False,
            defaulted: False,
            canceled: False,
        }
    )

    self.loans[_borrower].append(new_loan)

    return new_loan.id


@internal
def _update_loan_paid_amount(_borrower: address, _loanId: uint256, _paidPrincipal: uint256, _paidInterestAmount: uint256):
    self.loans[_borrower][_loanId].paidPrincipal += _paidPrincipal
    self.loans[_borrower][_loanId].paidInterestAmount += _paidInterestAmount


@internal
def _update_paid_loan(_borrower: address, _loanId: uint256):
    self.loans[_borrower][_loanId].paid = True


@internal
def _update_defaulted_loan(_borrower: address, _loanId: uint256):
    self.loans[_borrower][_loanId].defaulted = True

@view
@internal
def _are_collaterals_approved(_borrower: address, _collaterals: DynArray[Collateral, 100]) -> bool:
    for collateral in _collaterals:
        if not self.collateralVaultContract.isCollateralApprovedForVault(
            _borrower,
            collateral.contractAddress,
            collateral.tokenId
        ):
            return False
    return True


@pure
@internal
def _collaterals_amounts(_collaterals: DynArray[Collateral, 100]) -> uint256:
    sumAmount: uint256 = 0
    for collateral in _collaterals:
        sumAmount += collateral.amount

    return sumAmount


@pure
@internal
def _loan_payable_amount(
    _amount: uint256,
    _paidAmount: uint256,
    _interest: uint256,
    _maxLoanDuration: uint256,
    _timePassed: uint256,
    _interestAccrualPeriod: uint256
) -> uint256:
    return (_amount - _paidAmount) * (10000 * _maxLoanDuration + _interest * (max(_timePassed + _interestAccrualPeriod, MINIMUM_INTEREST_PERIOD))) / (10000 * _maxLoanDuration)


@pure
@internal
def _compute_period_passed_in_seconds(_recentTimestamp: uint256, _olderTimestamp: uint256, _period: uint256) -> uint256:
    return (_recentTimestamp - _olderTimestamp) - ((_recentTimestamp - _olderTimestamp) % _period)


@internal
def _recover_reserve_signer(
    _borrower: address,
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _genesisToken: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> address:
    """
        @notice recovers the sender address of the signed reserve function call
    """
    collaterals_data_hash: DynArray[bytes32, 100] = []
    for c in _collaterals:
        collaterals_data_hash.append(keccak256(_abi_encode(COLLATERAL_TYPE_HASH, c.contractAddress, c.tokenId, c.amount)))

    data_hash: bytes32 = keccak256(_abi_encode(
                RESERVE_TYPE_HASH,
                _borrower,
                _amount,
                _interest,
                _maturity,
                keccak256(slice(_abi_encode(collaterals_data_hash), 32*2, 32*len(_collaterals))),
                _delegations,
                _deadline,
                _nonce,
                _genesisToken
                ))

    sig_hash: bytes32 = keccak256(concat(convert("\x19\x01", Bytes[2]), _abi_encode(self.reserve_sig_domain_separator, data_hash)))
    signer: address = ecrecover(sig_hash, _v, _r, _s)

    return signer


@internal
def _reserve(
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _genesisToken: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> uint256:
    assert not self.isDeprecated, "contract is deprecated"
    assert self.isAcceptingLoans, "contract is not accepting loans"
    assert block.timestamp < _maturity, "maturity is in the past"
    assert block.timestamp <= _deadline, "deadline has passed"
    assert self._collaterals_amounts(_collaterals) == _amount, "amount in collats != than amount"
    assert self.lendingPoolContract.maxFundsInvestable() >= _amount, "insufficient liquidity"

    assert not self._is_loan_created(msg.sender, _nonce), "loan already created"
    if _nonce > 0:
        assert self._is_loan_created(msg.sender, _nonce - 1), "loan is not sequential"
    
    signer: address = self._recover_reserve_signer(msg.sender, _amount, _interest, _maturity, _collaterals, _delegations, _deadline, _nonce, _genesisToken, _v, _r, _s)
    assert signer == self.admin, "invalid message signature"

    assert _genesisToken == 0 or self.genesisContract.ownerOf(_genesisToken) == msg.sender, "genesisToken not owned"

    newLoanId: uint256 = self._add_loan(msg.sender, _amount, _interest, _maturity, _collaterals)

    for collateral in _collaterals:

        self.collateralVaultContract.storeCollateral(
            msg.sender,
            collateral.contractAddress,
            collateral.tokenId,
            self.erc20TokenContract,
            _delegations
        )

    log LoanCreated(
        msg.sender,
        msg.sender,
        newLoanId,
        self.erc20TokenContract,
        _interest * 365 * 86400 / (_maturity - block.timestamp),
        _amount,
        _maturity - block.timestamp,
        _collaterals,
        _genesisToken
    )

    return newLoanId


##### EXTERNAL METHODS #####

@view
@external
def loansCoreContract() -> address:
    return self

@view
@external
def getLoanAmount(_borrower: address, _loanId: uint256) -> uint256:
    return self._get_loan(_borrower, _loanId).amount


@view
@external
def getLoanMaturity(_borrower: address, _loanId: uint256) -> uint256:
    return self._get_loan(_borrower, _loanId).maturity


@view
@external
def getLoanInterest(_borrower: address, _loanId: uint256) -> uint256:
    return self._get_loan(_borrower, _loanId).interest


@view
@external
def getLoanCollaterals(_borrower: address, _loanId: uint256) -> DynArray[Collateral, 100]:
    return self._get_loan(_borrower, _loanId).collaterals


@view
@external
def getLoanStartTime(_borrower: address, _loanId: uint256) -> uint256:
    return self._get_loan(_borrower, _loanId).startTime


@view
@external
def getLoanPaidPrincipal(_borrower: address, _loanId: uint256) -> uint256:
    return self._get_loan(_borrower, _loanId).paidPrincipal


@view
@external
def getLoanPaidInterestAmount(_borrower: address, _loanId: uint256) -> uint256:
    return self._get_loan(_borrower, _loanId).paidInterestAmount


@view
@external
def getLoanStarted(_borrower: address, _loanId: uint256) -> bool:
    return self._get_loan(_borrower, _loanId).started


@view
@external
def getLoanInvalidated(_borrower: address, _loanId: uint256) -> bool:
    return self._get_loan(_borrower, _loanId).invalidated


@view
@external
def getLoanPaid(_borrower: address, _loanId: uint256) -> bool:
    return self._get_loan(_borrower, _loanId).paid


@view
@external
def getLoanDefaulted(_borrower: address, _loanId: uint256) -> bool:
    return self._get_loan(_borrower, _loanId).defaulted


@view
@external
def getLoanCanceled(_borrower: address, _loanId: uint256) -> bool:
    if _loanId < len(self.loans[_borrower]):
        return self.loans[_borrower][_loanId].canceled
    return False


@view
@external
def getLoan(_borrower: address, _loanId: uint256) -> Loan:
    return self._get_loan(_borrower, _loanId)


@external
def proposeOwner(_address: address):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _address != empty(address), "_address it the zero address"
    assert self.owner != _address, "proposed owner addr is the owner"
    assert self.proposedOwner != _address, "proposed owner addr is the same"

    self.proposedOwner = _address

    log OwnerProposed(
        self.owner,
        _address,
        self.owner,
        _address,
        self.erc20TokenContract
    )


@external
def claimOwnership():
    assert msg.sender == self.proposedOwner, "msg.sender is not the proposed"

    log OwnershipTransferred(
        self.owner,
        self.proposedOwner,
        self.owner,
        self.proposedOwner,
        self.erc20TokenContract
    )

    self.owner = self.proposedOwner
    self.proposedOwner = empty(address)


@external
def changeInterestAccrualPeriod(_value: uint256):
    """
    @notice Sets the interest accrual period, considered on loan payment calculations
    @dev Logs `InterestAccrualPeriodChanged` event
    @param _value The interest accrual period in seconds
    """
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert _value != self.interestAccrualPeriod, "_value is the same"

    log InterestAccrualPeriodChanged(
        self.erc20TokenContract,
        self.interestAccrualPeriod,
        _value,
        self.erc20TokenContract
    )

    self.interestAccrualPeriod = _value


@external
def changeAdmin(_admin: address):
    assert msg.sender == self.owner  # reason: msg.sender is not the owner
    log AdminTransferred(self.admin, _admin)

    self.admin = _admin

@external
def setLendingPoolPeripheralAddress(_address: address):
    assert msg.sender == self.owner  # reason: msg.sender is not the owner
    assert _address != empty(address)  # reason: address is the zero address

    log LendingPoolPeripheralAddressSet(
        self.erc20TokenContract,
        self.lendingPoolContract.address,
        _address,
        self.erc20TokenContract
    )

    self.lendingPoolContract = ILendingPool(_address)
    self.erc20TokenContract = ILendingPool(_address).erc20TokenContract()


@external
def setCollateralVaultPeripheralAddress(_address: address):
    assert msg.sender == self.owner  # reason: msg.sender is not the owner
    assert _address != empty(address)  # reason: address is the zero address

    log CollateralVaultPeripheralAddressSet(
        self.erc20TokenContract,
        self.collateralVaultContract.address,
        _address,
        self.erc20TokenContract
    )

    self.collateralVaultContract = ICollateralVault(_address)


@external
def setLiquidationsPeripheralAddress(_address: address):
    assert msg.sender == self.owner  # reason: msg.sender is not the owner
    assert _address != empty(address)  # reason: address is the zero address

    log LiquidationsPeripheralAddressSet(
        self.erc20TokenContract,
        self.liquidationsContract.address,
        _address,
        self.erc20TokenContract
    )

    self.liquidationsContract = ILiquidations(_address)


@external
def changeContractStatus(_flag: bool):
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert not self.isDeprecated, "contract is deprecated"

    self.isAcceptingLoans = _flag

    log ContractStatusChanged(
        self.erc20TokenContract,
        _flag,
        self.erc20TokenContract
    )


@external
def deprecate():
    assert msg.sender == self.owner, "msg.sender is not the owner"
    assert not self.isDeprecated, "contract is already deprecated"

    self.isDeprecated = True
    self.isAcceptingLoans = False

    log ContractDeprecated(
        self.erc20TokenContract,
        self.erc20TokenContract
    )


@view
@external
def erc20TokenSymbol() -> String[100]:
    return IERC20Symbol(self.erc20TokenContract).symbol()


@view
@external
def getLoanPayableAmount(_borrower: address, _loanId: uint256, _timestamp: uint256) -> uint256:
    loan: Loan = self._get_loan(_borrower, _loanId)

    if loan.paid:
        return 0

    if loan.startTime > _timestamp:
        return max_value(uint256)

    if loan.started:
        timePassed: uint256 = self._compute_period_passed_in_seconds(
            _timestamp,
            loan.startTime,
            self.interestAccrualPeriod
        )
        return self._loan_payable_amount(
            loan.amount,
            loan.paidPrincipal,
            loan.interest,
            loan.maturity - loan.startTime,
            timePassed,
            self.interestAccrualPeriod
        )

    return max_value(uint256)


@external
def reserve(
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _genesisToken: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> uint256:
    """
    @notice Creates a new loan with the defined amount, interest rate and collateral. The message must be signed by the contract admin.
    @dev Logs `LoanCreated` event. The last 3 parameters must match a signature by the contract admin of the implicit message consisting of the remaining parameters, in order for the loan to be created
    @param _amount The loan amount in wei
    @param _interest The interest rate in bps (1/1000) for the loan duration
    @param _maturity The loan maturity in unix epoch format
    @param _collaterals The list of collaterals supporting the loan
    @param _delegations Wether to set the requesting wallet as a delegate for all collaterals
    @param _deadline The deadline of validity for the signed message in unix epoch format
    @param _genesisToken The optional Genesis Pass token used to determine the loan conditions, must be > 0
    @param _v recovery id for public key recover
    @param _r r value in ECDSA signature
    @param _s s value in ECDSA signature
    @return The loan id
    """

    newLoanId: uint256 = self._reserve(_amount, _interest, _maturity, _collaterals, _delegations, _deadline, _nonce, _genesisToken, _v, _r, _s)

    self.lendingPoolContract.sendFunds(msg.sender, _amount)

    return newLoanId


@external
def reserveEth(
    _amount: uint256,
    _interest: uint256,
    _maturity: uint256,
    _collaterals: DynArray[Collateral, 100],
    _delegations: bool,
    _deadline: uint256,
    _nonce: uint256,
    _genesisToken: uint256,
    _v: uint256,
    _r: uint256,
    _s: uint256
) -> uint256:
    """
    @notice Creates a new loan with the defined amount, interest rate and collateral. The message must be signed by the contract admin.
    @dev Logs `LoanCreated` event. The last 3 parameters must match a signature by the contract admin of the implicit message consisting of the remaining parameters, in order for the loan to be created
    @param _amount The loan amount in wei
    @param _interest The interest rate in bps (1/1000) for the loan duration
    @param _maturity The loan maturity in unix epoch format
    @param _collaterals The list of collaterals supporting the loan
    @param _delegations Wether to set the requesting wallet as a delegate for all collaterals
    @param _deadline The deadline of validity for the signed message in unix epoch format
    @param _genesisToken The optional Genesis Pass token used to determine the loan conditions, must be > 0
    @param _v recovery id for public key recover
    @param _r r value in ECDSA signature
    @param _s s value in ECDSA signature
    @return The loan id
    """

    newLoanId: uint256 = self._reserve(_amount, _interest, _maturity, _collaterals, _delegations, _deadline, _nonce, _genesisToken, _v, _r, _s)

    self.lendingPoolContract.sendFundsEth(msg.sender, _amount)

    return newLoanId


@payable
@external
def pay(_loanId: uint256):

    """
    @notice Closes an active loan by paying the full amount
    @dev Logs the `LoanPayment` and `LoanPaid` events. The associated `LendingPoolCore` contract must be approved for the payment amount
    @param _loanId The id of the loan to settle
    """

    receivedAmount: uint256 = msg.value
    if not self.isPayable:
        assert receivedAmount == 0, "no ETH allowed for this loan"

    assert self._is_loan_created(msg.sender, _loanId), "loan not found"

    loan: Loan = self._get_loan(msg.sender, _loanId)
    assert block.timestamp <= loan.maturity, "loan maturity reached"
    assert not loan.paid, "loan already paid"

    # compute days passed in seconds
    timePassed: uint256 = self._compute_period_passed_in_seconds(
        block.timestamp,
        loan.startTime,
        self.interestAccrualPeriod
    )

    # pro-rata computation of max amount payable based on actual loan duration in days
    paymentAmount: uint256 = self._loan_payable_amount(
        loan.amount,
        loan.paidPrincipal,
        loan.interest,
        loan.maturity - loan.startTime,
        timePassed,
        self.interestAccrualPeriod
    )

    erc20TokenContract: address = self.erc20TokenContract
    excessAmount: uint256 = 0

    if receivedAmount > 0:
        assert receivedAmount >= paymentAmount, "insufficient value received"
        excessAmount = receivedAmount - paymentAmount
        log PaymentReceived(msg.sender, msg.sender, receivedAmount)
    else:
        assert IERC20(erc20TokenContract).balanceOf(msg.sender) >= paymentAmount, "insufficient balance"
        assert IERC20(erc20TokenContract).allowance(
                msg.sender,
                self.lendingPoolContract.address
        ) >= paymentAmount, "insufficient allowance"

    paidInterestAmount: uint256 = paymentAmount - loan.amount

    self._update_loan_paid_amount(msg.sender, _loanId, loan.amount, paidInterestAmount)
    self._update_paid_loan(msg.sender, _loanId)

    if receivedAmount > 0:
        self.lendingPoolContract.receiveFundsEth(msg.sender, loan.amount, paidInterestAmount, value=paymentAmount)
        log PaymentSent(self.lendingPoolContract.address, self.lendingPoolContract.address, paymentAmount)
    else:
        self.lendingPoolContract.receiveFunds(msg.sender, loan.amount, paidInterestAmount)

    for collateral in loan.collaterals:
        self.collateralVaultContract.transferCollateralFromLoan(
            msg.sender,
            collateral.contractAddress,
            collateral.tokenId,
            erc20TokenContract
        )

    if excessAmount > 0:
        send(msg.sender, excessAmount)
        log PaymentSent(msg.sender, msg.sender,excessAmount)

    log LoanPayment(
        msg.sender,
        msg.sender,
        _loanId,
        loan.amount,
        paidInterestAmount,
        erc20TokenContract
    )
    
    log LoanPaid(
        msg.sender,
        msg.sender,
        _loanId,
        erc20TokenContract
    )


@external
def settleDefault(_borrower: address, _loanId: uint256):
    """
    @notice Settles an active loan as defaulted
    @dev Logs the `LoanDefaulted` event, removes the collaterals from the loan and creates a liquidation
    @param _borrower The wallet address of the borrower
    @param _loanId The id of the loan to settle
    """
    assert msg.sender == self.admin, "msg.sender is not the admin"
    assert self._is_loan_created(_borrower, _loanId), "loan not found"
    
    loan: Loan = self._get_loan(_borrower, _loanId)
    assert not loan.paid, "loan already paid"
    assert block.timestamp > loan.maturity, "loan is within maturity period"
    assert self.liquidationsContract.address != empty(address), "BNPeriph is the zero address"

    self._update_defaulted_loan(_borrower, _loanId)

    self.liquidationsContract.addLiquidation(
        _borrower,
        _loanId,
        self.erc20TokenContract
    )

    log LoanDefaulted(
        _borrower,
        _borrower,
        _loanId,
        loan.amount,
        self.erc20TokenContract
    )


@external
def setDelegation(_loanId: uint256, _collateralAddress: address, _tokenId: uint256, _value: bool):

    """
    @notice Sets / unsets a delegation for some collateral of a given loan. Only available to unpaid loans until maturity is reached
    @param _loanId The id of the loan to settle
    @param _collateralAddress The contract address of the collateral
    @param _tokenId The token id of the collateral
    @param _value Wether to set or unset the token delegation
    """

    loan: Loan = self._get_loan(msg.sender, _loanId)
    assert loan.amount > 0, "invalid loan id"
    assert block.timestamp <= loan.maturity, "loan maturity reached"
    assert not loan.paid, "loan already paid"
    
    for collateral in loan.collaterals:
        if collateral.contractAddress ==_collateralAddress and collateral.tokenId == _tokenId:
            self.collateralVaultContract.setCollateralDelegation(
                msg.sender,
                _collateralAddress,
                _tokenId,
                self.erc20TokenContract,
                _value
            )