// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract CustodialContract {
    address public owner;

    event Withdrawed(address to, uint256 amount);
    event Received(address indexed to, uint256 indexed amount);

    modifier onlyAdmin() {
        require(msg.sender == owner, "CustodialContract:Caller does not have admin privileges");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw(address to) external onlyAdmin {
        uint amount = address(this).balance;
        require(amount > 0 , "CustodialContract:Incorrect amount.");
		(bool success,) = to.call{value : amount}("");
        
        if (success)
            emit Withdrawed(to, amount);
    }

    function withdrawERC20(address _token, address to) external onlyAdmin {
        uint amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0 , "CustodialContract:Incorrect amount.");
        IERC20(_token).transfer(to, amount);
    }
}

contract CasinoBankRoll {
    address public creator;
    mapping (uint => address) private addressTracker;

    event Deploy(address addr);
    event Withdrawed(address to, uint256 amount);

    modifier onlyCreator() {
        require(msg.sender == creator, "CasinoBankRoll:Caller does not have creator privileges");
        _;
    }

    constructor() {
        creator = msg.sender;
    }

    receive() external payable {}

    function deploy(uint _salt) external onlyCreator {
        CustodialContract _contract = new CustodialContract{
            salt: bytes32(_salt)
        }(msg.sender);

        addressTracker[_salt] = address(_contract);

        emit Deploy(address(_contract));
    }

    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );
        return address (uint160(uint(hash)));
    }

    function getBytecode(address _owner) public pure returns (bytes memory) {
        bytes memory bytecode = type(CustodialContract).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }

    function withdraw(address to, uint256 amount) external onlyCreator {
        require(amount <= address(this).balance, "CasinoBankRoll:Insufficient funds.");
		(bool success,) = to.call{value : amount}("");

        if (success)
            emit Withdrawed(to, amount);
    }

    function withdrawCustomToken(address _token, address to, uint256 amount) external onlyCreator() {
        require(amount <= IERC20(_token).balanceOf(address(this)), "CasinoBankRoll:Insufficient funds.");
        IERC20(_token).transfer(to, amount);
    }

    function getCustodialAddress(uint salt) external view returns (address) {
        return addressTracker[salt];
    }
}