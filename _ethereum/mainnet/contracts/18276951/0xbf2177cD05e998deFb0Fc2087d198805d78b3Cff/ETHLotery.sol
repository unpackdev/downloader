/**
 *Submitted for verification at Etherscan.io on 2023-08-01
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
            address from,
            address to,
            uint256 amount
        ) external returns (bool);
}

/** Chainlink VRF */
interface LinkTokenInterface {
    function transferAndCall(
            address to,
            uint256 value,
            bytes calldata data
        ) external returns (bool success);
}
contract VRFRequestIDBase {
    function makeVRFInputSeed(
            bytes32 _keyHash,
            uint256 _userSeed,
            address _requester,
            uint256 _nonce
        ) internal pure returns (uint256) {
            return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
        }
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
        }
}
abstract contract VRFConsumerBase is VRFRequestIDBase {
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;
        uint256 private constant USER_SEED_PLACEHOLDER = 0;
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }
    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;
    /**
    * @param _vrfCoordinator address of VRFCoordinator contract
    * @param _link address of LINK token contract
    *
    * @dev https://docs.chain.link/docs/link-token-contracts
    */
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

contract Random is VRFConsumerBase {
    /** Statisitcs*/
    uint256 public rand_counter;
    struct _RequestsIDs{
        bytes32 requestId;
        uint256 rand_results;
    }
    mapping(uint256 => _RequestsIDs) public RequestsIDs;
    /** Randoms*/

    bytes32 internal keyHash;
    uint256 internal rand_fee;
    uint256 public randomResult;

        /*  mainnet
    LINK Token	0x514910771AF9Ca656af840dff83E8264EcF986CA
    VRF Coordinator	0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
    Key Hash	0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
    */

    constructor() VRFConsumerBase
    (0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
    0x514910771AF9Ca656af840dff83E8264EcF986CA)  // LINK Token
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        rand_fee = 2 * 10**18;
    }
    function getRandomNumber() public returns (bytes32 requestId) {
        return requestRandomness(keyHash, rand_fee);
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override{
         randomResult = randomness;
         /** Statisitcs*/
         RequestsIDs[rand_counter].requestId = requestId;
         RequestsIDs[rand_counter].rand_results = randomness;
         rand_counter ++;
    }
}

/** ERC721 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


library Address {
    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ReentrancyGuard {
    // word because each write operation emits an extra SLOAD to first read the
    // back. This is the compiler's defense against contract upgrades and

    // but in exchange the refund on every call to nonReentrant will be lower in
    // transaction's gas, it is best to keep them low in cases like this one, to
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract ERC721A is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 private currentIndex = 0;
    uint256 internal immutable collectionSize;
    uint256 internal immutable maxBatchSize;
    string private _name;
    string private _symbol;
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerships;
    mapping(address => AddressData) private _addressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) {
        require(
            collectionSize_ > 0,
            "ERC721A: collection must have a nonzero supply"
        );
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
    }
    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < totalSupply(), "ERC721A: global index out of bounds");
        return index;
    }
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721A: unable to get token of owner by index");
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: balance query for the zero address"
        );
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert("ERC721A: unable to determine the owner of token");
    }
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721A: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId, owner);
    }
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721A: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != _msgSender(), "ERC721A: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721A: transfer to non ERC721Receiver implementer"
        );
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "ERC721A: mint to the zero address");
        require(!_exists(startTokenId), "ERC721A: token already minted");
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(
            isApprovedOrOwner,
            "ERC721A: transfer caller is not owner nor approved"
        );

        require(
            prevOwnership.addr == from,
            "ERC721A: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721A: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);
        _approve(address(0), tokenId, prevOwnership.addr);

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(
                    prevOwnership.addr,
                    prevOwnership.startTimestamp
                );
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "quantity must be nonzero");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > collectionSize - 1) {
            endIndex = collectionSize - 1;
        }
        require(_exists(endIndex), "not enough minted yet for this cleanup");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(
                    ownership.addr,
                    ownership.startTimestamp
                );
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721A: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

contract ETHLotery is Ownable, ERC721A, ReentrancyGuard, Random {

    bool public publicSale = true;
    uint256 public maxToken = 10000; 
    uint256 public price = 1*10**16; // ETH
    uint256 public tickets_per_raffle = 5;
    uint256 public last_raffle = 0;
    string  private _baseTokenURI;
    address public burn_address = 0xe7BE149fB160Ba37D96f051cafd2dC22fA9707Ef; // wallet for buyback and burn
    address public link_address = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // Link Token
    uint256 burn_percent = 20;    

    constructor(string memory _NAME, string memory _SYMBOL, string memory baseTokenURI)
        ERC721A(_NAME, _SYMBOL, 1000, 10*10**9)
    {
        _baseTokenURI = baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ""))
                : "";
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(publicSale, "SALE_HAS_NOT_STARTED_YET");
        require(quantity > 0, "INVALID_QUANTITY");
        require(quantity <= tickets_per_raffle, "CANNOT_MINT_THAT_MANY");
        require(totalSupply() + quantity <= maxToken, "NOT_ENOUGH_SUPPLY_TO_MINT_DESIRED_AMOUNT");   
        require(msg.value >= quantity * price, ": Value insufficient");

        /** Get raffle*/
        if(totalSupply() + quantity >= last_raffle + tickets_per_raffle){
        /** mint tickets*/
        _safeMint(msg.sender, quantity);

        /** get from ChainLink*/
        getRandomNumber();
        
        /** calc winner*/      
        uint winner_ticket_ID = randomResult % tickets_per_raffle + last_raffle;
        address winner = IERC721(address(this)).ownerOf(winner_ticket_ID);

        /* calc funds**/
        uint256 prize_fund = tickets_per_raffle * price *  (100 - burn_percent) / 100; 
        uint256 burn_fund = tickets_per_raffle * price * burn_percent / 100;  
       
        /** Pay winner*/
        payable(winner).transfer(prize_fund);

        /** burning */
        payable(burn_address).transfer(burn_fund);
        
        last_raffle +=tickets_per_raffle;

        } else {

            _safeMint(msg.sender, quantity);    

        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function set_burn_percent(uint256 _burn_percent) external onlyOwner {
        burn_percent = _burn_percent;
    }

    function set_maxToken(uint256 _maxToken) external onlyOwner {
        maxToken = _maxToken;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function set_tickets_per_raffle(uint256 _tickets_per_raffle) external onlyOwner {
        tickets_per_raffle = _tickets_per_raffle;
    }

    function set_burn_address(address _burn_address) external onlyOwner {
        burn_address = _burn_address;
    }    

    function flipPublicSaleState() external onlyOwner {
        publicSale = !publicSale;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function withdrawLink() external onlyOwner {
        IERC20(link_address).transfer(msg.sender, IERC20(link_address).balanceOf(address(this)) );
    }
}