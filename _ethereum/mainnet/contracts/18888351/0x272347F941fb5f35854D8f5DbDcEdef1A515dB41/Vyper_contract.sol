# @version ^0.3.9

MAX_REQUESTS: constant(uint256) = 32 # maximum number of requestIds to process at a time
MAX_OUTPUT_PIPES: constant(uint256) = 32
MAX_LIDO_DEPOSIT: constant(uint256) = 1000 * 10**18
MIN_LIDO_DEPOSIT: constant(uint256) = 100
MAX_PIPE_DATA: constant(uint256) = 32 * 16

interface StETH:
  def balanceOf(_owner: address) -> uint256: view
  def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
  def approve(_spender: address, _value: uint256) -> bool: nonpayable

interface UnstETH:
  def requestWithdrawals(_amounts: DynArray[uint256, MAX_REQUESTS], _owner: address) -> DynArray[uint256, MAX_REQUESTS]: nonpayable
  def getClaimableEther(_requestIds: DynArray[uint256, MAX_REQUESTS], _hints: DynArray[uint256, MAX_REQUESTS]) -> DynArray[uint256, MAX_REQUESTS]: view
  def claimWithdrawals(_requestIds: DynArray[uint256, MAX_REQUESTS], _hints: DynArray[uint256, MAX_REQUESTS]): nonpayable

interface Lidont:
  def mint(amount: uint256, recipient: address): nonpayable

interface OutputPipe:
  def receive(_who: address, _data: Bytes[MAX_PIPE_DATA]): payable
  def receiveReward(_token: address, _from: address, _amount: uint256): nonpayable

stakedEther: immutable(StETH)
unstETH: immutable(UnstETH)
lidont: public(Lidont)

# Claims tracking

# Stages:
# 1. No deposit           - outputPipe empty
#    deposit →
# 2. stETH deposited      - outputPipe set, stETH non-zero
#    initiateWithdrawal →
# 3. Withdrawal requested - outputPipe set, stETH zero, ETH zero
#    finaliseWithdrawal →
# 4. Withdrawal finalised - outputPipe set, stETH zero, ETH non-zero
#    claim →
struct DepositData:
  stETH: uint256
  requestId: uint256
  ETH: uint256
  outputPipe: address

deposits: public(HashMap[address, DepositData])

queue: public(address[MAX_REQUESTS])
queueSize: public(uint256)
queueFront: public(uint256)
queueBack: public(uint256)
@internal
def _appendQueue(a: address):
  self.queue[self.queueBack] = a
  self.queueBack += 1
  if self.queueBack == MAX_REQUESTS: self.queueBack = 0
  self.queueSize += 1
  assert self.queueSize < MAX_REQUESTS, "too many depositors"
@internal
def _popQueue() -> address:
  front: address = self.queue[self.queueFront]
  self.queueFront += 1
  if self.queueFront == MAX_REQUESTS: self.queueFront = 0
  self.queueSize -= 1
  return front

# Output pipes

admin: public(address)
newMinter: public(address)
outputIndex: public(HashMap[address, uint256]) # 0 is invalid, otherwise 1+index in outputPipes
outputPipes: public(DynArray[address, MAX_OUTPUT_PIPES])

emissionPerBlock: public(uint256)
lastRewardBlock: public(HashMap[address, uint256])

event ChangeAdmin:
  oldAdmin: indexed(address)
  newAdmin: indexed(address)

event SetOutputValidity:
  output: indexed(address)
  valid: indexed(bool)

event ChangeEmission:
  oldEmissionPerBlock: indexed(uint256)
  newEmissionPerBlock: indexed(uint256)

@external
def __init__(stETHAddress: address, unstETHAddress: address):
  stakedEther = StETH(stETHAddress)
  unstETH = UnstETH(unstETHAddress)
  self.admin = msg.sender

@external
def changeAdmin(newAdmin: address):
  assert msg.sender == self.admin, "auth"
  self.admin = newAdmin
  log ChangeAdmin(msg.sender, newAdmin)

@external
def setLidont(lidontAddress: address):
  assert msg.sender == self.admin, "auth"
  self.lidont = Lidont(lidontAddress)

@external
def setUpgrade(upgradeAddress: address):
  assert msg.sender == self.admin, "auth"
  self.newMinter = upgradeAddress

event SetLastRewardBlock:
  pipe: indexed(address)
  bnum: indexed(uint256)

@internal
def _updatePendingRewardsFor(output: address):
  # assert 0 < self.outputIndex[output], "assume the caller checks this"
  unclaimedBlocks: uint256 = block.number - self.lastRewardBlock[output]
  self.lastRewardBlock[output] = block.number
  log SetLastRewardBlock(output, block.number)
  reward: uint256 = unclaimedBlocks * self.emissionPerBlock
  if 0 < reward:
    self.lidont.mint(reward, output)
    OutputPipe(output).receiveReward(self.lidont.address, empty(address), reward)

@internal
def _updatePendingRewards():
  for output in self.outputPipes:
    self._updatePendingRewardsFor(output)

@external
def triggerEmission(output: address):
  assert 0 < self.outputIndex[output], "invalid output pipe"
  self._updatePendingRewardsFor(output)

@external
def toggleValidOutput(output: address):
  assert msg.sender == self.admin, "auth"
  newValidity: bool = self.outputIndex[output] == 0
  if not newValidity:
    self._updatePendingRewardsFor(output)
  for i in range(MAX_OUTPUT_PIPES):
    if i == len(self.outputPipes): break
    if newValidity and self.outputPipes[i] == empty(address):
      self.outputPipes[i] = output
      self.outputIndex[output] = unsafe_add(i, 1)
      break
    elif not newValidity and self.outputPipes[i] == output:
      self.outputPipes[i] = empty(address)
      self.outputIndex[output] = 0
      break
  if newValidity:
    if self.outputIndex[output] == 0:
      self.outputPipes.append(output)
      self.outputIndex[output] = len(self.outputPipes)
    self.lastRewardBlock[output] = block.number
    log SetLastRewardBlock(output, block.number)
  log SetOutputValidity(output, newValidity)

@external
def changeEmissionRate(newEmissionPerBlock: uint256):
  assert msg.sender == self.admin, "auth"
  self._updatePendingRewards()
  self.emissionPerBlock = newEmissionPerBlock
  log ChangeEmission(self.emissionPerBlock, newEmissionPerBlock)

# Main mechanisms:
# - deposit stETH for (pending) ETH
# - process withdrawals with Lido
# - claim withdrawn ETH to output pipe

event Deposit:
  who: indexed(address)
  amount: indexed(uint256)

event WithdrawalRequest:
  requestIds: DynArray[uint256, MAX_REQUESTS]
  depositors: DynArray[address, MAX_REQUESTS]
  amounts: DynArray[uint256, MAX_REQUESTS]

event Claim:
  who: indexed(address)
  output: indexed(address)
  amount: indexed(uint256)

@external
def deposit(stETHAmount: uint256, outputPipe: address):
  assert 0 < self.outputIndex[outputPipe], "invalid pipe"
  assert MIN_LIDO_DEPOSIT <= stETHAmount, "deposit too small"
  assert stETHAmount <= MAX_LIDO_DEPOSIT, "deposit too large"
  assert stETHAmount <= stakedEther.balanceOf(msg.sender), "balance"
  assert stakedEther.transferFrom(msg.sender, self, stETHAmount), "stETH transfer failed"
  assert self.deposits[msg.sender].outputPipe == empty(address) and self.deposits[msg.sender].stETH == 0, "pending deposit"
  self.deposits[msg.sender].outputPipe = outputPipe
  self.deposits[msg.sender].stETH = stETHAmount
  self._appendQueue(msg.sender)
  log Deposit(msg.sender, stETHAmount)

@external
def changeOutput(outputPipe: address):
  assert self.deposits[msg.sender].outputPipe != empty(address), "no deposit"
  assert 0 < self.outputIndex[outputPipe], "invalid pipe"
  self.deposits[msg.sender].outputPipe = outputPipe

@external
def initiateWithdrawal(depositors: DynArray[address, MAX_REQUESTS]) -> DynArray[uint256, MAX_REQUESTS]:
  requestAmounts: DynArray[uint256, MAX_REQUESTS] = []
  totalRequestAmount: uint256 = 0
  for depositor in depositors:
    assert self.deposits[depositor].ETH == 0, "claim pending"
    amount: uint256 = self.deposits[depositor].stETH
    assert amount > 0, "no deposit"
    requestAmounts.append(amount)
    totalRequestAmount += amount
  assert stakedEther.approve(unstETH.address, totalRequestAmount), "stETH approve failed"
  requestIds: DynArray[uint256, MAX_REQUESTS] = unstETH.requestWithdrawals(requestAmounts, self)
  for i in range(MAX_REQUESTS):
    if i == len(requestIds): break
    depositor: address = depositors[i]
    self.deposits[depositor].stETH = 0
    self.deposits[depositor].requestId = requestIds[i]
  log WithdrawalRequest(requestIds, depositors, requestAmounts)
  return requestIds

@external
def finaliseWithdrawal(depositors: DynArray[address, MAX_REQUESTS],
                       _hints: DynArray[uint256, MAX_REQUESTS]) -> DynArray[uint256, MAX_REQUESTS]:
  requestIds: DynArray[uint256, MAX_REQUESTS] = []
  for depositor in depositors:
    requestIds.append(self.deposits[depositor].requestId)
  claimAmounts: DynArray[uint256, MAX_REQUESTS] = unstETH.getClaimableEther(requestIds, _hints)
  unstETH.claimWithdrawals(requestIds, _hints)
  for i in range(MAX_REQUESTS):
    if i == len(claimAmounts): break
    self.deposits[depositors[i]].ETH = claimAmounts[i]
  return claimAmounts

@external
@payable
def __default__():
  assert msg.sender == unstETH.address, "only withdrawals accepted"

@external
def claim(data: Bytes[MAX_PIPE_DATA]) -> uint256:
  recipient: address = self._popQueue()
  output: address = self.deposits[recipient].outputPipe
  assert output != empty(address), "not deposited" # TODO: impossible?
  amount: uint256 = self.deposits[recipient].ETH
  assert 0 < amount, "not finalised"
  OutputPipe(output).receive(recipient, data, value=amount)
  self.deposits[recipient].ETH = 0
  self.deposits[recipient].outputPipe = empty(address)
  log Claim(recipient, output, amount)
  return amount