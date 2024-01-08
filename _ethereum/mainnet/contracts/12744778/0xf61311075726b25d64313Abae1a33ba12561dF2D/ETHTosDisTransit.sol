pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";

contract ETHTosDisTransit is Ownable {
    using SafeMath for uint;
    
    address public signWallet;
    address public developWallet;
    address public WETH;
    
    uint public totalFee;
    uint public developFee;
    
    // key: payback_id
    mapping (bytes32 => bool) public executedMap;
    
    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    event Transit(address indexed from, address indexed token, uint amount);
    event Withdraw(bytes32 paybackId, address indexed to, address indexed token, uint amount);
    event CollectFee(address indexed handler, uint amount);
    event ChangedSigner(address wallet);
    event ChangedDevelopWallet(address wallet);
    event ChangedDevelopFee(uint amount);

    constructor(address _WETH, address _signer, address _developer) public {
        WETH = _WETH;
        signWallet = _signer;
        developWallet = _developer;
    }
    
    receive() external payable {
        assert(msg.sender == WETH);
    }
    
    function changeSigner(address _wallet) external onlyOwner{
        // require(msg.sender == owner, "CHANGE_SIGNER_FORBIDDEN");
        signWallet = _wallet;
        emit ChangedSigner(signWallet);
    }
    
    function changeDevelopWallet(address _wallet) external onlyOwner{
        // require(msg.sender == owner, "CHANGE_DEVELOP_WALLET_FORBIDDEN");
        developWallet = _wallet;
        emit ChangedDevelopWallet(developWallet);
    } 
    
    function changeDevelopFee(uint _amount) external onlyOwner{
        // require(msg.sender == owner, "CHANGE_DEVELOP_FEE_FORBIDDEN");
        developFee = _amount;
        emit ChangedDevelopFee(developFee);
    }
    
    function collectFee() external onlyOwner lock{
        // require(msg.sender == owner, "FORBIDDEN");
        require(developWallet != address(0), "SETUP_DEVELOP_WALLET");
        require(totalFee > 0, "NO_FEE");
        TransferHelper.safeTransferETH(developWallet, totalFee);
        totalFee = 0;
    }
    
    function transitForBSC(address _tokenAddress, uint _amount) external {
        require(_amount > 0, "INVALID_AMOUNT");

        IERC20 token = IERC20(_tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _amount);
        uint256 received = token.balanceOf(address(this)).sub(balanceBefore);

        require(received ==_amount, "UNSUPPORTED_TOKEN");
        emit Transit(msg.sender, _tokenAddress, _amount);
    }
    
    function transitETHForBSC() external payable {
        require(msg.value > 0, "INVALID_AMOUNT");
        IWETH(WETH).deposit{value: msg.value}();
        emit Transit(msg.sender, WETH, msg.value);
    }
    
    function withdrawFromBSC(bytes calldata _signature, bytes32 _paybackId, address _token, uint _amount) 
             external lock payable {
        require(!executedMap[_paybackId], "ALREADY_EXECUTED");
        executedMap[_paybackId] = true;
        
        require(_amount > 0, "NOTHING_TO_WITHDRAW");
        require(msg.value == developFee, "INSUFFICIENT_VALUE");
        
        bytes32 message = keccak256(abi.encodePacked(_paybackId, _token, msg.sender, _amount));
        require(_verify(message, _signature), "INVALID_SIGNATURE");
        
        if(_token == WETH) {
            IWETH(WETH).withdraw(_amount);
            TransferHelper.safeTransferETH(msg.sender, _amount);
        } else {
            TransferHelper.safeTransfer(_token, msg.sender, _amount);
        }
        totalFee = totalFee.add(developFee);
        
        emit Withdraw(_paybackId, msg.sender, _token, _amount);
    }
    
    function _verify(bytes32 _message, bytes memory _signature) internal view returns (bool) {
        bytes32 hash = _toEthBytes32SignedMessageHash(_message);
        address[] memory signList = _recoverAddresses(hash, _signature);
        return signList[0] == signWallet;
    }
    
    function _toEthBytes32SignedMessageHash (bytes32 _msg) pure internal returns (bytes32 signHash)
    {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msg));
    }
    
    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) 
             pure internal returns (address[] memory addresses)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }
    
    function _parseSignature(bytes memory _signatures, uint _pos) 
             pure internal returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }
    
    function _countSignatures(bytes memory _signatures) pure internal returns (uint)
    {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}
