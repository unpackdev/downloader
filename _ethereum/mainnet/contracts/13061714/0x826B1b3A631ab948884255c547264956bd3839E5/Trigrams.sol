// "SPDX-License-Identifier: MIT"
// TX 18.08.2021

//pragma solidity ^0.8.4;
pragma solidity ^0.4.24;

/**
 * ████████ ██████  ██  ██████  ██████   █████  ███    ███  ███████ 
 *    ██    ██   ██ ██ ██       ██   ██ ██   ██ ████  ████  ██      
 *    ██    ██████  ██ ██   ███ ██████  ███████ ██ ████ ██  ███████ 
 *    ██    ██   ██ ██ ██    ██ ██   ██ ██   ██ ██  ██  ██       ██ 
 *    ██    ██   ██ ██  ██████  ██   ██ ██   ██ ██      ██  ███████ 
 *                                                                                                          
 *                                                                                                         
 *                                                            by Tx
 * 
 * inspired by 
 * 
 *      ***    **     ** ********  *******   ******   **     **    ** ********  **     **  ******
 *     ** **   **     **    **    **     ** **    **  **      **  **  **     ** **     ** **    **
 *    **   **  **     **    **    **     ** **        **       ****   **     ** **     ** **
 *   **     ** **     **    **    **     ** **   **** **        **    ********  *********  ******
 *   ********* **     **    **    **     ** **    **  **        **    **        **     **       **
 *   **     ** **     **    **    **     ** **    **  **        **    **        **     ** **    **
 *   **     **  *******     **     *******   ******   ********  **    **        **     **  ******
 * 
 *                                                                 by Matt Hall and John Watkinson
 *
 *
 * The output of the 'tokenURI' function is a set of instructions to make a drawing.
 * Each symbol in the output corresponds to a cell, and there are 5x5 symbols arranged in a square grid.
 * The drawing can be any size, and the pen's stroke width should be between 1/5th to 1/10th the size of a cell.
 * The drawing instructions for the nine different symbols are as follows:
 *
 *  Draw corresponding trigram in a cell.
 *
 */
 
interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes /*memory*/ _data) external returns(bytes4);
}

contract Trigrams {

    event Generated(uint indexed index, address indexed a, string value);

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

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant TOKEN_LIMIT = 1024; // 8 for testing, 1024 for prod
    uint public constant ARTIST_PRINTS = 2;  // 2 for testing, 2 for prod
    uint public constant PRICE = 200 * 1000000000000000; // 'finney':       '1000000000000000',
    
    // The beneficiary is SemanticCORD
    address public constant BENEFICIARY = 0x5877734C2245BfCbB6e26638c28eBaE48a8a944E;

    mapping (uint => address) private idToCreator;
    mapping (uint => uint8) private idToSymbolScheme;

    // ERC 165
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping (uint256 => address) internal idToOwner;

    /**
     * @dev A mapping from NFT ID to the seed used to make it.
     */
    mapping (uint256 => uint256) internal idToSeed;
    mapping (uint256 => uint256) internal seedToId;

    /**
     * @dev Mapping from NFT ID to approved address.
     */
    mapping (uint256 => address) internal idToApproval;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Total number of tokens.
     */
    uint internal numTokens = 0;

    /**
     * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }

    /**
     * @dev Guarantees that _tokenId is a valid Token.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }

    /**
     * @dev Contract constructor.
     */
    constructor()  {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }

    ///////////////////
    //// GENERATOR ////
    ///////////////////

    int constant  ONE = int(0x100000000);
    uint constant USIZE = 15;
    
    int constant SIZE = int(USIZE);
    int constant HALF_SIZE = SIZE / int(2);
    int constant SIZEH = (SIZE/3);
    int constant HALF_SIZEH = SIZEH / int(2);
    
    bytes prefix = "data:text/plain;charset=utf-8,";

    string internal nftName = "Trigrams";
    string internal nftSymbol = "☳☰☶☴☶";
    // ☰☰☱.

    function abs(int n) internal pure returns (int) {
        if (n >= 0) return n;
        return -n;
    }

    function getScheme(uint a) internal pure returns (uint8) {
        uint index = a % 100;
        uint8 scheme;             
        if (index <= 5) {
            scheme = 1;           // (5% with potential for all trigrams)
        } else if (index <= 20) {  
            scheme = 2;           // (15% with potential for 7 trigrams)
        } else if (index <= 45) {  
            scheme = 3;           // (25% with potential for 6 trigrams)
        } else if (index <= 71) {  
            scheme = 4;           // (26% with potential for 5 trigrams)
        } else {
            scheme = 5;           // (29% with potential for 4 trigrams)         
        } 
        return scheme;
    }

    /* * ** *** ***** ******** ************* ******** ***** *** ** * */
    
    // The following code generates art.
    function draw(uint id) public view returns (string) {
        uint a = uint(uint160(keccak256(abi.encodePacked(idToSeed[id]))));
        bytes memory output = new bytes(uint(SIZEH) * USIZE * 3);
        uint c = 0;
        uint v = 0;
        //uint mod = (a % 11) + 5;
        int x = 0;
        int y = 0;
        uint tmod = 8;
        
        if (idToSymbolScheme[id] == 0) {
            revert();
        } 
        tmod = uint(tmod - (idToSymbolScheme[id]-1)); // reduce available set
        
        //trigrams endings 0xB0 B1 B2 B3 B4 B5 B6 B7; // #O
        for (int i = int(0); i < SIZEH; i++) {
            y = (2 * (i - HALF_SIZEH) + 1);
            if (a % tmod == 1) {
                y = -y;
            }
            else if (a % tmod == 2) {
                y = abs(y);
            }
            y = y * int(a);
            
            for (int j = int(0); j < SIZE; j+=3) {
                x = (2 * (j - HALF_SIZE) + 1);
                x = x * int(a);
                
                v = uint(x * y / ONE) % tmod;
                {
                    output[c] = byte(0xE2);
                    c++;
                    output[c] = byte(0x98);
                    c++;
                    output[c] = byte(0xB0 + int(v));
                    c++;
                } 
            }
            
            output[c] = byte(0x25);
            c++;
            output[c] = byte(0x30);
            c++;
            output[c] = byte(0x41);
            c++;
        }
        
        bytes memory full = new bytes(c + 30);
        for (v = 0; v < 30; v++) { // reuse var to copy
            full[v] = prefix[v];
        }
        for (v = 30; v < 30+c; v++) { // add data
            full[v] = output[v-30];
        }

        return string(full);
    }
    
    /* * ** *** ***** ******** ************* ******** ***** *** ** * */

    function creator(uint _id) external view returns (address) {
        return idToCreator[_id];
    }

    function symbolScheme(uint _id) external view returns (uint8) {
        return idToSymbolScheme[_id];
    }

    function createGlyph(uint seed) external payable returns (string memory) {
        return _mint(msg.sender, seed);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    /**
     * @dev Returns whether the target address is a contract.
     * @param _addr Address to check.
     * @return addressCheck True if _addr is a contract, false if not.
     */
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
     * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
     * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
     * function checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes /*memory*/ _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice This works identically to the other function with an extra data parameter, except this
     * function just sets data to ""
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
     * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
     * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
     * they maybe be permanently lost.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }

    /**
     * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
     * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
     * the current NFT owner, or an authorized operator of the current owner.
     * @param _approved Address to be approved for the given NFT ID.
     * @param _tokenId ID of the token to be approved.
     */
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of
     * `msg.sender`'s assets. It also emits the ApprovalForAll event.
     * @notice This works even if sender doesn't own any tokens at the time.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     * @return Balance of _owner.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    /**
     * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
     * invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT.
     * @return _owner Address of _tokenId owner.
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }

    /**
     * @dev Get the approved address for a single NFT.
     * @notice Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId ID of the NFT to query the approval of.
     * @return Address that _tokenId is approved for.
     */
    function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    /**
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    /**
     * @dev Actually preforms the transfer.
     * @notice Does NO checks.
     * @param _to Address of a new owner.
     * @param _tokenId The NFT that is being transferred.
     */
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    /**
     * @dev Mints a new NFT.
     * @notice This is an internal function which should be called from user-implemented external
     * mint function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     * @param _to The address that will own the minted NFT.
     */
    function _mint(address _to, uint seed) internal returns (string memory) {
        require(_to != address(0));
        require(numTokens < TOKEN_LIMIT, "token limit");
        uint amount = 0;
        if (numTokens >= ARTIST_PRINTS) {
            amount = PRICE;
            require(msg.value >= amount, "!value");
        }
        require(seedToId[seed] == 0, "!seed");
        
        uint id = numTokens + 1;

        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        uint a = uint(bytes32(keccak256(abi.encodePacked(seed)))); // 132354123 // 1231231
        idToSymbolScheme[id] = getScheme(a);
        
        string memory uri = draw(id);

        emit Generated(id, _to, uri);

        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        if (msg.value > amount) {
            msg.sender.transfer(msg.value - amount);
        }
        if (amount > 0) {
            BENEFICIARY.transfer(amount);
        } 

        emit Transfer(address(0), _to, id);
        return uri; 
    }

    /**
     * @dev Assigns a new NFT to an address.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _to Address to which we want to add the NFT.
     * @param _tokenId Which NFT we want to add.
     */
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "!to");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
    }

    /**
     * @dev Removes a NFT from an address.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _from Address from wich we want to remove the NFT.
     * @param _tokenId Which NFT we want to remove.
     */
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        //ownerToIds[_from].pop();
        ownerToIds[_from].length--; 
    }

    /**
     * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
     * extension to remove double storage (gas optimization) of owner nft count.
     * @param _owner Address for whom to query the count.
     * @return Number of _owner NFTs.
     */
    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    /**
     * @dev Actually perform the safeTransferFrom.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    /**
     * @dev Clears the current approval of a given NFT ID.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //// Enumerable

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < numTokens);
        return index;
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    //// Metadata

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return _name Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return draw(_tokenId);
    }

}