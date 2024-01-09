// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./BaseAccessControl.sol";

abstract contract LockableReceiver is BaseAccessControl, IERC721Receiver {
    
    using Address for address payable;

    address private _tokenContractAddress;
    mapping(uint => address) private _lockedTokens;

    event TokenLocked(uint tokenId, address indexed holder);
    event TokenWithdrawn(uint tokenId, address indexed holder);
    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    constructor (address accessControl, address tokenContractAddress) 
    BaseAccessControl(accessControl) {
        _tokenContractAddress = tokenContractAddress;
    }

    modifier whenLocked(uint tokenId) {
        require(isLocked(tokenId), "LockableReceiver: token must be locked");
        _;
    }

    modifier onlyHolder(uint tokenId) {
        require(holderOf(tokenId) == _msgSender(), "LockableReceiver: caller is not the token holder");
        _;
    }

    function onERC721Received(address operator, address /*from*/, uint /*tokenId*/, bytes calldata /*data*/) 
        external virtual override returns (bytes4) {
        require(operator == address(this), "LockableReceiver: the caller is not a valid operator");
        return this.onERC721Received.selector;
    }

    function receiveApproval(address sender, uint tokenId, address _tokenContract, bytes calldata data) external virtual {
        require(tokenContract() == _msgSender(), "LockableReceiver: not enough privileges to call the method");
        require(_tokenContract == tokenContract(), "LockableReceiver: unable to receive the given token");
    
        IERC721(tokenContract()).safeTransferFrom(sender, address(this), tokenId, data);
        
        _lock(tokenId, sender);
        processERC721(sender, tokenId, data);
    }

    function processERC721(address from, uint tokenId, bytes calldata data) internal virtual {
    }

    function _lock(uint tokenId, address holder) internal {
        _lockedTokens[tokenId] = holder;
        emit TokenLocked(tokenId, holder);
    }

    function _unlock(uint tokenId) internal {
        delete _lockedTokens[tokenId];
    }

    function tokenContract() public view returns (address) {
        return _tokenContractAddress;
    }

    function setTokenContract(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _tokenContractAddress;
        _tokenContractAddress = newAddress;
        emit AddressChanged("tokenContract", previousAddress, newAddress);
    }

    function isLocked(uint tokenId) public view returns (bool) {
        return _lockedTokens[tokenId] != address(0);
    }

    function holderOf(uint tokenId) public view returns (address) {
        return _lockedTokens[tokenId];
    }

    function withdrawEthers(uint amount, address payable to) external virtual onlyRole(CFO_ROLE) {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function withdraw(uint tokenId) public virtual onlyHolder(tokenId) {
        _transferTokenToHolder(tokenId);
        emit TokenWithdrawn(tokenId, _msgSender());
    }

    function _transferTokenToHolder(uint tokenId) internal virtual {
        address holder = holderOf(tokenId);
        if (holder != address(0)) {
            IERC721(tokenContract()).safeTransferFrom(address(this), holder, tokenId);
            _unlock(tokenId);
        }
    }
} 