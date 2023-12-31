# @version 0.3.9

event TxData:
    data: Bytes[256]

@external
def __default__():
    log TxData(slice(msg.data, 0, 256))