// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./BaseAccessControl.sol";
import "./DragonInfo.sol";
import "./DragonToken.sol";

contract DragonSwapper is BaseAccessControl, IERC721Receiver {
    
    using Address for address payable;

    string public constant OWNER_ERROR = "DragonSwapper: caller is not owner";
    string public constant BAD_AMOUNT_ERROR = "DragonSwapper: bad amount";
    string public constant BAD_ADDRESS_ERROR = "DragonSwapper: bad address";
    string public constant NOT_VALID_OPERATOR_ERROR = "DragonSwapper: the caller is not a valid operator";

    address private _tokenContractAddress;
    address private _burnAddress;
    uint private _swapPrice;
    mapping(uint => address) private _lockedTokens;

    event TokenLocked(address indexed owner, uint tokenId, uint dragonValue, address polygonTo);
    event TokenUnlocked(address indexed owner, uint tokenId);
    event TokenBurned(uint tokenId);
    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    constructor(uint price, address accessControl, address tokenContractAddress, address burnAddr) 
    BaseAccessControl(accessControl) {
        _swapPrice = price;
        _tokenContractAddress = tokenContractAddress;
        _burnAddress = burnAddr;
    }

    function burnAddress() public view returns (address) {
        return _burnAddress;
    }

    function tokenContract() public view returns (address) {
        return _tokenContractAddress;
    }

    function setTokenContract(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _tokenContractAddress;
        _tokenContractAddress = newAddress;
        emit AddressChanged("tokenContract", previousAddress, newAddress);
    }

    function swapPrice() public view returns (uint) {
        return _swapPrice;
    }

    function setSwapPrice(uint newPrice) external onlyRole(CFO_ROLE) {
        uint previousValue = _swapPrice;
        _swapPrice = newPrice;
        emit ValueChanged("swapPrice", previousValue, newPrice);
    }

    function onERC721Received(address operator, address /*from*/, uint /*tokenId*/, bytes calldata /*data*/) 
        external virtual override returns (bytes4) {
        require(operator == address(this), NOT_VALID_OPERATOR_ERROR);
        return this.onERC721Received.selector;
    }

    function swap(uint tokenId, address polygonTo) payable external {
        DragonToken dt = DragonToken(tokenContract());
        
        require(msg.value >= swapPrice(), BAD_AMOUNT_ERROR);
        require(dt.ownerOf(tokenId) == _msgSender(), OWNER_ERROR);
        require(!Address.isContract(polygonTo), BAD_ADDRESS_ERROR);

        dt.safeTransferFrom(_msgSender(), address(this), tokenId);
        
        DragonInfo.Details memory details = dt.dragonInfo(tokenId);
        _lockedTokens[tokenId] = _msgSender();
        
        emit TokenLocked(_msgSender(), tokenId, DragonInfo.getValue(details), polygonTo);
    }

    function unlock(uint tokenId) external onlyRole(COO_ROLE) {
        address owner = _lockedTokens[tokenId];
        
        if (owner != address(0)) {
            DragonToken dt = DragonToken(tokenContract());
            dt.safeTransferFrom(address(this), owner, tokenId);
            delete _lockedTokens[tokenId];

            emit TokenUnlocked(owner, tokenId);
        }
    }

    function burn(uint tokenId) external onlyRole(COO_ROLE) {
        address owner = _lockedTokens[tokenId];
        
        if (owner != address(0)) {
            DragonToken dt = DragonToken(tokenContract());
            dt.safeTransferFrom(address(this), burnAddress(), tokenId);
            delete _lockedTokens[tokenId];

            emit TokenBurned(tokenId);
        }
    }

    function withdrawEthers(uint amount, address payable to) external onlyRole(CFO_ROLE) {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }
}
