// SPDX-License-Identifier: UNLICENSED
// © Copyright 2022. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.19;

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title IERC165
/// @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}



/// @author Guillaume Gonnaud 2023
/// @title ERC721 for lazy minted drops.
/// How to use : 
/// Constructor, then setTokenURIPrefix to setup a prefix (default is tokenID as suffix)
/// call setAuthorizedLazyMinters(GBMDIamondAddress, true) to allow Lazy minting by the GBM contract
contract ER721LazyMinted is IERC721, IERC165 {

    string public name; // Returns the name of the token - e.g. "Generic ERC721".
    string public symbol; // Returns the symbol of the token. E.g. GEN721.
    mapping(address => uint256) public override balanceOf; //The number of token an address own
    uint256 public totalSupply; //The total amount of minted tokens
    mapping(uint256 => string) tokenURIs;

    string public tokenURIPrefix;
    bool public usingTokenIDAsSuffix;
    mapping(address => bool) public authorizedLazyMinters;

    address public owner;

    mapping(uint256 => address) internal ownerOfVar;
    mapping(uint256 => address) internal approvedTransferAddress; //Address allowed to Transfer a token
    mapping(address => mapping(address => bool)) internal approvedOperator; //Approved operators mapping: owner => operator => allowed?

    mapping(bytes4 => bool) supportedInterfaces;

    /// @notice Constructor
    /// @dev Please change the values in here if you want more specific values, or make the constructor takes arguments
    constructor(string memory _name, string memory _symbol)
    {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;

        usingTokenIDAsSuffix = true;

        supportedInterfaces[0x2a55205a] = true; //Royalty standard ERC2981
        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata  support (NFT images/json)
        supportedInterfaces[0x01ffc9a7] = true; //ERC165
        
    }   

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external override view returns (address){
        return ownerOfVar[_tokenId];
    }


    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external override payable{
        safeTransferFromInternal(_from, _to, _tokenId, data);
    }


    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override payable{
        safeTransferFromInternal(_from, _to, _tokenId, "");
    }


    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external override payable{
        transferFromInternal(_from, _to, _tokenId);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external override payable{
        require(msg.sender == ownerOfVar[_tokenId] || 
            approvedOperator[ownerOfVar[_tokenId]][msg.sender],
            "approve: msg.sender is not allowed to approve the token"
        );

        approvedTransferAddress[_tokenId] = _approved;
        emit Approval(ownerOfVar[_tokenId], _approved, _tokenId);
    }


    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external override {
        approvedOperator[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external override view returns (address){
        return approvedTransferAddress[_tokenId];
    }


    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external override view returns (bool){
        return  approvedOperator[_owner][_operator];
    }


    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external override view returns (bool){
        return (supportedInterfaces[interfaceID]);
    }


    function setTokenURIPrefix(string calldata prefix) external {
        require(owner == msg.sender, "Only the owner can set the prefix");
        tokenURIPrefix = prefix;
    }

    function setUsingTokenIDAsSuffix(bool usingSuffix) external {
        require(owner == msg.sender, "Only the owner can set the suffix rule");
        usingTokenIDAsSuffix = usingSuffix;
    }

    /// @notice Allow or disallow an address from calling transfer (0x0, to, tokenID)
    /// @param minter The address of the minter
    /// @param authorized true if to make the address a lazy minter, false to remove the authorization
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    function setAuthorizedLazyMinters(address minter, bool authorized) external {
        require(owner == msg.sender, "Only the owner can set the lazy minters");
        authorizedLazyMinters[minter] = authorized;
    }


    /// @notice Mint a token for msg.sender
    function mint(string calldata _URI, uint256 _tokenID) external returns (uint256) {
        require(owner == msg.sender, "Only the owner can mint");
        require( ownerOfVar[_tokenID] == address(0), "Token Already minted");
        return internalMint(_URI, _tokenID);
    }


    function internalMint(string calldata _URI, uint256 _tokenID) internal returns (uint256){

        totalSupply++;
        balanceOf[msg.sender] = balanceOf[msg.sender] + 1;

        //Changing ownership
        ownerOfVar[_tokenID] = msg.sender;
        tokenURIs[_tokenID] = _URI;

        //Emitting transfer event
        emit Transfer(address(0x0), msg.sender, _tokenID);

        return totalSupply;
    }


    /// @dev Called by both variants of Safetransfer. Is a transfer followed by a smartContract check and then
    /// an onERC721Received call
    function safeTransferFromInternal(address _from, address _to, uint256 _tokenId, bytes memory data) internal {
        transferFromInternal(_from, _to, _tokenId);
        
        if(isContract(_to)){
            //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) == 0x150b7a02
            require(IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) == bytes4(0x150b7a02));
        }
    }


    /// @dev Actual token transfer code called by all the other functions
    function transferFromInternal(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0x0), "transferFromInternal: Tokens cannot be send to 0x0. Use 0xdead instead ?");
        require(ownerOfVar[_tokenId] == _from, "transferFromInternal: _from is not the owner of the token");
        require(msg.sender == ownerOfVar[_tokenId] || 
            approvedOperator[ownerOfVar[_tokenId]][msg.sender] ||
            msg.sender == approvedTransferAddress[_tokenId] ||
            (authorizedLazyMinters[msg.sender] && _from == address(0x0)),
            "transferFromInternal: msg.sender is not allowed to manipulate the token"
        );

        // Adjusting token balances
        if(_from != address(0x0)){
            balanceOf[_from] = balanceOf[_from] - 1;
        } else {
            totalSupply++;
        }
        balanceOf[_to] = balanceOf[_to] + 1;

        //Resetting approved addresse permission
        approvedTransferAddress[_tokenId] = address(0x0);

        //Changing ownership
        ownerOfVar[_tokenId] = _to;

        //Emitting transfer event
        emit Transfer(_from, _to, _tokenId);
        
    }
    

    /// @notice Check if an address is a contract
    /// @param _address The adress you want to test
    /// @return true if the address has bytecode, false if not
    function isContract(address _address) internal view returns(bool){
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_address) }
        return (codehash != accountHash && codehash != 0x0);
    }


    mapping(uint256 => address) royaltyReceiver;
    mapping(uint256 => uint256) royaltyPercentage;

    function setRoyaltyInfo(uint256, address receiver, uint256 percentkage) external {
        require(msg.sender == owner);
        royaltyReceiver[0] = receiver;
        royaltyPercentage[0] = percentkage;
    }


    function royaltyInfo(uint256, uint256 finalAmount) public view returns(address receiver, uint256 royaltyAmount) {
        uint256 royalty = finalAmount * royaltyPercentage[0] / 10000;
        return(royaltyReceiver[0], royalty);
    }


    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory){
        if(bytes(tokenURIs[_tokenId]).length != 0){
            return (tokenURIs[_tokenId]);
        } else if(usingTokenIDAsSuffix) {
            return string.concat(tokenURIPrefix, toString(_tokenId), ".json");
        } else {
            return tokenURIPrefix;
        }
    }


    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal {
        tokenURIs[_tokenId] = _tokenURI;
    }


    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        require(msg.sender == owner);
        _setTokenURI(_tokenId, _tokenURI);
    }


    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) { 
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), "0123456789"))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }


    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

}