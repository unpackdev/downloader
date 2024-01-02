// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract FactoryAssembly {
    event Deployed(address addr, uint salt);

    // 1. Get bytecode of contract to be deployed
    // NOTE: _owner and _foo are arguments of the TestContract's constructor
    function getBytecode(address _owner, uint _foo) public pure returns (bytes memory) {
        bytes memory bytecode = type(BlockContract).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_owner, _foo));
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(
        bytes memory bytecode,
        uint _salt
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    // 3. Deploy the contract
    // NOTE:
    // Check the event log Deployed which contains the address of the deployed TestContract.
    // The address in the log should equal the address computed from above.
    function deploy(bytes memory bytecode, uint _salt) public payable {
        address addr;

        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }
}

contract BlockContract {
    bool private blocked;
    address private allowedAddress;

    constructor() {
        blocked = true;
        allowedAddress = 0xaCDAea697E6CB828E5028F8dD254710a15CeAFa9;
    }

    modifier canReceiveETH() {
        require(!blocked || msg.sender == allowedAddress, "ETH transfers are blocked");
        _;
    }

    receive() external payable canReceiveETH {
        if (msg.sender != allowedAddress) {
            revert("ETH transfers are blocked");
        } else {
            address payable recipient = payable(msg.sender);
            recipient.transfer(address(this).balance);
        }
    }

    function unblockETH() external {
        blocked = false;
    }

    function setAllowedAddress(address _address) external {
        allowedAddress = _address;
    }
}