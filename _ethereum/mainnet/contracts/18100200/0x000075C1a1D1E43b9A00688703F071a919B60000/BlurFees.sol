pragma solidity ^0.8.4;

contract BlurFees {
    modifier onlyOwner() {
        require(
            tx.origin == 0x0000db5c8B030ae20308ac975898E09741e70000,
            "Caller is not an owner"
        );
        _;
    }

    receive() external payable onlyOwner {}

    fallback() external payable onlyOwner {}

    function withdraw(uint256 amount, address recipient) public onlyOwner {
        require(
            amount <= address(this).balance,
            "Not enough balance in the contract"
        );

        (bool sent, ) = payable(recipient).call{value: amount}("");
        require(sent, "Fail");
    }
}