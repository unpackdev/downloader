pragma solidity ^0.8.0;
import "./IPowerERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";

contract Bridge is Ownable, AccessControl, Pausable {
    using SafeERC20 for IPowerERC20;

    uint private constant BPS = 10000;

    uint256 private _id;
    uint256 public feeRate;
    uint256 public feeFixed;
    address public immutable token;
    mapping(uint256 => bool) public supportedChain;
    mapping(bytes32 => bool) public minted;
    mapping(uint256 => uint256) public totalRequest;
    mapping(uint256 => uint256) public totalMinted;
    
    bytes32 immutable private OPERATOR_ROLE = keccak256("OPERATOR");
    
    event Convert(
        bytes32 indexed id, 
        address indexed from,
        address to,
        uint256 amount, 
        uint256 fee, 
        uint256 chainTo
    );
    event Minted(
        bytes32 indexed id, 
        address to,
        uint256 amount, 
        uint256 chainFrom
    );
    event UpdateFee(uint256 _feeRate, uint256 _feeFixed);
    
    constructor(address _token, uint256[] memory _supportedChain) {
        token = _token;
        for (uint8 i = 0; i < _supportedChain.length; i++) {
            supportedChain[_supportedChain[i]] = true;
        }
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Only call by Operator");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setFee(uint256 _rate, uint256 _fixed) external onlyOwner {
        require(_rate <= BPS, "rate <= 10000");
        feeRate = _rate;
        feeFixed = _fixed;
        emit UpdateFee(feeRate, feeFixed);
    }
    
    function addChainSupported(uint256 chainId) external onlyOwner {
        supportedChain[chainId] = true;   
    }

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        IPowerERC20(_token).safeTransfer(owner(), _amount);
    }

    function getFee(uint256 amountTransfer) view public returns(uint256 fee) {
        return feeFixed + amountTransfer * feeRate / BPS;
    }
    
    // amount included fee
    function transferToOtherChain(uint256 chainId, uint256 amount, address receiver, uint256 maxFee) external whenNotPaused {
        require(receiver != address(0), "receiver != address(0)");
        require(supportedChain[chainId], "network is not supported");
        uint256 fee = getFee(amount);
        require(fee <= maxFee, "Fee over");

        bytes32 id = keccak256(abi.encodePacked(_id, block.difficulty, block.timestamp, amount, chainId, receiver));
        _id++;
        IPowerERC20(token).safeTransferFrom(msg.sender, address(this), amount + fee);
        IPowerERC20(token).burn(amount);
        
        totalRequest[chainId] += amount;
        emit Convert(id, msg.sender, receiver, amount, fee, chainId);
    }
    
    function mintForTrasferCrossChain(uint256 fromChainId, bytes32 id, uint256 amount, address receiver) external onlyOperator {
        require(!minted[id], "minted");
        require(amount > 0, "amount > 0");
        require(receiver != address(0), "receiver != address(0)");
        require(supportedChain[fromChainId], "network is not supported");
        minted[id] = true;
        
        IPowerERC20(token).mint(receiver, amount);
        
        totalMinted[fromChainId] += amount;
        emit Minted(id, receiver, amount, fromChainId);
    }
}