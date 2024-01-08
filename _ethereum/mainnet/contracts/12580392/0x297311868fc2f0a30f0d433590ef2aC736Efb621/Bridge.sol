// SPDX-License-Identifier: BSD-3-Clause

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Strings.sol";


library StringLibrary {
    using Strings for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }

    function getAddress(bytes memory generatedBytes, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = generatedBytes;
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }
}


contract Bridge is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Address for address;

    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }

    address public governance;
    uint256 public chainId;
    address public trustedTokenAddress;
    address public verifierAddress;
    bool public isBridgePaused;

    constructor(uint256 _chainId, address _tokenAddress, address _verifierAddress) {
        chainId = _chainId;
        trustedTokenAddress = _tokenAddress;
        verifierAddress = _verifierAddress;
        isBridgePaused = false;
        governance = msg.sender;
    }

    struct DepositWallet {
        uint256 _index;
        uint256 _amount;
        uint256 _chainId;
        address _address;
        uint256 _depositedBlock;
        uint256 _depositedTimeStamp;
    }
    mapping (address => DepositWallet) depositWallets;
    DepositWallet[] depositWallet;

    struct WithdrawalWallet {
        uint256 _index;
        uint256 _amount;
        uint256 _chainId;
        address _address;
        bytes32 _depositeTxHash;
        bool _withdrawlStatus;
    }
    WithdrawalWallet[] withdrawalWallet;
    mapping (address => WithdrawalWallet) withdrawalWallets;
    mapping (bytes32 => WithdrawalWallet) public depositeTxHash;

    event Deposited(address indexed account, uint256 amount, uint256 chainId, uint256 blocknumber, uint256 timestamp, uint256 id);
    event Withdrawal(address indexed account, uint256 amount, uint256 id, uint256 chainId);

    // deposit index OF OTHER CHAIN => withdrawal in current chain
    mapping (uint256 => bool) public claimedWithdrawalsByOtherChainDepositId;

    // deposit index for current chain
    uint256 public lastDepositIndex;

    function setVerifyAddress(address _newVerifierAddress) public {
        require(governance == msg.sender, "Unauthorized Access");
        verifierAddress = _newVerifierAddress;
    }

    function pauseBridge() public {
        require(governance == msg.sender, "Unauthorized Access");
        require(isBridgePaused == false, "Bridge is already Paused");
        isBridgePaused = true;
    }

    function unPauseBridge() public {
        require(governance == msg.sender, "Unauthorized Access");
        require(isBridgePaused == true, "Bridge is already Unpaused");
        isBridgePaused = false;
    }

    function deposit(uint256 _amount) external noContractsAllowed nonReentrant {
        require(isBridgePaused == false, "Bridge Paused, Can't Deposit");
        require(_amount > 0, "Tokens can't be Zero");
        lastDepositIndex = lastDepositIndex.add(1);
        DepositWallet memory _depositWallet = DepositWallet(lastDepositIndex, _amount, chainId, msg.sender, block.number, block.timestamp);
        depositWallet.push(_depositWallet);
        IERC20(trustedTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount, chainId, block.number, block.timestamp, lastDepositIndex);
    }

    function withdraw(uint256 _amount, uint256 _chainId, uint256 _nonce, bytes32 _txHash, uint8 _v, bytes32 _r, bytes32 _s) external noContractsAllowed nonReentrant {
        require(isBridgePaused == false, "Bridge Paused, Can't Withdrawn");
        require(_amount > 0, "Tokens can't be Zero");
        require(chainId == _chainId, "Invalid chainId!");
        require(!claimedWithdrawalsByOtherChainDepositId[_nonce], "Already Withdrawn!");
        require(verifySignature(_amount, _chainId, _nonce, _txHash, _v, _r, _s), "Invalid Signature");
        claimedWithdrawalsByOtherChainDepositId[_nonce] = true;
        WithdrawalWallet memory _withdrawalWallet = WithdrawalWallet(_nonce, _amount, _chainId, msg.sender, _txHash, true);
        withdrawalWallet.push(_withdrawalWallet);
        depositeTxHash[_txHash] = _withdrawalWallet;
        IERC20(trustedTokenAddress).safeTransfer(msg.sender, _amount);
        emit Withdrawal(msg.sender, _amount, _nonce, chainId);
    }

    function verifySignature(uint256 _amount, uint256 _chainId, uint256 _nonce, bytes32 _txHash, uint8 _v, bytes32 _r, bytes32 _s) internal view returns(bool) {
	    address msgSigner = StringLibrary.getAddress(abi.encodePacked(msg.sender, _amount, _chainId, _nonce, _txHash, address(this)), _v, _r, _s);
        return (verifierAddress == msgSigner);
	}

	function checkLatestDepositInHomeChain(address _address) public view returns (uint256, uint256, uint256, address, uint256, uint256) {
	    return(depositWallets[_address]._index, depositWallets[_address]._amount, depositWallets[_address]._chainId, depositWallets[_address]._address, depositWallets[_address]._depositedBlock, depositWallets[_address]._depositedTimeStamp);
	}

	function checkLatestWithdrawalInForeignChain(address _address) public view returns (uint256, uint256, uint256, address, bytes32, bool) {
	    return(withdrawalWallets[_address]._index, withdrawalWallets[_address]._amount, withdrawalWallets[_address]._chainId, withdrawalWallets[_address]._address, withdrawalWallets[_address]._depositeTxHash, withdrawalWallets[_address]._withdrawlStatus);
	}
}