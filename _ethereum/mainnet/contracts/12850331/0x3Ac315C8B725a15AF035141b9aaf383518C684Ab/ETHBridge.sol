pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./ECDSA.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";
import "./Token.sol";


contract ETHBridge is Ownable {
    using SafeMath for uint;

    address public signer;

    mapping(address => uint256) public portFee;
    mapping(string => bool) public executed;
    mapping(address => address) public ercToBep;
    mapping(address => address) public bepToErc;

    event Data(uint chain, address bridge, address token, uint amount, address sender ,string txHash);
    event Loda(address sig, address signer);

    event PortTo(address indexed ercToken, address indexed bepToken, address indexed from, uint256 amount);
    event PortBack(address indexed bepToken, address indexed ercToken, address indexed from, uint256 amount, string _portTxHash);

    constructor(address _signer) public {
        require(_signer != address(0x0));
        signer = _signer;
    }

    function withdrawFee(address _token, address _to, uint256 _amount) onlyOwner external {
        require(_to != address(0), "invalid address");
        require(_amount > 0, "amount must be greater than 0");
        if(_token == address(0))
        TransferHelper.safeTransferETH(_to, _amount);
        else TransferHelper.safeTransfer(_token, _to, _amount);
    }

    function portTo(address _ercToken, uint256 _amount) external payable {
        address bepToken = ercToBep[_ercToken]; // ensure we support swap
        require(bepToken != address(0), "invalid token");
        require(_amount > 0, "amount must be greater than 0");        
        require(portFee[bepToken] == msg.value, "invalid port fee");

        Token(_ercToken).burnFrom(msg.sender, _amount);
        emit PortTo(_ercToken, bepToken, msg.sender, _amount);
    }

    function portToLegacy(address _ercToken, uint256 _amount) external payable {
        address bepToken = ercToBep[_ercToken]; // ensure we support swap
        require(bepToken != address(0), "invalid token");
        require(_amount > 0, "amount must be greater than 0");        
        require(portFee[bepToken] == msg.value, "invalid port fee");
        
        Token(_ercToken).burn(msg.sender, _amount);
        emit PortTo(_ercToken, bepToken, msg.sender, _amount);
    }


    // signature for authorization of mint
    function portBack(bytes calldata _signature, string memory _portTxHash, address _bepToken, uint _amount) external {
        require(!executed[_portTxHash], "already ported back");
        require(_amount > 0, "amount must be greater than 0");
        address ercToken = bepToErc[_bepToken];

        uint chainId;
        assembly {
            chainId := chainid()
        }

        bytes32 message = keccak256(abi.encodePacked(chainId, address(this), _bepToken, _amount, msg.sender, _portTxHash));
        bytes32 signature = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
       
        require(ECDSA.recover(signature, _signature) == signer, "invalid signature");

        executed[_portTxHash] = true;
        Token(ercToken).mint(msg.sender, _amount);
        emit PortBack(_bepToken, ercToken, msg.sender, _amount, _portTxHash);
    }

    function changePortFee(address ercToken, uint256 _portFee) onlyOwner external {
        portFee[ercToken] = _portFee;
    }

    function changeSigner(address _signer) onlyOwner external {
        signer = _signer;
    }

    function addToken(address _ercToken, address _bepToken) onlyOwner external {
        ercToBep[_ercToken] = _bepToken;
        bepToErc[_bepToken] = _ercToken;
    }
}