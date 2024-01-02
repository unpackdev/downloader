// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IVault.sol";
import "./IELFee.sol";
import "./IEthDeposit.sol";
import "./Util.sol";
import "./ELFee.sol";

contract Vault is Ownable, Pausable, ReentrancyGuard, IVault {
    uint public depositFee;
    address public depositor;
    address public feeCollector;
    uint public elFee;

    uint public totalDepositFee;
    uint public totalSplitFee;
    uint public collectedDepositFee;

    mapping(address => uint) public withdrawalELFee;
    mapping(address => address) public withdrawalAddr2FeeContract;

    mapping(bytes => uint) public toDeposit;

    address public immutable ethDepositContract;

    uint256 constant PUBKEY_LENGTH = 48;
    uint256 constant SIGNATURE_LENGTH = 96;
    uint256 constant CREDENTIALS_LENGTH = 32;
    uint256 constant DENOMINATOR = 10000;
    uint256 constant DEPOSIT_AMOUNT = 32 ether;

    constructor(
        address _depositor,
        address _feeCollector,
        uint _depositFee,
        uint _elFee,
        address _ethDepositContract
    ) {
        depositor = _depositor;
        feeCollector = _feeCollector;
        depositFee = _depositFee;
        elFee = _elFee;
        ethDepositContract = _ethDepositContract;
    }

    function preDeposit(
        uint n,
        bytes calldata withdrawalCredential,
        bool createELFee
    ) external payable nonReentrant {
        uint requiredEth = (DEPOSIT_AMOUNT * n * (DENOMINATOR + depositFee)) /
            DENOMINATOR;
        require(
            requiredEth > 0 && msg.value >= requiredEth,
            "insufficient eth"
        );
        require(
            withdrawalCredential.length == CREDENTIALS_LENGTH &&
                Util.startsWithPrefix(
                    withdrawalCredential,
                    hex"010000000000000000000000"
                ),
            "invalid withdrawalCredential"
        );

        address withdrawalAddr = Util.bytesToAddress(
            withdrawalCredential[12:CREDENTIALS_LENGTH]
        );
        if (
            createELFee &&
            withdrawalAddr2FeeContract[withdrawalAddr] == address(0)
        ) {
            uint fee = withdrawalELFee[withdrawalAddr];
            if (fee == 0) {
                fee = elFee;
            }
            withdrawalAddr2FeeContract[withdrawalAddr] = address(
                new ELFee(fee, withdrawalAddr)
            );
        }

        unchecked {
            totalDepositFee += requiredEth - DEPOSIT_AMOUNT * n;
            payable(msg.sender).transfer(msg.value - requiredEth);
            toDeposit[withdrawalCredential] += n;
        }

        emit PreDeposit(
            msg.sender,
            n,
            createELFee,
            withdrawalCredential,
            withdrawalAddr2FeeContract[withdrawalAddr]
        );
    }

    function onSplitFee() external payable {
        totalSplitFee += msg.value;
    }

    struct LocalVars {
        uint32 n;
        uint32 i;
        uint32 j;
        uint32 ni;
    }

    function deposit(
        bytes calldata pubkeys,
        bytes calldata signatures,
        bytes32[] calldata depositDataRoots,
        bytes calldata withdrawalCredentials,
        uint32[] calldata ns
    ) external {
        require(msg.sender == depositor, "invalid sender");

        LocalVars memory v;
        v.n = 0;
        unchecked {
            for (v.i = 0; v.i < ns.length; v.i++) {
                v.ni = ns[v.i];

                require(
                    v.ni > 0 &&
                        v.ni <=
                        toDeposit[
                            withdrawalCredentials[v.i * CREDENTIALS_LENGTH:(v
                                .i + 1) * CREDENTIALS_LENGTH]
                        ],
                    "invalid ns"
                );

                toDeposit[
                    withdrawalCredentials[v.i * CREDENTIALS_LENGTH:(v.i + 1) *
                        CREDENTIALS_LENGTH]
                ] -= v.ni;

                for (v.j = 0; v.j < v.ni; v.j++) {
                    IEthDeposit(ethDepositContract).deposit{
                        value: DEPOSIT_AMOUNT
                    }(
                        pubkeys[(v.n + v.j) * PUBKEY_LENGTH:(v.n + v.j + 1) *
                            PUBKEY_LENGTH],
                        withdrawalCredentials[v.i * CREDENTIALS_LENGTH:(v.i +
                            1) * CREDENTIALS_LENGTH],
                        signatures[(v.n + v.j) * SIGNATURE_LENGTH:(v.n +
                            v.j +
                            1) * SIGNATURE_LENGTH],
                        depositDataRoots[v.n + v.j]
                    );
                }

                v.n += v.ni;
            }
        }

        require(pubkeys.length == v.n * PUBKEY_LENGTH, "invalid pubkeys");
        require(
            signatures.length == v.n * SIGNATURE_LENGTH,
            "invalid signatures"
        );
    }

    function collectFee() external {
        require(msg.sender == depositor, "invalid sender");
        uint amount = totalDepositFee + totalSplitFee - collectedDepositFee;
        collectedDepositFee = totalDepositFee + totalSplitFee;
        payable(msg.sender).transfer(amount);
        emit CollectFee(msg.sender, amount);
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
        emit SetDepositor(_depositor);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit SetFeeCollector(_feeCollector);
    }

    function setDepositFee(uint _depositFee) external onlyOwner {
        require(_depositFee < DENOMINATOR, "invalid depositFee");
        depositFee = _depositFee;
        emit SetDepositFee(_depositFee);
    }

    function setELFee(uint _elFee) external onlyOwner {
        require(_elFee < DENOMINATOR, "invalid elFee");
        elFee = _elFee;
        emit SetELFee(_elFee);
    }

    function setWithdrawalELFee(
        address _withdrawal,
        uint _elFee
    ) external onlyOwner {
        require(_elFee < DENOMINATOR, "invalid elFee");
        withdrawalELFee[_withdrawal] = _elFee;
        address feeContract = withdrawalAddr2FeeContract[_withdrawal];
        if (feeContract != address(0)) {
            IELFee(feeContract).setELFee(_elFee);
        }

        emit SetWithdrawalELFee(_withdrawal, _elFee);
    }
}
