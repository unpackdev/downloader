// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/shadow.sol


pragma solidity ^0.8.0;


contract ShadowStorage {
    struct tokenDetail{
        address nftAddress; //nft address
        uint256 tokenId;    //tokenId
        bool status;        //status 
    }

    mapping (address=> mapping(uint256=>uint256)) private shadows;  //NFT => Id => shadowId
    mapping (uint256=>tokenDetail) public shadowDetails;            //shadowId => tokenDetails

    function getShadowId(address nft, uint256 tokenId) public view returns(uint256) {
        return shadows[nft][tokenId];
    }

    function isExistShadow(address nft, uint256 tokenId) public view returns(bool) {
        return shadows[nft][tokenId] != 0;
    }

    function isActiveShadow(uint256 shadowId) public view returns(bool) {
        return shadowDetails[shadowId].status;
    }

    function _newShadow(address nft, uint256 tokenId, uint256 shadowId) internal {
        shadows[nft][tokenId] = shadowId;
        shadowDetails[shadowId] = tokenDetail(nft, tokenId, true);
    }  

    function _updataShadow(uint256 tokenId, bool status) internal{
        shadowDetails[tokenId].status = status;
    }
}

interface IERC721Metadata{
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract Shadow is ShadowStorage, IERC721{
    //ERC721 metadata
    string public name;
    string public symbol;
    uint256 public totalsupply;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    function setShadow(string memory _name, string memory _symbol) internal {
        name = _name;
        symbol = _symbol;
    }

    function ownerOf(uint256 tokenId) public view override returns(address owner){
        return _owners[tokenId];
    }

    function balanceOf(address owner) public view override returns(uint256 balance){
        return _balances[owner];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        tokenDetail memory s = shadowDetails[tokenId];
        return IERC721Metadata(s.nftAddress).tokenURI(s.tokenId);
    }
    
    function _mint(address to) private returns(uint256 tokenId) {
        totalsupply++;
        tokenId = totalsupply;
    
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _revive(address to, uint256 tokenId) private {
        require(totalsupply >= tokenId,"Shadow: unexist tokenId");
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
   
    function mint(address to, address nft, uint256 tokenId) internal {
        require(to != address(0), "Shadow: zero address");
        uint256 sid;
        if (isExistShadow(nft, tokenId)){  
            sid = getShadowId(nft, tokenId);
            _revive(to, sid);
            _updataShadow(sid, true);
        }else {
            sid = _mint(to);   
            _newShadow(nft, tokenId, sid);
        }
    }

    function burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        _updataShadow(tokenId, false);
        emit Transfer(owner, address(0), tokenId);
    }

    //---virtuel function for ERC721 
    function approve(address to, uint256 tokenId) external override{}
    function transferFrom(address from, address to, uint256 tokenId) external override{}
    function safeTransferFrom(address from, address to, uint256 tokenId) external override{}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override{}
    function setApprovalForAll(address operator, bool approved) external override{}
    function getApproved(uint256 tokenId) external view override returns (address){}
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {}
    function supportsInterface(bytes4 interfaceId) external view override returns (bool){}
}

// File: contracts/factory.sol


pragma solidity ^0.8.0;



interface Ilink {
    function initialize(address _factory, address _nft, address _userA, address _userB, uint256 _idA, uint256 _idB, uint256 _lockDays) external;
    function userB() external returns(address);
    function idB() external returns(uint256);
    function NFT() external returns(address);
    function agree() external;
}

contract Ownable{
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner{
        require(_owner != address(0), "owner address cannot be 0");
        owner = _owner;
    }
}

contract Initialize {
    bool internal initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Config is Ownable{
    uint256 public minLockDay;
    uint256 public maxLockDay;
    address public nftLink;
    mapping(address => bool) public allowedNFT;
    mapping(address => bool) public shadowNeed;
    mapping(address => bool) public isLink;
    uint256 public totalLink;

    function setNftLink(address link) external onlyOwner {
        require(link != address(0), "link address cannot be 0");
        nftLink = link;
    }

    function setLockDay(uint256 min, uint256 max) external onlyOwner {
        (minLockDay, maxLockDay) = (min, max);
    }

    function addProject(address nft, bool isNeedShadow) external onlyOwner {
        require(nft != address(0), "nft address cannot be 0");
        allowedNFT[nft] = true;
        shadowNeed[nft] = isNeedShadow;
    }

    function removeProject(address nft) external onlyOwner {
        delete allowedNFT[nft];
        delete shadowNeed[nft];
    }
}

contract CloneFactory {
    function _clone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract FactoryV2 is Ownable, Config, Initialize, CloneFactory, Shadow {
    event Create(address indexed from, address indexed target, address indexed nft, address link, bool isFullLink);
    event LinkActive(address _link, address _user, uint256 _methodId);

    modifier onlyLink(){
        require(isLink[msg.sender], "only Link");
        _;
    } 

    function initialize(address link) noInit public {
        (minLockDay, maxLockDay) = (1, 1285);
        setShadow("ATM-SHADOW", "ATS");
        nftLink = link;
        owner = msg.sender;
    }

    function getToken(address nft, address user, uint256 id) onlyLink external {
         IERC721(nft).transferFrom(user, msg.sender, id);
    }

    function mintShadow(address to, address nft, uint256 tokenId) onlyLink external {
        mint(to, nft, tokenId);
    }

    function burnShadow(address nft, uint256 tokenId) onlyLink external {
        uint256 sid = getShadowId(nft, tokenId);
        burn(sid);
    }

    function createLink(address nft, address target, uint256[] calldata tokenId, uint256 lockDays) external{
        require(target != address(0),"target cannot be 0");
        require(target != msg.sender,"target cannot be self");
        require(allowedNFT[nft], "nft invalid");
        require(lockDays >= minLockDay && lockDays <= maxLockDay, "lockDays invalid");
        require(tokenId.length == 1 || tokenId.length == 2, "tokenId invalid");
        bool isFullLink = tokenId.length == 2;
        IERC721 NFT = IERC721(nft);
        if (isFullLink){
            //fullLink
            require(tokenId[0] != 0 && tokenId[1] != 0, "tokenId invalid");
            require(tokenId[0] != tokenId[1], "tokenId cannot be the same");
            require(NFT.ownerOf(tokenId[0]) == msg.sender && NFT.ownerOf(tokenId[1]) == msg.sender,"not token owner");
            require(NFT.isApprovedForAll(msg.sender, address(this)) || (NFT.getApproved(tokenId[0]) == address(this) && NFT.getApproved(tokenId[1]) == address(this)),"not Approved");
        }else{
            //normalLink
            require(tokenId[0] != 0, "tokenId invalid");
            require(NFT.ownerOf(tokenId[0]) == msg.sender,"not token owner");
            require(NFT.isApprovedForAll(msg.sender, address(this)) || NFT.getApproved(tokenId[0]) == address(this),"not Approved");
        }

        //create contract
        Ilink link = Ilink(_clone(nftLink));
        totalLink++;
        isLink[address(link)] = true;
        uint256 idB = isFullLink ? tokenId[1] : 0;

        //transfer token   
        NFT.transferFrom(msg.sender, address(link), tokenId[0]);
        if (isFullLink) {
            NFT.transferFrom(msg.sender, address(link), tokenId[1]);
        }

        //create shadowNFT
        if (shadowNeed[nft]){
            mint(msg.sender, nft, tokenId[0]);
            if (isFullLink) {
                mint(msg.sender, nft, tokenId[1]);
            }
        }

        //set link info
        link.initialize(address(this), nft, msg.sender, target, tokenId[0], idB, lockDays);
        emit Create(msg.sender, target, nft, address(link), isFullLink);
    }

    function linkActive(address _user, uint256 _methodId) external{
        require(isLink[msg.sender], "Factory: only Link");
        emit LinkActive(msg.sender, _user, _methodId);
    }
}