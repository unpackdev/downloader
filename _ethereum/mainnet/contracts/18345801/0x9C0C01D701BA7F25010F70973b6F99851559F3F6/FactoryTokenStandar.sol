// File: contracts/COMMON/common.sol


pragma solidity ^0.8.18;

library Address {   
    function isContract(address account) internal view returns (bool) { 
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeMath {   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/Factorys/FactoryBase.sol


pragma solidity ^0.8.19;


contract FactoryBase is Context, Ownable {
    using Address for address;
    using SafeMath for uint256;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    struct TokenInfo {
        string name;
        string symbol;
        address tokenAddress;
    }

    mapping(address => TokenInfo[]) internal myTokens;

    struct ConfigEtherStruct {
        bool isActive;
        uint256 paymentAmount;
    }

    struct ConfigTokenStruct {
        string name;
        bool isActive;
        uint256 paymentAmount;
    }

    ConfigEtherStruct public configEther;

    mapping(address => ConfigTokenStruct) public tokenMatrix;

    event WithdrawalSuccessful(address indexed owner, uint256 amount);
    event WithdrawalTokenSuccessful(address, address, uint256);
    event onTransferFromEvent(address, address, uint256 amount);
    event onTokenCreatedEvent(address, address, string, string, uint256);

    function addContractToken(
        address owner,
        string memory _name,
        string memory _symbol,
        address _tokenAddress
    ) internal {
        myTokens[owner].push(TokenInfo(_name, _symbol, _tokenAddress));
    }

    function getContractTokenByAddress(address owner)
        external
        view
        returns (TokenInfo[] memory)
    {
        return myTokens[owner];
    }

    function updateTokenConfig(
        address _tokenAddress,
        string memory _name,
        bool _isActive,
        uint256 _paymentAmount
    ) public onlyOwner {
        tokenMatrix[_tokenAddress].name = _name;
        tokenMatrix[_tokenAddress].isActive = _isActive;
        tokenMatrix[_tokenAddress].paymentAmount = _paymentAmount;
    }

    function updateEtherConfig(bool _isActive, uint256 _paymentAmount)
        public
        onlyOwner
    {
        configEther.isActive = _isActive;
        configEther.paymentAmount = _paymentAmount;
    }

    function removeTokenConfig(address _tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        if (tokenMatrix[_tokenAddress].isActive) {
            delete tokenMatrix[_tokenAddress];
            return true;
        } else {
            return false;
        }
    }

    function requireTokenActive(address _tokenAddress) internal view virtual {
        ConfigTokenStruct storage token = tokenMatrix[_tokenAddress];
        require(token.isActive, "El token no est\u00E1 activo");
    }

    function isERC20Token(address tokenAddress)
        internal
        view
        virtual
        returns (bool)
    {
        IERC20 token = IERC20(tokenAddress);
        try token.totalSupply() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }

    function requireValidERC20Token(address _tokenAddress)
        internal
        view
        virtual
    {
        require(
            isERC20Token(_tokenAddress),
            "El token no es un token ERC20 v\u00E1lido"
        );
    }

    //obtener monto del servicio del token
    function getTokenPaymentAmount(address _tokenAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        ConfigTokenStruct storage token = tokenMatrix[_tokenAddress];
        return token.paymentAmount;
    }

   
    // Función para retirar dinero de la moneda de la red
    function withdrawByEther(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Saldo insuficiente en el contrato");
        payable(_msgSender()).transfer(_amount);
        emit WithdrawalTokenSuccessful(owner(), address(this), _amount);
    }

    // Función para retirar dinero de un token específico
    function withdrawByToken(address _tokenAddress, uint256 _amount) external onlyOwner {
        requireValidERC20Token(_tokenAddress);
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Saldo insuficiente en el contrato" );
        IERC20(_tokenAddress).transfer(_msgSender(), _amount);
        emit WithdrawalTokenSuccessful(owner(), _tokenAddress, _amount);
    }

    //obtener balance de un tokens
    function getBalanceToken(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        requireValidERC20Token(_tokenAddress);
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(address(this));
    }

    //obtener balance principal
    function getBalanceEther() external view returns (uint256) {
        return address(this).balance;
    }
}

// File: contracts/Factorys/FactoryTokenStandar.sol


pragma solidity ^0.8.19;



interface TokenFacory {
    function createToken(
        string memory _NAME,
        string memory _SYMBOL,
        uint256 _DECIMALS,
        uint256 _supply,
        uint256 _txFee,
        uint256 _lpFee,
        uint256 _DexFee,
        address feeaddress,
        address tokenOwner,
        address _owner
    ) external returns (address);
}

contract FactoryTokenStandar is FactoryBase {
    TokenFacory tokenFactory;
    address private contractAddress;

    constructor(address _owner, address _contractAddress) FactoryBase(_owner) {
        tokenFactory = TokenFacory(_contractAddress);
        contractAddress = _contractAddress;
        _transferOwnership(_owner);
    }

    //deploy tokens paid cryptocurrency
    function deployPaidByEther(
        string memory _NAME,
        string memory _SYMBOL,
        uint256 _DECIMALS,
        uint256 _supply,
        uint256 _txFee,
        uint256 _lpFee,
        uint256 _DexFee,
        address feeaddress,
        address tokenOwner
    ) external payable returns (address) {
        require(configEther.isActive, "El pago no esta activo");
        require(
            msg.value == configEther.paymentAmount,
            "No tienes suficiente saldo para pagar el servicio"
        );
        address newERC20 = tokenFactory.createToken(
            _NAME,
            _SYMBOL,
            _DECIMALS,
            _supply,
            _txFee,
            _lpFee,
            _DexFee,
            feeaddress,
            tokenOwner,
            owner()
        );
        addContractToken(_msgSender(), _NAME, _SYMBOL, newERC20);
        return address(newERC20);
    }

    //deploy tokens paid valid tokens
    function deployPaidByToken(
        string memory _NAME,
        string memory _SYMBOL,
        uint256 _DECIMALS,
        uint256 _supply,
        uint256 _txFee,
        uint256 _lpFee,
        uint256 _DexFee,
        address feeaddress,
        address tokenOwner,
        address _tokenAddress
    ) external returns (address) {
        requireTokenActive(_tokenAddress);
        requireValidERC20Token(_tokenAddress);
        uint256 toPayment = getTokenPaymentAmount(_tokenAddress);       
        require(
            IERC20(_tokenAddress).balanceOf(_msgSender()) >= toPayment,
            "No tienes suficientes tokens"
        );

        require(
            IERC20(_tokenAddress).allowance(_msgSender(), address(this)) >= toPayment,
            "Error al autorizar los tokens"
        );

        require(
            IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), toPayment),
            "Error en transferencia de los tokens"
        );

        address newERC20 = tokenFactory.createToken(
            _NAME,
            _SYMBOL,
            _DECIMALS,
            _supply,
            _txFee,
            _lpFee,
            _DexFee,
            feeaddress,
            tokenOwner,
            owner()
        );
        addContractToken(_msgSender(), _NAME, _SYMBOL, newERC20);
        return address(newERC20);
    }

    function updateTokenFactoryAddress(address _newTokenFactoryAddress) external onlyOwner {
        require(_newTokenFactoryAddress != address(0), "La nueva direccion no puede ser cero");
        tokenFactory = TokenFacory(_newTokenFactoryAddress);
        contractAddress = _newTokenFactoryAddress;
    }

    function getTokenFactoryAddress() external view onlyOwner returns (address){
        return contractAddress;
    }
}