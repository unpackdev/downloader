// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/** 
 * smatthewenglish oOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOo niftynathan
 * OoOoOoOoOoOoOoOoOoOoOoOoOoO                          OoOoOoOoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoO                                      OoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOo                                             OoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOo                                                    oOoOoOoOoOoOoOo
 * OoOoOoOoOoOo                                                         OoOoOoOoOoOo
 * OoOoOoOoOo                                                             OoOoOoOoOo
 * OoOoOoOo                                                                 OoOoOoOo
 * OoOoOo                                                                     OoOoOo
 * OoOoO                                                                       oOoOo
 * OoOo                                                                         OoOo
 * OoO                                                                           oOo
 * Oo                                                                             oO
 * Oo                                                                             oO
 * O                                                                               O
 * O                                                                               O
 * O                                                                               O
 * O                                                                               O
 * O                                                                               O
 * Oo                                                                             oO
 * Oo                                                                             oO
 * OoO                                                                           oOo
 * OoOo                                                                         OoOo
 * OoOoO                                                                       oOoOo
 * OoOoOo                                                                     OoOoOo
 * OoOoOoOo                                                                 OoOoOoOo
 * OoOoOoOoOo                                                             OoOoOoOoOo
 * OoOoOoOoOoOo                                                         OoOoOoOoOoOo
 * OoOoOoOoOoOoOo                                                    oOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOo                                             OoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoO                                      OoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoOoOoOoO                          OoOoOoOoOoOoOoOoOoOoOoOoOoOo
 * soliditygoldminerz oOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOo reviewed by manifold.xyz
 */

import "./SafeMath.sol";
import "./MergeMetadata.sol";

interface INiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Merge is ERC721, ERC721Metadata {

    using SafeMath for uint256;
 

    IMergeMetadata public _metadataGenerator;

    
    string private _name;

    string private _symbol;


    bool public _mintingFinalized;

 
    uint256 public _countMint;
 
    uint256 public _countToken;

    uint256 immutable public _percentageTotal;
    uint256 public _percentageRoyalty;


    uint256 public _alphaMass;

    uint256 public _alphaId;


    uint256 public _massTotal;


    address public _pak;

    address public _dead;

    address public _omnibus;

    address public _receiver;

    address immutable public _registry;


    event AlphaMassUpdate(uint256 indexed tokenId, uint256 alphaMass);


    event MassUpdate(uint256 indexed tokenIdBurned, uint256 indexed tokenIdPersist, uint256 mass);


    // Mapping of addresses disbarred from holding any token.
    mapping (address => bool) private _blacklistAddress;

    // Mapping of address allowed to hold multiple tokens.
    mapping (address => bool) private _whitelistAddress;

    // Mapping from owner address to token ID.
    mapping (address => uint256) private _tokens;

    // Mapping owner address to token count.
    mapping (address => uint256) private _balances;


    // Mapping from token ID to owner address.
    mapping (uint256 => address) private _owners;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    

    // Mapping token ID to mass value.
    mapping (uint256 => uint256) private _values;

    // Mapping token ID to all quantity merged into it.
    mapping (uint256 => uint256) private _mergeCount;


    function getMergeCount(uint256 tokenId) public view returns (uint256 mergeCount) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return _mergeCount[tokenId];
    }

    modifier onlyPak() {
        require(_msgSender() == _pak, "Merge: msg.sender is not pak");
        _;
    }

    modifier onlyValidWhitelist() {
        require(_whitelistAddress[_msgSender()], "Merge: Invalid msg.sender");
        _;
    }

    modifier onlyValidSender() {
        require(INiftyRegistry(_registry).isValidNiftySender(_msgSender()), "Merge: Invalid msg.sender");
        _;
    }

    /**
     * @dev Set the values carefully!
     *
     * Requirements:
     *
     * - `registry_` enforce access control on state-changing ops
     * - `omnibus_` for efficient minting of initial token stock
     * - `metadataGenerator_` 
     * - `pak_` - Initial pak address (0x2Ce780D7c743A57791B835a9d6F998B15BBbA5a4)
     *
     */
    
    constructor(address registry_, address omnibus_, address metadataGenerator_, address pak_) {
        _registry = registry_;
        _omnibus = omnibus_;
        _metadataGenerator = IMergeMetadata(metadataGenerator_);
        _name = "merge.";
        _symbol = "m";

        _pak = pak_;
        _receiver = pak_;

        _dead = 0x000000000000000000000000000000000000dEaD;


        _percentageTotal = 10000;
        _percentageRoyalty = 1000;


        _blacklistAddress[address(this)] = true;

        _whitelistAddress[omnibus_] = true;              
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    } 

    function totalSupply() public view returns (uint256) {
        return _countToken;
    }
 
    function merge(uint256 tokenIdRcvr, uint256 tokenIdSndr) external onlyValidWhitelist returns (uint256 tokenIdDead) {        
        address ownerOfTokenIdRcvr = ownerOf(tokenIdRcvr);
        address ownerOfTokenIdSndr = ownerOf(tokenIdSndr);
        require(ownerOfTokenIdRcvr == ownerOfTokenIdSndr, "Merge: Illegal argument disparate owner.");
        require(_msgSender() == ownerOfTokenIdRcvr, "ERC721: msg.sender is not token owner.");
        return _merge(tokenIdRcvr, tokenIdSndr, ownerOfTokenIdRcvr, ownerOfTokenIdSndr); 
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721: transfer attempt for nonexistent token");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_blacklistAddress[to], "Merge: transfer attempt to blacklist address");
        require(from != to, "ERC721: transfer attempt to self");

        if(to == _dead){
            _burn(tokenId);
            return;
        }

        _approve(address(0), tokenId);

        bool fromIsWhitelisted = isWhitelisted(from);
        bool toIsWhitelisted = isWhitelisted(to);

        if(!fromIsWhitelisted && toIsWhitelisted){            
            delete _tokens[from];            
            _owners[tokenId] = to;

            _balances[to] += 1;
            delete _balances[from];            

            emit Transfer(from, to, tokenId);
            return;
        }

        if(fromIsWhitelisted && toIsWhitelisted) {

            _balances[to] += 1;
            _balances[from] -= 1;
            
            _owners[tokenId] = to;

            emit Transfer(from, to, tokenId);
            return;
        }

        if(_tokens[to] == 0){            

            _tokens[to] = tokenId;
            _owners[tokenId] = to;

            _balances[to] += 1;
            _balances[from] -= 1;

            emit Transfer(from, to, tokenId);
            return;
        }        

        emit Transfer(from, to, tokenId);

        uint256 tokenIdRcvr = _tokens[to];
        uint256 tokenIdSndr = tokenId;
        uint256 tokenIdDead = _merge(tokenIdRcvr, tokenIdSndr, to, from);

        if(tokenIdDead == tokenIdRcvr){
            _owners[tokenIdSndr] = to;
            _tokens[to] = tokenIdSndr;
        } else {
            _owners[tokenIdRcvr] = to;
            _tokens[to] = tokenIdRcvr;
        }
        delete _owners[tokenIdDead];
    }

    function _merge(uint256 tokenIdRcvr, uint256 tokenIdSndr, address ownerRcvr, address ownerSndr) internal returns (uint256 tokenIdDead) {
        require(tokenIdRcvr != tokenIdSndr, "Merge: Illegal argument identical tokenId.");

        uint256 massRcvr = decodeMass(_values[tokenIdRcvr]);
        uint256 massSndr = decodeMass(_values[tokenIdSndr]);

        if(!_whitelistAddress[ownerRcvr]){
            _balances[ownerRcvr] = 1;
        }
        _balances[ownerSndr] -= 1;
        
        uint256 massSmall = massRcvr;
        uint256 massLarge = massSndr;

        uint256 tokenIdSmall = tokenIdRcvr;
        uint256 tokenIdLarge = tokenIdSndr;

        if (massRcvr >= massSndr) {

            massSmall = massSndr;
            massLarge = massRcvr;

            tokenIdSmall = tokenIdSndr;
            tokenIdLarge = tokenIdRcvr;
        }

        emit Transfer(ownerOf(tokenIdSmall), address(0), tokenIdSmall);

        _values[tokenIdLarge] += massSmall;

        uint256 combinedMass = massLarge + massSmall;

        if(combinedMass > _alphaMass) {
            _alphaId = tokenIdLarge;
            _alphaMass = combinedMass;
            emit AlphaMassUpdate(_alphaId, combinedMass);
        }
        
        _mergeCount[tokenIdLarge]++;

        delete _values[tokenIdSmall];

        _countToken -= 1;

        emit MassUpdate(tokenIdSmall, tokenIdLarge, combinedMass);

        return tokenIdSmall;
    }

    function setRoyaltyBips(uint256 percentageRoyalty_) external onlyPak {
        require(percentageRoyalty_ <= _percentageTotal, "Merge: Illegal argument more than 100%");
        _percentageRoyalty = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * _percentageRoyalty) / _percentageTotal;
        return (_receiver, royaltyAmount);
    }

    function setBlacklistAddress(address address_, bool status) external onlyPak {
        require(address_ != _omnibus, "Merge: Illegal argument address_ is _omnibus.");
        _blacklistAddress[address_] = status;
    }

    function setPak(address pak_) external onlyPak {  
        _pak = pak_;
    }

    function setRoyaltyReceiver(address receiver_) external onlyPak {  
        _receiver = receiver_;
    }
    
    function setMetadataGenerator(address metadataGenerator_) external onlyPak {  
        _metadataGenerator = IMergeMetadata(metadataGenerator_);
    }
   
    function whitelistUpdate(address address_, bool status) external onlyPak {
        if(address_ == _omnibus){
            require(status != false, "Merge: Illegal argument _omnibus can't be removed.");
        }

        if(status == false) {
            require(balanceOf(address_) <= 1, "Merge: Address with more than one token can't be removed.");
        }

        _whitelistAddress[address_] = status;
    }

    function isWhitelisted(address address_) public view returns (bool) {
        return _whitelistAddress[address_];
    }

    function isBlacklisted(address address_) public view returns (bool) {
        return _blacklistAddress[address_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");        
        return _owners[tokenId];
    }

    /**
     * @dev Generate the NFTs of this collection. 
     *
     * [20001000, 20000900, ]
     *
     * Requirements:
     *
     * - `values_` provided as a list of addresses, each of
     *             which implicitly corresponds to a tokenId, 
     *             derrived by the index of the value in the 
     *             input array. The values map to a color
     *             attribute.
     *
     * Emits a series of {Transfer} events.
     */
    function mint(uint256[] memory values_) external onlyValidSender {
        require(!_mintingFinalized, "Merge: Minting is finalized.");

        uint256 index = _countMint;
        uint256 massAdded = 0;

        uint256 alphaId = _alphaId;
        uint256 alphaMass = _alphaMass;

        for (uint256 i = 1; i <= values_.length; i++) {

            index = _countMint + i;

            _values[index] = values_[i - 1];

            _owners[index] = _omnibus;

            (uint256 class, uint256 mass) = decodeClassAndMass(values_[i - 1]);
            require(class > 0 && class <= 4, "Merge: Class must be between 1 and 4.");
            require(mass > 0 && mass < 99999999, "Merge: Mass must be between 1 and 99999999.");          

            if(alphaMass < mass){
                alphaMass = mass;
                alphaId = index;
            }

            massAdded += mass;

            emit Transfer(address(0), _omnibus, index);
        }

        _countMint += values_.length;
        _countToken += values_.length;

        _balances[_omnibus] = _countMint;

        _massTotal += massAdded;

        if(_alphaId != alphaId) {
            _alphaId = alphaId;
            _alphaMass = alphaMass;
            emit AlphaMassUpdate(alphaId, alphaMass);
        }        
    }

    function finalize() external onlyPak {
        _mintingFinalized = true;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];        
    }

    function massOf(uint256 tokenId) public view virtual returns (uint256) {
        return decodeMass(_values[tokenId]);
    }

    function getValueOf(uint256 tokenId) public view virtual returns (uint256) {
        return _values[tokenId];
    }

    function tokenOf(address owner) public view virtual returns (uint256) {
        uint256 token = _tokens[owner];
        return token;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");       
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _values[tokenId] != 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");

        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }   

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        
        return _metadataGenerator.tokenMetadata(
            tokenId, 
            decodeClass(_values[tokenId]), 
            decodeMass(_values[tokenId]), 
            decodeMass(_values[_alphaId]), 
            tokenId == _alphaId,
            getMergeCount(tokenId));
    }

    function encodeClassAndMass(uint256 class, uint256 mass) public pure returns (uint256) {        
        require(class > 0 && class <= 4, "Merge: Class must be between 1 and 4.");
        require(mass > 0 && mass < 99999999, "Merge: Mass must be between 1 and 99999999.");            
        return ((class * 100000000) + mass);
    }

    function decodeClassAndMass(uint256 value) public pure returns (uint256, uint256) {
        uint256 class = value.div(100000000);        
        uint256 mass = value.sub(class.mul(100000000));
        require(class > 0 && class <= 4, "Merge: Class must be between 1 and 4.");
        require(mass > 0 && mass < 99999999, "Merge: Mass must be between 1 and 99999999.");             
        return (class, mass);
    }

    function decodeClass(uint256 value) public pure returns (uint256) {
        return value.div(100000000);
    }    

    function decodeMass(uint256 value) public pure returns (uint256) {
        return value.sub(decodeClass(value).mul(100000000));
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }    

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }


    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId);

        _massTotal -= decodeMass(_values[tokenId]);

        delete _tokens[owner];
        delete _owners[tokenId];
        delete _values[tokenId];

        _countToken -= 1;
        _balances[owner] -= 1;        

        emit MassUpdate(tokenId, 0, 0);

        emit Transfer(owner, address(0), tokenId);
    }
}