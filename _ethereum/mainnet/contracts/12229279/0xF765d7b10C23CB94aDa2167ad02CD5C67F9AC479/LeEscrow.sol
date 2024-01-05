pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Signing.sol";


contract LeEscrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    struct TokenInfo {
        address tokenAddress;
        //rate div 1e6 convert to LeUSD
        uint256 rates;
        uint256 decimal;
    }

    address public depositTreasury;
    address public withdrawTreasury; 


    // 0 - USDT , 1 - LEUSD , 2 - LETOKEN
    TokenInfo[] public listOfTokenInfo;


    mapping(address => mapping(uint256 => uint256)) public userBalances;




    string public constant version = "1";
    // The name of the contract
    string public constant name = "LeEscrow";

        // EIP712 niceties
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 public constant DEPOSIT_TYPEHASH = keccak256(
        "Deposit(address user,uint256 amount,uint256 tokenID,uint256 nonce,uint256 deadline)"
    );
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256(
        "Withdraw(address user,uint256 amount,uint256 tokenID,uint256 nonce,uint256 deadline)"
    );

    // EIP712 domain
    bytes32 public DOMAIN_SEPARATOR;
    // Mapping from a user address to the nonce for signing/validating signatures
    mapping (address => uint256) public nonces;

    event Deposit(address indexed user, uint256 amount, uint256 tokenId);
    event Withdraw(address indexed user, uint256 amount, uint256 tokenId);

    constructor(address _depositTreasury,address _withdrawTreasury) public{
        _revertZeroAddress(_depositTreasury);
        _revertZeroAddress(_withdrawTreasury);

        depositTreasury = _depositTreasury;
        withdrawTreasury = _withdrawTreasury;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                Signing.getChainId(),
                address(this)
            )
        );
    }

    function deposit(
        uint256 _amount,
        uint256 _tokenID
        ) public nonReentrant {
            _deposit(msg.sender,_amount,_tokenID);
        
    }

    function _deposit(address _user, uint256 _amount, uint256 _tokenID) internal{
        
        require(_tokenID >= 0 , "LeEscrow: tokenID cannot be less than zero");
        _tokenExist(_tokenID);

        TokenInfo memory ti = listOfTokenInfo[_tokenID];
        IERC20 token = IERC20(ti.tokenAddress);
        uint256 amountToTransfer = _amount;

        require(amountToTransfer.div(10**ti.decimal) >= 100 , "LeEscrow: amount cannot be less than 100");

        token.transferFrom(_user, depositTreasury, _amount);

        amountToTransfer = (amountToTransfer.div(10**ti.decimal)).mul(ti.rates).div(1000000);


        userBalances[_user][1] = userBalances[_user][1].add(amountToTransfer);
        emit Deposit(_user, _amount, _tokenID);
    }

    function _withdraw(address _user, uint256 _amount, uint256 _tokenID) internal{
        
        require(_amount > 0, "LeEscrow: amount cannot be zero");
        require(_tokenID >= 0, "LeEscrow: tokenID cannot be less than zero");
        
        _tokenExist(_tokenID);
        TokenInfo memory ti = listOfTokenInfo[_tokenID];
        IERC20 token = IERC20(ti.tokenAddress);
        
        token.transferFrom(withdrawTreasury, _user, _amount.mul(10**ti.decimal));
        
        emit Withdraw(_user, _amount, _tokenID);

    }


    function depositBySig(
        address user,
        uint256 amount, 
        uint256 tokenID, 
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) public nonReentrant {
        Signing.checkExpiry(deadline, block.timestamp);
        uint256 nonce = nonces[user]++;
        bytes32 digest;
        {
            bytes memory message = abi.encode(DEPOSIT_TYPEHASH, user, amount, tokenID, nonce, deadline);
            digest = Signing.eip712Hash(DOMAIN_SEPARATOR, message);
        }
        Signing.verifySignature(user, digest, v, r, s);

        _deposit(user, amount, tokenID);
        
    }


    function withdrawBySig(
        address user,
        uint256 amount,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) public nonReentrant {
        Signing.checkExpiry(deadline, block.timestamp);
        uint256 nonce = nonces[user]++;
        bytes32 digest;
        {
            bytes memory message = abi.encode(WITHDRAW_TYPEHASH, user, amount, tokenID, nonce, deadline);
            digest = Signing.eip712Hash(DOMAIN_SEPARATOR, message);
        }
        Signing.verifySignature(user, digest, v, r, s);
        require(msg.sender == withdrawTreasury, "LeEscrow: Must be from withdraw Treasury");
        _withdraw(user, amount, tokenID);

    }

    function _revertZeroAddress(address _address) private pure {
        require(_address != address(0), "LeEscrow:ZERO_ADDRESS");
    }

    function _tokenExist(uint256 _id) private view {
        require( _id < listOfTokenInfo.length, "LeEscrow:TOKEN DONT EXIST");
    }

    function addToken(address _tokenAddress, uint256 _rates, uint256 _decimal) public onlyOwner{
        _revertZeroAddress(_tokenAddress);
        require(_rates > 0, "LeEscrow: rates must be more than 0");
        require(_decimal > 0, "LeEscrow: decimal must be more than 0");
        listOfTokenInfo.push(TokenInfo({
            tokenAddress: _tokenAddress,
            rates: _rates,
            decimal: _decimal
        }));
    }

    function replaceToken(uint256 _tokenID, address _tokenAddress, uint256 _rates, uint256 _decimal) public onlyOwner{
        _tokenExist(_tokenID);
        TokenInfo memory ti  = listOfTokenInfo[_tokenID];
        ti.tokenAddress = _tokenAddress;
        ti.rates = _rates;
        ti.decimal = _decimal;
        listOfTokenInfo[_tokenID] = ti;
    }

    function withdrawToTreasury(uint256 _tokenId) public onlyOwner {
        _tokenExist(_tokenId);

        TokenInfo memory ti = listOfTokenInfo[_tokenId];
        IERC20 token = IERC20(ti.tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transferFrom(address(this),depositTreasury, balance);

    }

    function viewAllTokenList() public view returns(TokenInfo[] memory) {
        return listOfTokenInfo;
    }   

    function setDepositTreasury(address _depositTreasury) public onlyOwner{
        _revertZeroAddress(_depositTreasury);
        depositTreasury = _depositTreasury;
    }

    function setWithdrawTreasury(address _withdrawTreasury) public onlyOwner{
        _revertZeroAddress(_withdrawTreasury);
        withdrawTreasury = _withdrawTreasury;
    }

}