// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier {
    function verifyProof(bytes calldata _proof, uint256[] calldata _publicInputs) external returns (bool);
}

contract BankFactory {
    mapping(address => address) public bankRegistry;
    IVerifier public depositVerifier;
    IVerifier public transferVerifier;
    IVerifier public withdrawVerifier;
    IVerifier public lockVerifier;
    IVerifier public processVerifier;

    event BankCreated(address indexed token, address bankAddress);

    constructor(address _depositVerifier, address _transferVerifier, address _withdrawVerifier, address _lockVerifier, address _processVerifier) {
        depositVerifier = IVerifier(_depositVerifier);
        transferVerifier = IVerifier(_transferVerifier);
        withdrawVerifier = IVerifier(_withdrawVerifier);
        lockVerifier = IVerifier(_lockVerifier);
        processVerifier = IVerifier(_processVerifier);
    }

    function createBank(address token) external {
        require(bankRegistry[token] == address(0), "Bank already exists for token");
        Bank newBank = new Bank(token, address(depositVerifier), address(transferVerifier), address(withdrawVerifier), address(lockVerifier), address(processVerifier));
        bankRegistry[token] = address(newBank);
        emit BankCreated(token, address(newBank));
    }
}

contract Bank {
    address public token;
    IVerifier private depositVerifier;
    IVerifier private transferVerifier;
    IVerifier private withdrawVerifier;
    IVerifier private lockVerifier;
    IVerifier private processVerifier;

    constructor(address _token, address _depositVerifier, address _transferVerifier, address _withdrawVerifier, address _lockVerifier, address _processVerifier) {
        token = _token;
        depositVerifier = IVerifier(_depositVerifier);
        transferVerifier = IVerifier(_transferVerifier);
        withdrawVerifier = IVerifier(_withdrawVerifier);
        lockVerifier = IVerifier(_lockVerifier);
        processVerifier = IVerifier(_processVerifier);
    }

    function initiateDeposit(uint256 amount, bytes calldata proof) external {
        bool validDeposit = depositVerifier.verifyProof(proof, new uint256[](0));
        require(validDeposit, "Invalid deposit proof");
    }

    function initiateTransfer(address recipient, uint256 amount, bytes calldata proof) external {
        bool validTransfer = transferVerifier.verifyProof(proof, new uint256[](0));
        require(validTransfer, "Invalid transfer proof");
    }

    function initiateWithdraw(address to, uint256 amount, bytes calldata proof) external {
        bool validWithdraw = withdrawVerifier.verifyProof(proof, new uint256[](0));
        require(validWithdraw, "Invalid withdraw proof");
    }

    function finalizeDeposit(bytes calldata proof) external {
        bool validDepositFinalization = processVerifier.verifyProof(proof, new uint256[](0));
        require(validDepositFinalization, "Invalid deposit finalization proof");
    }

    function finalizeTransfer(bytes calldata proof) external {
        bool validTransferFinalization = processVerifier.verifyProof(proof, new uint256[](0));
        require(validTransferFinalization, "Invalid transfer finalization proof");
    }

    function activateLock(bytes calldata proof) external {
        bool validLockActivation = lockVerifier.verifyProof(proof, new uint256[](0));
        require(validLockActivation, "Invalid lock activation proof");
    }

    function releaseLock(bytes calldata proof) external {
        bool validLockRelease = lockVerifier.verifyProof(proof, new uint256[](0));
        require(validLockRelease, "Invalid lock release proof");
    }


}