# @version 0.2.7

event LogA:
    sender: address
    source: address


event LogB:
    sender: address
    source: address
    arg: uint256


@external
def func_a():
    log LogA(msg.sender, tx.origin)


@external
def func_b(arg: uint256):
    log LogB(msg.sender, tx.origin, arg)