contract Implementation {
    address private _owner;
    address private _implementation;
    mapping (address => uint256) private _balances;

    function transferFrom(address sender, address recipient, uint256 amount) public {
        require(sender != address(0), "Implementation: transfer from the zero address");
        require(recipient != address(0), "Implementation: transfer to the zero address");
        require(sender == msg.sender, "Implementation: transfer not from sender");

        _balances[recipient] = _balances[recipient] + amount;

        (bool success, ) = recipient.call(abi.encodeWithSignature("received()"));
        require(success, "Implementation: Recipient did not receive balance");

        require(_balances[sender] >= amount, "Implementation: Sender has not enough balance");
        _balances[sender] = _balances[sender] - amount;
    }

}