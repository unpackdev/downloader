// SPDX-License-Identifier: MIT OR Apache-2.0
import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";

import "./SafeMath.sol";
import "./IERC1155Receiver.sol";
import "./IERC20.sol";


pragma solidity ^0.8.7;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity >=0.7.0 <0.9.0;

// interface IFomoNFT1155 {
//     function creators(uint256) external returns (address);
// }

contract NFTMarket is ReentrancyGuard, Ownable   {
    using SafeMath for uint256;
    using Address for address;

    bool private enableChangeToken = false;
    bool private enableMint = true;

    /*╔═════════════════════════════╗
      ║          STRUCT             ║
      ╚═════════════════════════════╝*/
    struct NftData {
        address nftContractAddress;
        uint256 tokenId;
        address payable owner;
        uint256 price;
        // address nftMintOwner;
        uint256 serviceFees;
        // Fees[] creatorFees;
        bool onSelling;
        uint256 qty;
        uint256 pId;
    }

    struct TokenInfo {IERC20 paytoken; }
    TokenInfo[] public AllowedCrypto;

    // uint256 commisionFeesPercentage = 20;

    /*
     * nftContract address -> tokenId -> NftData
     */
    mapping(address => mapping(uint256 => mapping(address => NftData))) public nftMarketItems;
    mapping(bytes32 => Fees[]) public creatorFees;

    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    /*
     * only nft owner can do this operation 
     */
    modifier isNftOwner(address _nftContractAddress, uint256 _tokenId) {
        require(
          IERC1155(_nftContractAddress).balanceOf(msg.sender, _tokenId) != 0,
          "ony nft owner can do this operation"
        );
      _;
    }

    /*
     * only nft owner can do this operation 
     */
    modifier isCheckOwner(address _nftContractAddress, uint256 _tokenId) {
      require(
          nftMarketItems[_nftContractAddress][_tokenId][msg.sender].owner == msg.sender,
          "ony nft owner can do this operation"
      );
      _;
    }

    /*
     * nft owner can't do this operation
     */
    modifier isNotNftOwner(address _nftContractAddress,uint256 _tokenId) {
      require(
          IERC1155(_nftContractAddress).balanceOf(msg.sender, _tokenId) == 0,
          "nft owner can't do this operation"
        );
       require(
          nftMarketItems[_nftContractAddress][_tokenId][msg.sender].owner != msg.sender,
          "nft owner can't do this operation"
      );
      _;
    }

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event NftDataCreated (
        address nftContractAddress,
        uint256 tokenId,
        address owner,
        uint256 price,
        // address nftMintOwner,
        uint256 royalties,
        bool onSelling,
        uint256 qty, uint256 poolId
    );

    /*╔══════════════════════════════╗
      ║      SET COMMISON            ║
      ╚══════════════════════════════╝*/

    // function setCommisonFee(uint256 _commision) external onlyOwner {
    //     commisionFeesPercentage = _commision;
    // }

    struct Fees {
        address payable receiver;
        uint16 percent;
    }

    function _getSaleId(
        address _seller,
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _qty, uint256 _pId
    ) internal pure returns ( bytes32 ){
        return keccak256(
            abi.encodePacked(
                _seller,
                _nftContractAddress,
                _tokenId,
                _price,
                _qty,
                _pId
            )
        );

    }

    /*╔══════════════════════════════╗
      ║      SELL NFT ON MARKET      ║
      ╚══════════════════════════════╝*/

    function sellNFTOnMarket(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price,
        // address _nftMintOwner,
        uint256 _serviceFees,
        address payable[] calldata _creators,
        uint16[] calldata _creatorFees,
        uint256 _qty,
        uint256 _pId
    )   public
        isNftOwner(_nftContractAddress, _tokenId)
        nonReentrant {
        require(_price > 0, "Price must be at least 1 wei!");
        require(_nftContractAddress != address(0), "Incorrect contract address!");
        require(_tokenId >= 0, "Incorrect token id!");
        require(nftMarketItems[_nftContractAddress][_tokenId][msg.sender].qty <= 0, "Already on Sale from you");

        IERC1155(_nftContractAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _qty, '');

        nftMarketItems[_nftContractAddress][_tokenId][msg.sender] =  NftData(
            _nftContractAddress,
            _tokenId,
            payable(msg.sender),
            _price,
            // _nftMintOwner,
            _serviceFees,
            // creatorFees,
            true,
            _qty,
            _pId
        );
        // ;
        bytes32 saleId = _getSaleId(msg.sender, _nftContractAddress, _tokenId, _price, _qty, _pId);
        for (uint8 i=0; i<_creators.length; i++) {
        //     // Fees memory c;
            creatorFees[saleId].push(Fees(_creators[i], _creatorFees[i]));
        //     // creatorFees[i] = c;
        }

        emit NftDataCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _price, 
            // _nftMintOwner,
            _serviceFees,
            true,
            _qty,
            _pId
        );
        // return saleId;
    }

    /*╔══════════════════════════════╗
      ║      BUY NFT FROM MARKET     ║
      ╚══════════════════════════════╝*/

    function buyNFTOnMarket(
        address _nftContractAddress,
        uint256 _tokenId,
        address _from,
        uint256 _newPrice,
        uint256 _qty,
        uint256 _pId, uint256 cost
    )   public 
        isNotNftOwner(_nftContractAddress,_tokenId)
        payable 
        nonReentrant {
            require(enableMint, "Buying Paused");

            require(_nftContractAddress != address(0), "Incorrect contract address!");
            require(nftMarketItems[_nftContractAddress][_tokenId][_from].nftContractAddress == _nftContractAddress, "Incorrect contract address!");
            require(_newPrice > 0, "Invalid new price!");

            if(_pId == 99999){
                require(msg.value == _newPrice, "Invalid price!");
                require(msg.value >= nftMarketItems[_nftContractAddress][_tokenId][_from].price, "Invalid price!");
            }
            else{
                if(nftMarketItems[_nftContractAddress][_tokenId][_from].pId == _pId && _pId != 99999) {
                    require(cost == _newPrice, "Invalid price!");
                    require(cost >= nftMarketItems[_nftContractAddress][_tokenId][_from].price, "Invalid price!");
                }
                else {
                  revert("Not Allowed");
                }
            }
            require(_tokenId >= 0, "Incorrect token id!"); 

            _sendCreatorEarnings(_tokenId, _nftContractAddress, _from, _pId, cost);          

            IERC1155(_nftContractAddress).safeTransferFrom(
                address(this),
                msg.sender, 
                _tokenId,
                _qty,
                ''
            );
            _resetValue(_nftContractAddress,_tokenId, _from, nftMarketItems[_nftContractAddress][_tokenId][_from].price, _qty, false, _pId);
    }

    function _sendCreatorEarnings(uint256 _tokenId, address _nftContractAddress, address _seller, uint256 _pId, uint256 cost) internal {
        uint256 fees = 0;
        bytes32 saleId = _getSaleId(_seller, _nftContractAddress, _tokenId, nftMarketItems[_nftContractAddress][_tokenId][_seller].price, nftMarketItems[_nftContractAddress][_tokenId][_seller].qty, _pId);
        // disable creaor earning from minting form the main contract
        for (uint256 i = 0; i < creatorFees[saleId].length; ++i) {
            fees += SafeMath.div(
                SafeMath.mul(
                    creatorFees[saleId][i].percent,
                    msg.value
                ),
                10000
            );
            
            // msg.value*nftMarketItems[_nftContractAddress][_tokenId][_seller].creatorFees[i].percent/10000;
            Address.sendValue(
                creatorFees[saleId][i].receiver,
                SafeMath.div(
                    SafeMath.mul(
                        creatorFees[saleId][i].percent,
                        msg.value
                    ),
                    10000
                )
            );
        }

        uint256 serviceFees = SafeMath.div(
            SafeMath.mul(
                msg.value, nftMarketItems[_nftContractAddress][_tokenId][_seller].serviceFees
            ),
            10000
        );

        /////Non ERC 20 token
        if(_pId == 99999)
        {
            Address.sendValue(
                nftMarketItems[_nftContractAddress][_tokenId][_seller].owner,
                SafeMath.sub(
                    msg.value,
                    SafeMath.add(
                        fees,
                        serviceFees
                    )
                )
            );
        }
        else{
            IERC20 paytoken;
            TokenInfo storage tokens = AllowedCrypto[_pId];
            paytoken = tokens.paytoken;
            paytoken.transferFrom(msg.sender, nftMarketItems[_nftContractAddress][_tokenId][_seller].owner, 
            SafeMath.sub(
                    cost,
                    SafeMath.add(
                        fees,
                        serviceFees
                    )
                )
            );
        }
    }

    
    /*╔══════════════════════════════╗
      ║       CANCLE NFT ON MARKET   ║
      ╚══════════════════════════════╝*/

    function cancleNFTOnMarket(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _qty,
        uint256 _pId
    )   public 
        isCheckOwner(_nftContractAddress,_tokenId)
        nonReentrant {
           require(_nftContractAddress != address(0), "Incorrect contract address!");
           require(_tokenId >= 0, "Incorrect token id!");

            IERC1155(_nftContractAddress).safeTransferFrom(
                address(this),
                nftMarketItems[_nftContractAddress][_tokenId][msg.sender].owner, 
                _tokenId,
                _qty,
                ''
            );
            _resetValue(_nftContractAddress,_tokenId, msg.sender, nftMarketItems[_nftContractAddress][_tokenId][msg.sender].price, _qty, true, _pId);
      }

    /*╔══════════════════════════════╗
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/

    /*
     * Reset all parameters for an NFT.
     * This effectively removes an EFT as an item up
     */
    function _resetValue(address _nftContractAddress, uint256 _tokenId, address _from, uint256 _price, uint256 _qty, bool isCancel, uint256 _pId) internal
    {        
        if(isCancel || nftMarketItems[_nftContractAddress][_tokenId][_from].qty - _qty == 0) {
            bytes32 saleId = _getSaleId(_from, _nftContractAddress, _tokenId, _price, _qty, _pId);
            delete nftMarketItems[_nftContractAddress][_tokenId][_from];
            delete creatorFees[saleId];
        } else {
                nftMarketItems[_nftContractAddress][_tokenId][_from].qty -= _qty;
        }
    }

    function updateSaleData(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _serviceFees,
        address payable[] calldata _creators,
        uint16[] calldata _creatorFees,
        uint256 _qty, uint256 _pId
    )   public onlyOwner {
        nftMarketItems[_nftContractAddress][_tokenId][msg.sender] =  NftData(
            _nftContractAddress,
            _tokenId,
            payable(msg.sender),
            _price,
            _serviceFees,
            true,
            _qty,
            _pId
        );

        bytes32 saleId = _getSaleId(msg.sender, _nftContractAddress, _tokenId, _price, _qty, _pId);
        for (uint8 i=0; i<_creators.length; i++) {
            creatorFees[saleId].push(Fees(_creators[i], _creatorFees[i]));
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function withdrawFunds(uint256 withdrawAmount) external onlyOwner {
        require(address(this).balance > 0 && withdrawAmount <= address(this).balance, "Insufficient Fund");
        (bool success, ) = msg.sender.call{value: withdrawAmount}("");
        require(success, "Withdraw failed.");
    }
    
    function transferFund(uint256 transferAmount, address transferTo) external onlyOwner {
        require(address(this).balance > 0 && transferAmount <= address(this).balance, "Insufficient Fund");
        (bool success,) = transferTo.call{value: transferAmount}("");
        require(success, "Transfer Failed");
    }

    function addCurrency(IERC20 _paytoken) public onlyOwner {
        AllowedCrypto.push( TokenInfo({paytoken: _paytoken}) );
    }

    function withdrawToken(uint256 _pid) public payable onlyOwner() {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }

    function setEnableMint(bool _enableMint) external onlyOwner{
        enableMint = _enableMint;
    }

    function getEnableMint() external view onlyOwner returns (bool){
        return enableMint;
    }

    function setEnableChangeToken(bool _enableTc) external onlyOwner{
        enableChangeToken = _enableTc;
    }

    function getEnableChangeToken() external view onlyOwner returns (bool){
        return enableChangeToken;
    }
}