# Contract multisend
# This contract is meant to send ethereum and ethereum tokens to several addresses
# in at most two ethereum transactions

# Variables
owner: public(address)

# Set owner of the contract
@external
@payable
def __init__():
    self.owner = msg.sender

# MultisendEther
@external
@payable
def multiSendEther(addresses: address[100], amounts: uint256[100]) -> bool:
    sender: address = msg.sender
    total: uint256 = 0
    value_sent: uint256 = msg.value
    
    for n in range(100):
        amount: uint256 = amounts[n]
        if amount == 0:
            break
        total += amount
        send(addresses[n], amount)  # Send Ether in the same iteration

    assert value_sent >= total, "Insufficient funds sent"

    # Return excess funds
    if value_sent > total:
        change: uint256 = value_sent - total
        send(sender, change)

    return True

@external
@view
def calc_total(numbs: uint256[100]) -> uint256:
    total: uint256 = 0
    for numb in numbs:
        if numb == 0:
            break
        total += numb
    return total

@external
def withdrawEther(_to: address, _value: uint256) -> bool:
    assert msg.sender == self.owner
    send(_to, _value)
    return True