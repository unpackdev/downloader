//@notice the interface used for transferring NFTs from sender wallet address to receiver wallet address.
//@notice andalso transfers the assetFee, royaltyFee, platform fee from users.

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./AccessControl.sol";
import "./ITransferProxy.sol";

contract TransferProxy is AccessControl, ITransferProxy {

    //@notice operatorChanged the event is emited at the time of changeOperator function invoke. 
    //@param from address of the previous contract operator.
    //@param to address of the new contract operator.

    event operatorChanged(address indexed from, address indexed to);

    //@notice OwnershipTransferred the event is emited at the time of transferownership function invoke. 
    //@param previousOwner address of the previous contract owner.
    //@param newOwner address of the new contract owner.

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //@notice owner holds current contract owner.

    address public owner;

    //@notice operator holds current contract operator.

    address public operator;


    constructor() {
        owner = msg.sender;
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("OPERATOR_ROLE", operator);
    }

    //@notice changeOperator for transferring contract operator role to new operator address.
    //@param _operator address of new _operator.
    //@return bool value always true. 
    /** restriction: the ADMIN_ROLE address only has the permission to 
    change the contract operator role to new wallet address.*/
    //@dev see{Accesscontrol}.
    // emits {changeOperator} event.

    function changeOperator(address _operator)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            _operator != address(0),
            "Operator: new operator is the zero address"
        );
        _revokeRole("OPERATOR_ROLE", operator);
        operator = _operator;
        _setupRole("OPERATOR_ROLE", operator);
        emit operatorChanged(address(0), operator);
        return true;
    }

    //@notice transferOwnership for transferring contract ownership to new owner address.
    //@param newOwner address of new owner.
    //@return bool value always true. 
    /** restriction: the ADMIN_ROLE address only has the permission to 
    transfer the contract ownership to new wallet address.*/
    //@dev see{Accesscontrol}.
    // emits {OwnershipTransferred} event.

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }
    //@notice the function transfers NFTs to users.
    //@param token, ERC721 address @dev see {IERC721}.
    //@param from, seller address, NFTs to be transferrred from this address.
    //@param to, buyer address, NFTs to be received to this address.
    //@param tokenId, unique NFT id to be transfer.

    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyRole("OPERATOR_ROLE") {
        token.safeTransferFrom(from, to, tokenId);
    }

    //@notice the function transfers ERC721 NFTs to users.
    //@param token, ERC1155 @dev see {IERC1155}.
    //@param from, seller address, NFTs to be transferrred from this address.
    //@param to, buyer address, NFTs to be received to this address.
    //@param tokenId, unique NFT id to be transfer.

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override onlyRole("OPERATOR_ROLE") {
        token.safeTransferFrom(from, to, tokenId, value, data);
    }

    //@notice function used for ERC1155Lazymint, it does NFT minting and NFT transfer.
    //@param nftAddress, ERC1155 @dev see {IERC1155}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered 'from' address to this address.
    //@param _tokenURI, IPFS URI of NFT to be Minted.
    //@param _royaltyFee, fee permiles for secondary sale.
    //@param _receivers, fee receivers for secondary sale.
    //@param supply, copies to minted to creator 'from' address.
    //@param qty, copies to be transfer to receiver 'to' address.
    //@return _tokenId, NFT unique id.
    //@dev see {ERC1155}.

    function mintAndSafe1155Transfer(
        ILazyMint token,
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,        
        uint256 supply,
        uint256 qty
    ) external override onlyRole("OPERATOR_ROLE") {
        token.mintAndTransfer(from, to, _tokenURI, _royaltyFee, _receivers, supply, qty);
    }

    //@notice function used for ERC721Lazymint, it does NFT minting and NFT transfer.
    //@param nftAddress, ERC721 address @dev see {IERC721}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered from address to this address.
    //@param _tokenURI, IPFS URI of NFT to be Minted.
    //@param _royaltyFee, fee permiles for secondary sale.
    //@param _receivers, fee receivers for secondary sale.
    //@return _tokenId, NFT unique id.
    //@dev see {ERC721}.

    function mintAndSafe721Transfer(
        ILazyMint token,
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers
    ) external override onlyRole("OPERATOR_ROLE") {
        token.mintAndTransfer(from, to, _tokenURI, _royaltyFee, _receivers);
    }
    
    //@notice the, function used for transferring token from 'from' address to 'to' address.
    //@param token, ERC20 address(WETH, WBNB, WMATIC) @dev see {IERC20}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered 'from' address to this address.
    //@param value, amount of tokens to transfer(Royalty, assetFee, platformFee...).

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external override onlyRole("OPERATOR_ROLE") {
        require(
            token.transferFrom(from, to, value),
            "failure while transferring"
        );
    }
}