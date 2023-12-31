// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/erc20/kfcdao/KFCdaoPassAdmin.sol


pragma solidity ^0.8.0;


contract KFCdaoPassAdmin is Ownable {
    KFCdao public kfcdao;

    constructor(address _nftContract) {
        kfcdao = KFCdao(_nftContract);
    }

    function setNFTContract(address _nftContract) public onlyOwner {
        kfcdao = KFCdao(_nftContract);
    }

    function removeAdmin(address _admin) public {
        kfcdao.removeAdmin(_admin);
    }

    function addAdminBatch(address[] memory _admins) public {
        kfcdao.addAdminBatch(_admins);
    }

    function removeFromWhiteList(address _address) public {
        kfcdao.removeFromWhiteList(_address);
    }

    function addToWhiteListBatch(address[] memory _addresses) public {
        kfcdao.addToWhiteListBatch(_addresses);
    }

    function setBaseParameters(
        bool _whiteListMintEnabled,
        uint256 _maxSupply,
        uint256 _mintStartBlock,
        uint256 _mintEndBlock,
        uint256 _mintPrice
    ) public {
        kfcdao.setBaseParameters(
            _whiteListMintEnabled,
            _maxSupply,
            _mintStartBlock,
            _mintEndBlock,
            _mintPrice
        );
    }

    function setDefaultURI(string memory _defaultURI) public {
        kfcdao.setDefaultURI(_defaultURI);
    }

    function withdrawThis() external {
        payable(owner()).transfer(address(this).balance);
    }

    function withdraw() external {
        kfcdao.withdraw();
    }

    function mintAdmin() external {
        kfcdao.mintAdmin();
    }

    function enableWhiteListMint() public {
        kfcdao.enableWhiteListMint();
    }

    function disableWhiteListMint() public {
        kfcdao.disableWhiteListMint();
    }

    function whiteListMintEnabled() external view returns (bool) {
        return kfcdao.whiteListMintEnabled();
    }

    function burn(uint256 _tokenId) external {
        kfcdao.burn(_tokenId);
    }
}

interface KFCdao {
    function removeAdmin(address _admin) external;

    function removeFromWhiteList(address _address) external;

    function setBaseParameters(
        bool _whiteListMintEnabled,
        uint256 _maxSupply,
        uint256 _mintStartBlock,
        uint256 _mintEndBlock,
        uint256 _mintPrice
    ) external;

    function setDefaultURI(string memory _defaultURI) external;

    function mintAdmin() external payable;

    function withdraw() external;

    function addToWhiteListBatch(address[] memory _addresses) external;

    function addAdminBatch(address[] memory _admins) external;

    function enableWhiteListMint() external;

    function disableWhiteListMint() external;

    function whiteListMintEnabled() external view returns (bool);

    function burn(uint256 _tokenId) external;
}