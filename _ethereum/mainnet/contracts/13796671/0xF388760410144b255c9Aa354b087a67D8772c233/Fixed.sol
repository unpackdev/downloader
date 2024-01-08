// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * OoOoOoOoOoOoOoOoOoOoOoOoOoOaOoOoOoOoOoOoOoOoOoOoOoOoOoOaOoOoOoOoOoOoOoOoOoOoOoOoo
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
 * OOOOOOOOOOOOOOOOOOOOOOOOO0000000 my name is non OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
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
 * oOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOooOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOooOoOoOo
 */

import "./SafeMath.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./FixedMetadata.sol";

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

interface IMerge {
    function getValueOf(uint256 tokenId) external view returns (uint256);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Fixed is ERC721, ERC721Metadata {
    using SafeMath for uint256;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IFixedMetadata public _metadataGenerator;
    IMerge public _Merge;

    string private _name;
    string private _symbol;

    bytes32 public _merkleRoot;

    bool public _mintingFinalized;

    uint256 public _countMint;
    uint256 public _countToken;

    uint256 immutable public _percentageTotal;
    uint256 public _percentageRoyalty;

    uint256 public _alphaMass;
    uint256 public _alphaId;

    uint256 public _massTotal;

    address public _non;
    address public _dead;
    address public _receiver;

    address proxyRegistryAddress;

    mapping (address => bool) _defaultApprovals;

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

    mapping (address => bool) private _mints;


    function getMergeCount(uint256 tokenId) public view returns (uint256 mergeCount) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return _mergeCount[tokenId];
    }

    modifier onlyNon() {
        require(_msgSender() == _non, "Fixed: msg.sender is not non");
        _;
    }

    /**
     * @dev Set the values carefully!
     *
     * Requirements:
     *
     * - `merge_` merge. (0x27d270B7d58D15D455c85c02286413075f3C8a31)
     * - `metadataGenerator_` (/0xCFF0eDafFe7cAE0D7F2007baf1D7Cc254f38B597)
     * - `non_` - Initial non address (0x4b9cFa53329Fe768a344233a5A1cB821eFc82597)
     * - `proxyRegistryAddress_` - OpenSea proxy registry (0xa5409ec958c83c3f309868babaca7c86dcb077c1/0xf57b2c51ded3a29e6891aba85459d600256cf317)
     * - `transferProxyAddress_` - Rarible transfer proxy (0x4fee7b061c97c9c496b01dbce9cdb10c02f0a0be/0x7d47126a2600E22eab9eD6CF0e515678727779A6)
     * - `merkleRoot_` - Merkle root (0x28bc4b70fafd51f87a3a4ebafe122e5a33fad7152087f2010119805a89c36138)
     */

    constructor(address merge_, address metadataGenerator_, address non_, address proxyRegistryAddress_, address transferProxyAddress_, bytes32 merkleRoot_) {
        _tokenIdCounter.increment();
        _metadataGenerator = IFixedMetadata(metadataGenerator_);
        _Merge = IMerge(merge_);

        _name = "fixed.";
        _symbol = "f";

        _non = non_;
        _receiver = non_;

        _dead = 0x000000000000000000000000000000000000dEaD;


        _percentageTotal = 10000;
        _percentageRoyalty = 1000;


        _blacklistAddress[address(this)] = true;

        proxyRegistryAddress = proxyRegistryAddress_;

        _defaultApprovals[transferProxyAddress_] = true;

        _merkleRoot = merkleRoot_;
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

    function setMerkleRoot(bytes32 merkleRoot_) onlyNon public {
        _merkleRoot = merkleRoot_;
    }

    function merge(uint256 tokenIdRcvr, uint256 tokenIdSndr) external returns (uint256 tokenIdDead) {
        address ownerOfTokenIdRcvr = ownerOf(tokenIdRcvr);
        address ownerOfTokenIdSndr = ownerOf(tokenIdSndr);
        require(ownerOfTokenIdRcvr == ownerOfTokenIdSndr, "Fixed: Illegal argument disparate owner.");
        require(_msgSender() == ownerOfTokenIdRcvr, "ERC721: msg.sender is not token owner.");
        return _merge(tokenIdRcvr, tokenIdSndr, ownerOfTokenIdRcvr, ownerOfTokenIdSndr);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721: transfer attempt for nonexistent token");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_blacklistAddress[to], "Fixed: transfer attempt to blacklist address");
        require(from != to, "ERC721: transfer attempt to self");

        if(to == _dead){
            _burn(tokenId);
            return;
        }

        _approve(address(0), tokenId);

        if(_tokens[to] == 0){
            _tokens[to] = tokenId;
            delete _tokens[from];

            _owners[tokenId] = to;

            _balances[to] = 1;
            _balances[from] = 0;

            emit Transfer(from, to, tokenId);
            return;
        }

        uint256 tokenIdRcvr = _tokens[to];
        uint256 tokenIdSndr = tokenId;
        uint256 tokenIdDead = _merge(tokenIdRcvr, tokenIdSndr, to, from);

        delete _owners[tokenIdDead];
    }

    function _merge(uint256 tokenIdRcvr, uint256 tokenIdSndr, address ownerRcvr, address ownerSndr) internal returns (uint256 tokenIdDead) {
        require(tokenIdRcvr != tokenIdSndr, "Fixed: Illegal argument identical tokenId.");

        uint256 massRcvr = decodeMass(_values[tokenIdRcvr]);
        uint256 massSndr = decodeMass(_values[tokenIdSndr]);

        _balances[ownerRcvr] = 1;
        _balances[ownerSndr] = 0;

        emit Transfer(_owners[tokenIdSndr], address(0), tokenIdSndr);

        _values[tokenIdRcvr] += massSndr;

        uint256 combinedMass = massRcvr + massSndr;

        if(combinedMass > _alphaMass) {
            _alphaId = tokenIdRcvr;
            _alphaMass = combinedMass;
            emit AlphaMassUpdate(_alphaId, combinedMass);
        }

        _mergeCount[tokenIdRcvr]++;

        delete _values[tokenIdSndr];

        delete _tokens[ownerSndr];

        _countToken -= 1;

        emit MassUpdate(tokenIdSndr, tokenIdRcvr, combinedMass);

        return tokenIdSndr;
    }

    function setRoyaltyBips(uint256 percentageRoyalty_) external onlyNon {
        require(percentageRoyalty_ <= _percentageTotal, "Fixed: Illegal argument more than 100%");
        _percentageRoyalty = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * _percentageRoyalty) / _percentageTotal;
        return (_receiver, royaltyAmount);
    }

    function setBlacklistAddress(address address_, bool status) external onlyNon {
        _blacklistAddress[address_] = status;
    }

    function setNon(address non_) external onlyNon {
        _non = non_;
    }

    function setRoyaltyReceiver(address receiver_) external onlyNon {
        _receiver = receiver_;
    }

    function setMetadataGenerator(address metadataGenerator_) external onlyNon {
        _metadataGenerator = IFixedMetadata(metadataGenerator_);
    }

    function whitelistUpdate(address address_, bool status) external onlyNon {
        if(status == false) {
            require(balanceOf(address_) <= 1, "Fixed: Address with more than one token can't be removed.");
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
     * Emits a series of {Transfer} events.
     */
    function mint(uint256 mass_, string memory nonce_, bytes32[] calldata proof_) external {
        require(!_mintingFinalized, "Fixed: Minting is finalized.");

        require(_mints[msg.sender] == false);
        _mints[msg.sender] = true;

        string memory key_ = string(abi.encodePacked(mass_.toString(), ":", nonce_));
        require(_verify(_leaf(msg.sender, key_), proof_), "Invalid merkle proof");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        uint256 alphaId = _alphaId;
        uint256 alphaMass = _alphaMass;

        uint256 value = _Merge.getValueOf(tokenId);

        if (value == 0) {
            value = 100000001;
        }

        (uint256 class, uint256 m) = decodeClassAndMass(value);
        value = mass_ + (class * 100000000);

        _values[tokenId] = value;
        _owners[tokenId] = msg.sender;

        _tokens[msg.sender] = tokenId;

        require(class > 0 && class <= 4, "Fixed: Class must be between 1 and 4.");
        require(mass_ > 0 && mass_ < 99999999, "Fixed: Mass must be between 1 and 99999999.");

        if(alphaMass < mass_){
            alphaMass = mass_;
            alphaId = tokenId;
        }

        emit Transfer(address(0), msg.sender, tokenId);

        _countMint += 1;
        _countToken += 1;

        _balances[msg.sender] = 1;

        _massTotal += mass_;

        if(_alphaId != alphaId) {
            _alphaId = alphaId;
            _alphaMass = alphaMass;
            emit AlphaMassUpdate(alphaId, alphaMass);
        }
    }

    function finalize() external onlyNon {
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
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return _defaultApprovals[operator] || _operatorApprovals[owner][operator];
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
        require(class > 0 && class <= 4, "Fixed: Class must be between 1 and 4.");
        require(mass > 0 && mass < 99999999, "Fixed: Mass must be between 1 and 99999999.");
        return ((class * 100000000) + mass);
    }

    function decodeClassAndMass(uint256 value) public pure returns (uint256, uint256) {
        uint256 class = value.div(100000000);
        uint256 mass = value.sub(class.mul(100000000));
        require(class > 0 && class <= 4, "Fixed: Class must be between 1 and 4.");
        require(mass > 0 && mass < 99999999, "Fixed: Mass must be between 1 and 99999999.");
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

    function _leaf(address account, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }
}