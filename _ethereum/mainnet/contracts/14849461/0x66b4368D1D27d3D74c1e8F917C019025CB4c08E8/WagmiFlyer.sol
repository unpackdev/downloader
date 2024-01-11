// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base58.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC2981.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract Target721 { 
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address owner) public view virtual returns (uint256);
    function getApproved(uint256 tokenId) public view virtual returns (address);
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool);
}

struct TargetContract {
    Target721 target;
    uint256 start;
    uint256 end;
    bytes32 ipfs;
}

contract WagmiFlyer is Context, ERC165, IERC721, IERC721Metadata, Ownable, ERC2981 {
    event Conversion(address indexed from, uint256 indexed tokenId);
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    string internal _baseTokenURI;
    string internal _contractURI;

    uint256 internal _totalSupply;
    uint256 internal MAX_TOKEN_ID; 
	
	bool internal burnAirdrop = false;

    TargetContract[] _targetList;
    address mainContractAddress;

    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => bool) private cancelAirdropMap;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        mint(address(0), msg.sender, 0);
        _setDefaultRoyalty(_msgSender(), 1000);
    }

    /** ERC721 Information */

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        for(uint idx = 0; idx < _targetList.length; idx++) {
            if(tokenId <= _targetList[idx].end && tokenId >= _targetList[idx].start) {
                if(_targetList[idx].ipfs > 0) {
                    return string(abi.encodePacked("ipfs://", Base58.toBase58(abi.encodePacked(hex"1220", _targetList[idx].ipfs))));
                }
            }
        }
        
        return _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) external view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint256 balance = 0;
        for(uint256 i = 0; i <= MAX_TOKEN_ID; i++) {
           if(_ownerOf(i) == owner) { balance++; }
        }
        return balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = _owners[tokenId];
        if(owner == address(0) && !burnAirdrop && !cancelAirdropMap[tokenId]) {
            unchecked {
                for(uint idx = 0; idx < _targetList.length; idx++) {
                    if(tokenId <= _targetList[idx].end) {
                        uint256 newVal = tokenId + 1 - _targetList[idx].start;
                        try _targetList[idx].target.ownerOf(newVal) returns (address result) { owner = result; } catch { owner = address(0); }
                        return owner;
                    }
                }
            }
        }
        return owner;
    }

    function setMax(uint256 _max) public onlyOwner {
        MAX_TOKEN_ID = _max;
    }
    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /** ERC721 APPROVE */

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if(_operatorApprovals[owner][operator]) {
            return true;
        }
        // Whitelist OpenSea proxy contract for easy trading.
        address proxy = proxyFor(owner);
        return proxy != address(0) && proxy == operator;
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    
    /** ERC721 transfer */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address[] calldata to,
        uint256[] calldata tokenId
    ) public onlyOwner {
        require(to.length == tokenId.length, "list length mismatch");
        unchecked {
            for (uint256 index = 0; index < to.length; index++) {
                emit Transfer(from, to[index], tokenId[index]);
            }
            _totalSupply += to.length;
        }
    }

    function batchMint(
        address[] calldata to,
        uint256[] calldata tokenId
    ) public onlyOwner {
        require(to.length == tokenId.length, "list length mismatch");
        unchecked {
            for (uint256 index = 0; index < to.length; index++) {
                emit Transfer(address(0), to[index], tokenId[index]);
            }
            _totalSupply += to.length;
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
       
        unchecked { 
           _owners[tokenId] = to;
        }

        emit Transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal virtual {
        // @note if transferred, flyer should not belong to airdrop target.
        if(!cancelAirdropMap[tokenId]) { cancelAirdropMap[tokenId] = true; }
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transfer(address to, uint256 tokenId) internal virtual {
        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @notice If owner do not want flyer, can cancel airdrop.
     */
    function cancelAirdrop(uint256 tokenId) external {
        address raw = ownerOf(tokenId);
        require(!cancelAirdropMap[tokenId], "airdrop has been canceled");
        require(raw == _msgSender() || owner() == _msgSender(), "Must own token.");
        unchecked { 
            cancelAirdropMap[tokenId] = true; 
           _owners[tokenId] = owner();
           emit Transfer(raw, owner(), tokenId);
        }
    }

    /**
     * @dev owner can convert flyer to main contract's NFT
     */
    function flyerConversion(address owner, uint256 tokenId) external {
        require(_msgSender() == mainContractAddress, "Only main contract can do this.");
        require(owner == ownerOf(tokenId), "Target must own token.");
        _burn(tokenId);
        emit Conversion(owner, tokenId);
    }
    
    function burn(uint256 tokenId) external { 
        address raw = ownerOf(tokenId);
        require(raw == _msgSender() || owner() == _msgSender(), "Must own token to burn.");
        _burn(tokenId);
    }

    function setURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }

    function setBurnAirdrop(bool setBurn) external onlyOwner {
        burnAirdrop = setBurn;
    }

    function _burn(uint256 tokenId) internal virtual {
        address own = _owners[tokenId];
        _beforeTokenTransfer(own, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        unchecked { 
           _totalSupply -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(own, address(0), tokenId);
    }

    function setTargetContract(address[] calldata adr, uint256[] calldata start, uint256[] calldata end, bytes32[] calldata b) external onlyOwner {
        delete _targetList; 
        for(uint256 i = 0;i < adr.length;i++) {
            _targetList.push(TargetContract(
                Target721(adr[i]), start[i], end[i], b[i]
            ));
        }
    }

    /**
    @notice Returns the OpenSea proxy address for the owner.
     */
    function proxyFor(address owner) internal view returns (address) {
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            // Production networks are placed higher to minimise the number of
            // checks performed and therefore reduce gas. By the same rationale,
            // mainnet comes before Polygon as it's more expensive.
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                // The geth SimulatedBackend iff used with the ethier
                // openseatest package. This is mocked as a Wyvern proxy as it's
                // more complex than the 0x ones.
                registry := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        // Unlike Wyvern, the registry itself is the proxy for all owners on 0x
        // chains.
        if (registry == address(0) || chainId == 137 || chainId == 80001) {
            return registry;
        }

        return address(ProxyRegistry(registry).proxies(owner));
    }
    
    function mint(address from, address adr, uint256 id) public onlyOwner payable {
        cancelAirdropMap[id] = true;
        _owners[id] = adr;
        emit Transfer(from, adr, id);
        _totalSupply += 1;
    }

    function setMainContract(address _adr) public onlyOwner {
        mainContractAddress = _adr;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(_msgSender()).call{ value: address(this).balance }("");
        require(success, "failed");
    }
}
