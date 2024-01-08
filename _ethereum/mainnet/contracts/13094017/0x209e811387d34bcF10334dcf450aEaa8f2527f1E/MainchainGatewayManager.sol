pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./Math.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

interface IERC20Mintable {
    function mint(address _to, uint256 _value) external returns (bool _success);
}

interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function approve(address _to, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool _approved);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;
}

interface IERC721Mintable {
    function mint(address _to, uint256 _tokenId) external returns (bool);

    function mintNew(address _to) external returns (uint256 _tokenId);
}

library AddressUtils {
    function toPayable(address _address)
        internal
        pure
        returns (address payable _payable)
    {
        return payable(_address);
    }

    function isContract(address _address)
        internal
        view
        returns (bool _correct)
    {
        uint256 _size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _size := extcodesize(_address)
        }
        return _size > 0;
    }
}

contract HasMinters is Ownable {
    event MinterAdded(address indexed _minter);
    event MinterRemoved(address indexed _minter);

    address[] public minters;
    mapping(address => bool) public minter;

    modifier onlyMinter() {
        require(minter[msg.sender]);
        _;
    }

    function addMinters(address[] memory _addedMinters) public onlyOwner {
        address _minter;

        for (uint256 i = 0; i < _addedMinters.length; i++) {
            _minter = _addedMinters[i];

            if (!minter[_minter]) {
                minters.push(_minter);
                minter[_minter] = true;
                emit MinterAdded(_minter);
            }
        }
    }

    function removeMinters(address[] memory _removedMinters) public onlyOwner {
        address _minter;

        for (uint256 i = 0; i < _removedMinters.length; i++) {
            _minter = _removedMinters[i];

            if (minter[_minter]) {
                minter[_minter] = false;
                emit MinterRemoved(_minter);
            }
        }

        uint256 i = 0;

        while (i < minters.length) {
            _minter = minters[i];

            if (!minter[_minter]) {
                minters[i] = minters[minters.length - 1];
                delete minters[minters.length - 1];
            } else {
                i++;
            }
        }
    }

    function isMinter(address _addr) public view returns (bool) {
        return minter[_addr];
    }
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool public paused;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }
}

interface IRegistry {
    function getContract(string calldata _name) external view returns (address _address);

    function isTokenMapped(address _token, uint32 _standard, bool _isMainchain) external view returns (bool);

    function updateContract(string calldata _name, address _newAddress) external;

    function mapToken( address _mainchainToken, address _sidechainToken, uint32 _standard) external;

    function clearMapToken(address _mainchainToken, address _sidechainToken) external;

    function getMappedToken(address _token, bool _isMainchain) external view returns ( address _mainchainToken, address _sidechainToken, uint32 _standard);
}

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract MainchainGatewayStorage is Pausable {

    event TokenDeposited(
        uint256 indexed _depositId,
        address indexed _owner,
        address indexed _tokenAddress,
        address _sidechainAddress,
        uint32 _standard,
        uint256 _tokenNumber // ERC-20 amount or ERC721 tokenId
    );

    event TokenWithdrew(
        uint256 indexed _withdrawId,
        address indexed _owner,
        address indexed _tokenAddress,
        uint256 _tokenNumber
    );

    struct DepositEntry {
        address owner;
        address tokenAddress;
        address sidechainAddress;
        uint32 standard;
        uint256 tokenNumber;
    }

    struct WithdrawalEntry {
        address owner;
        address tokenAddress;
        uint256 tokenNumber;
    }

    IRegistry public registry;

    uint256 public depositCount;
    DepositEntry[] public deposits;
    mapping(uint256 => WithdrawalEntry) public withdrawals;

    constructor(address _registry) public{
        registry = IRegistry(_registry);
    }

    function updateRegistry(address _registry) external onlyOwner {
        registry = IRegistry(_registry);
    }
}

/**
 * @title MainchainGatewayManager
 * @dev Logic to handle deposits and withdrawl on Mainchain.
 */
contract MainchainGatewayManager is MainchainGatewayStorage {
    using AddressUtils for address;
    using SafeMath for uint256;

    modifier onlyMappedToken(address _token, uint32 _standard) {
        require(
            registry.isTokenMapped(_token, _standard, true),
            "MainchainGatewayManager: Token is not mapped"
        );
        _;
    }

    modifier onlyNewWithdrawal(uint256 _withdrawalId) {
        WithdrawalEntry storage _entry = withdrawals[_withdrawalId];
        require(
            _entry.owner == address(0) && _entry.tokenAddress == address(0)
        );
        _;
    }

    constructor(address _registry) public MainchainGatewayStorage(_registry){ 
        
    }

    function depositERC20(address _token, uint256 _amount) external whenNotPaused returns (uint256)
    {
        return depositERC20For(msg.sender, _token, _amount);
    }

    function depositERC721(address _token, uint256 _tokenId) external whenNotPaused returns (uint256){
        return depositERC721For(msg.sender, _token, _tokenId);
    }

    function depositERC20For(address _user, address _token, uint256 _amount) public whenNotPaused returns (uint256) {
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "MainchainGatewayManager: ERC-20 token transfer failed"
        );
        return _createDepositEntry(_user, _token, 20, _amount);
    }

    function depositERC721For(address _user, address _token, uint256 _tokenId) public whenNotPaused returns (uint256) {
        IERC721(_token).transferFrom(msg.sender, address(this), _tokenId);
        return _createDepositEntry(_user, _token, 721, _tokenId);
    }

    function depositBulkFor(address _user, address[] memory _tokens, uint256[] memory _tokenNumbers) public whenNotPaused {
        require(_tokens.length == _tokenNumbers.length);

        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            address _token = _tokens[_i];
            uint256 _tokenNumber = _tokenNumbers[_i];
            (, , uint32 _standard) = registry.getMappedToken(_token, true);

            if (_standard == 20) {
                depositERC20For(_user, _token, _tokenNumber);
            } else if (_standard == 721) {
                depositERC721For(_user, _token, _tokenNumber);
            } else {
                revert("Token is not mapped or token type not supported");
            }
        }
    }

    function withdrawToken(uint256 _withdrawalId, address _token, uint256 _amount) public whenNotPaused {
        withdrawTokenFor(
            _withdrawalId,
            msg.sender,
            _token,
            _amount
        );
    }

    function withdrawTokenFor(uint256 _withdrawalId, address _user, address _token, uint256 _amount) public whenNotPaused {
        (, , uint32 _tokenType) = registry.getMappedToken(_token, true);

        if (_tokenType == 20) {
            withdrawERC20For(
                _withdrawalId,
                _user,
                _token,
                _amount
            );
        } else if (_tokenType == 721) {
            withdrawERC721For(
                _withdrawalId,
                _user,
                _token,
                _amount
            );
        }
    }

    function withdrawERC20(uint256 _withdrawalId, address _token, uint256 _amount) public whenNotPaused {
        withdrawERC20For(
            _withdrawalId,
            msg.sender,
            _token,
            _amount
        );
    }

    function withdrawERC20For(uint256 _withdrawalId, address _user, address _token, uint256 _amount) public onlyOwner whenNotPaused onlyMappedToken(_token, 20) {
        uint256 _gatewayBalance = IERC20(_token).balanceOf(address(this));
        if (_gatewayBalance < _amount) {
            require(
                IERC20Mintable(_token).mint(
                    address(this),
                    _amount.sub(_gatewayBalance)
                ),
                "MainchainGatewayManager: Minting ERC20 token to gateway failed"
            );
        }
        require(IERC20(_token).transfer(_user, _amount), "Transfer failed");
        _insertWithdrawalEntry(_withdrawalId, _user, _token, _amount);
    }

    function withdrawERC721( uint256 _withdrawalId, address _token, uint256 _tokenId) public whenNotPaused {
        withdrawERC721For(
            _withdrawalId,
            msg.sender,
            _token,
            _tokenId
        );
    }

    function withdrawERC721For(uint256 _withdrawalId, address _user, address _token, uint256 _tokenId) public onlyOwner whenNotPaused onlyMappedToken(_token, 721) {
        if (!_tryERC721TransferFrom(_token, address(this), _user, _tokenId)) {
            require(
                IERC721Mintable(_token).mint(_user, _tokenId),
                "MainchainGatewayManager: Minting ERC721 token to gateway failed"
            );
        }

        _insertWithdrawalEntry(_withdrawalId, _user, _token, _tokenId);
    }

    function _createDepositEntry(address _owner, address _token, uint32 _standard, uint256 _number) 
    internal onlyMappedToken(_token, _standard) returns (uint256 _depositId) {
        (, address _sidechainToken, uint32 _tokenStandard) = registry.getMappedToken(_token, true);
        require(_standard == _tokenStandard);

        DepositEntry memory _entry = DepositEntry(_owner, _token, _sidechainToken, _standard, _number);

        deposits.push(_entry);
        _depositId = depositCount++;

        emit TokenDeposited(_depositId, _owner, _token, _sidechainToken, _standard, _number);
    }

    function _insertWithdrawalEntry(uint256 _withdrawalId, address _owner, address _token, uint256 _number) internal onlyNewWithdrawal(_withdrawalId) {
        WithdrawalEntry memory _entry = WithdrawalEntry(
            _owner,
            _token,
            _number
        );

        withdrawals[_withdrawalId] = _entry;

        emit TokenWithdrew(_withdrawalId, _owner, _token, _number);
    }

    function _tryERC721TransferFrom(address _token, address _from, address _to, uint256 _tokenId) internal returns (bool) {
        (bool success, ) = _token.call(
            abi.encodeWithSelector(
                IERC721(_token).transferFrom.selector,
                _from,
                _to,
                _tokenId
            )
        );
        return success;
    }
}
