/**
Author: BlockRocket.tech.

*/

pragma solidity ^0.5.14;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

library Strings {
    
    function fromUint256(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) public view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) public view returns (address owner);

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        
        
        
        uint256 _value; 
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract ERC165 is IERC165 {
    
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        
        
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    
    mapping (uint256 => address) private _tokenOwner;

    
    mapping (uint256 => address) private _tokenApprovals;

    
    mapping (address => Counters.Counter) private _ownedTokensCount;

    
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(address from, address to, uint256 tokenId) public {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    
    mapping(address => uint256[]) private _ownedTokens;

    
    mapping(uint256 => uint256) private _ownedTokensIndex;

    
    uint256[] private _allTokens;

    
    mapping(uint256 => uint256) private _allTokensIndex;

    
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    
    constructor () public {
        
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        
        

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        
        _ownedTokens[from].length--;

        
        
    }

    
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        
        

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        
        
        
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 

        
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721MetadataWithoutTokenURI is ERC165, ERC721, IERC721Metadata {
    
    string private _name;

    
    string private _symbol;

    
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    
    function name() external view returns (string memory) {
        return _name;
    }

    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
}

contract CustomERC721Full is ERC721, ERC721Enumerable, ERC721MetadataWithoutTokenURI {
    constructor (string memory name, string memory symbol) public ERC721MetadataWithoutTokenURI(name, symbol) {
        
    }
}

contract IVideoLatinoTokenCreator {
    function mintToken(
        uint256 _tokenId,
        address _recipient,
        string calldata _productCode,
        string calldata _metadataIpfsHash
    ) external returns (bool success);
}

contract IRelayRecipient {
    
    function getHubAddr() public view returns (address);

    
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    
    function preRelayedCall(bytes calldata context) external returns (bytes32);

    
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external;
}

contract IRelayHub {
    

    
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

    
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

    
    function registerRelay(uint256 transactionFee, string memory url) public;

    
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

    
    function removeRelayByOwner(address relay) public;

    
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

    
    function unstake(address relay) public;

    
    event Unstaked(address indexed relay, uint256 stake);

    
    enum RelayState {
        Unknown, 
        Staked, 
        Registered, 
        Removed    
    }

    
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

    

    
    function depositFor(address target) public payable;

    
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

    
    function balanceOf(address target) external view returns (uint256);

    
    function withdraw(uint256 amount, address payable dest) public;

    
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

    

    
    function canRelay(
        address relay,
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public view returns (uint256 status, bytes memory recipientContext);

    
    enum PreconditionCheck {
        OK,                         
        WrongSignature,             
        WrongNonce,                 
        AcceptRelayedCallReverted,  
        InvalidRecipientStatusCode  
    }

    
    function relayCall(
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public;

    
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

    
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

    
    enum RelayCallStatus {
        OK,                      
        RelayedCallFailed,       
        PreRelayedFailed,        
        PostRelayedFailed,       
        RecipientBalanceChanged  
    }

    
    function requiredGas(uint256 relayedCallStipend) public view returns (uint256);

    
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) public view returns (uint256);

     
     
    
    

    
    function penalizeRepeatedNonce(bytes memory unsignedTx1, bytes memory signature1, bytes memory unsignedTx2, bytes memory signature2) public;

    
    function penalizeIllegalTransaction(bytes memory unsignedTx, bytes memory signature) public;

    
    event Penalized(address indexed relay, address sender, uint256 amount);

    
    function getNonce(address from) external view returns (uint256);
}

contract GSNRecipient is IRelayRecipient, Context {
    
    address private _relayHub = 0xD216153c06E857cD7f72665E0aF1d7D82172F494;

    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

    
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

    
    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    
    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

    
    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNRecipient: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNRecipient: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        _relayHub = newRelayHub;
    }

    
    
    
    function relayHubVersion() public view returns (string memory) {
        this; 
        return "1.0.0";
    }

    
    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_relayHub).withdraw(amount, payee);
    }

    
    
    
    

    
    function _msgSender() internal view returns (address payable) {
        if (msg.sender != _relayHub) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    
    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    
    

    
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        return _preRelayedCall(context);
    }

    
    function _preRelayedCall(bytes memory context) internal returns (bytes32);

    
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

    
    function _postRelayedCall(bytes memory context, bool success, uint256 actualCharge, bytes32 preRetVal) internal;

    
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

    
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

    
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

    
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
        
        
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }

    function _getRelayedCallSender() private pure returns (address payable result) {
        
        
        
        
        

        
        

        
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

        
        assembly {
            
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
        
        

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

library ECDSA {
    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        
        if (signature.length != 65) {
            return (address(0));
        }

        
        bytes32 r;
        bytes32 s;
        uint8 v;

        
        
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        
        return ecrecover(hash, v, r, s);
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract TokenLandiaWhitelistGSNRecipient is WhitelistedRole, GSNRecipient {
    using ECDSA for bytes32;

    enum GSNRecipientSignatureErrorCodes {
        INVALID_SENDER
    }

    constructor() public {
        super.addWhitelisted(_msgSender());
    }

    
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    )
    external
    view
    returns (uint256, bytes memory)
    {
        bytes memory blob = abi.encodePacked(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce, 
            getHubAddr(), 
            address(this) 
        );
        bool isOriginalCallerWhitelisted = isWhitelisted(keccak256(blob).toEthSignedMessageHash().recover(approvalData));
        if (isOriginalCallerWhitelisted) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNRecipientSignatureErrorCodes.INVALID_SENDER));
        }
    }

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
        
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
        
    }

    function upgradeRelayHub(address newRelayHub) external onlyWhitelistAdmin {
        _upgradeRelayHub(newRelayHub);
    }
}

contract VideoLatino is CustomERC721Full, IVideoLatinoTokenCreator, TokenLandiaWhitelistGSNRecipient {
    using SafeMath for uint256;

    event ContractCreated(
        address indexed creator
    );

    event VideoInfoUpdated(
        uint256 indexed tokenId,
        string productCode,
        string videoId,
        address indexed caller
    );

    event MetadataIpfsHashUpdated(
        uint256 indexed tokenId,
        string ipfsHash,
        address indexed caller
    );

    event TokenBaseURIUpdated(
        string tokenBaseURI,
        address indexed caller
    );

    string public tokenBaseURI = "";

    struct Token {
        string productCode;
        string metadataIpfsHash;
    }

    mapping(uint256 => Token) public tokens;

    
    mapping(string => uint256) internal videoIdToTokenId;

    modifier onlyWhenTokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "VideoLatino.onlyWhenTokenExists: Token does not exist");
        _;
    }

    constructor (string memory _tokenBaseURI) public
    CustomERC721Full("Video Latino NFT", "VID")
    TokenLandiaWhitelistGSNRecipient() {
        tokenBaseURI = _tokenBaseURI;
        emit ContractCreated(_msgSender());
    }

    
    function mintToken(
        uint256 _tokenId,
        address _recipient,
        string calldata _productCode,
        string calldata _metadataIpfsHash
    ) external onlyWhitelisted returns (bool success) {
        
        {
            
            uint256 productCodeLength = bytes(_productCode).length;
            require(productCodeLength > 0 && productCodeLength <= 7, "VideoLatino.mintToken: Product code must be between 1 and 7 characters.");

            require(bytes(_metadataIpfsHash).length == 46, "VideoLatino.mintToken: Metadata IPFS hash must be 46 characters long");
        }

        
        tokens[_tokenId] = Token({
            productCode: _productCode,
            metadataIpfsHash: _metadataIpfsHash
            });

        
        _mint(_recipient, _tokenId);

        
        string memory videoId = string(
            abi.encodePacked(
                _productCode,
                "-",
                Strings.fromUint256(_tokenId)
            )
        );

        videoIdToTokenId[videoId] = _tokenId;

        return true;
    }

    function attributes(uint256 _tokenId)
    external
    onlyWhenTokenExists(_tokenId) view returns (
        string memory _productCode,
        string memory _metadataIpfsHash
    ) {
        Token memory token = tokens[_tokenId];
        return (
            token.productCode,
            token.metadataIpfsHash
        );
    }

    function videoId(uint256 _tokenId)
    public
    onlyWhenTokenExists(_tokenId) view returns (string memory _videoId) {
        Token memory token = tokens[_tokenId];
        return string(
            abi.encodePacked(
                token.productCode,
                "-",
                Strings.fromUint256(_tokenId)
            )
        );
    }

    function tokenIdForVideoId(string calldata _videoId)
    external
    view returns (uint256 _tokenId) {
        return videoIdToTokenId[_videoId];
    }

    function tokenURI(uint256 _tokenId) external onlyWhenTokenExists(_tokenId) view returns (string memory) {
        return string(abi.encodePacked(tokenBaseURI, tokens[_tokenId].metadataIpfsHash));
    }

    function tokensOfOwner(address owner)
    external
    view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function updateProductCodeForToken(
        uint256 _tokenId,
        string calldata _productCode) external
    onlyWhitelisted onlyWhenTokenExists(_tokenId) {
        
        delete videoIdToTokenId[videoId(_tokenId)];

        string memory newVideoId = string(
            abi.encodePacked(
                _productCode,
                "-",
                Strings.fromUint256(_tokenId)
            )
        );

        
        videoIdToTokenId[newVideoId] = _tokenId;

        
        Token storage token = tokens[_tokenId];
        token.productCode = _productCode;

        emit VideoInfoUpdated(_tokenId, _productCode, newVideoId, _msgSender());
    }

    function updateMetadataIpfsHash(uint256 _tokenId, string calldata _newIpfsHash)
    external
    onlyWhitelisted onlyWhenTokenExists(_tokenId) {
        require(bytes(_newIpfsHash).length == 46, "VideoLatino.updateMetadataIpfsHash: IPFS hash must be 46 characters long.");
        tokens[_tokenId].metadataIpfsHash = _newIpfsHash;
        emit MetadataIpfsHashUpdated(_tokenId, _newIpfsHash, _msgSender());
    }

    function updateTokenBaseURI(string calldata _newBaseURI)
    external
    onlyWhitelistAdmin {
        require(bytes(_newBaseURI).length != 0, "VideoLatino.updateTokenBaseURI: Base URI invalid");
        tokenBaseURI = _newBaseURI;
        emit TokenBaseURIUpdated(_newBaseURI, _msgSender());
    }

    
    function burn(uint256 _tokenId)
    public
    onlyWhitelistAdmin onlyWhenTokenExists(_tokenId) {
        
        delete videoIdToTokenId[videoId(_tokenId)];
        delete tokens[_tokenId];

        
        _burn(_tokenId);
    }

}