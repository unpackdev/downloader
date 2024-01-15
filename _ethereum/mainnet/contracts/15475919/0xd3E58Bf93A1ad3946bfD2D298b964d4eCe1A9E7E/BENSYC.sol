//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";
import "./Util.sol";
import "./Base.sol";

/**
 * @author 0xc0de4c0ffee, sshmatrix
 * @title BENSYC Core
 */

contract BoredENSYachtClub is BENSYC {
    using Util for uint256;
    using Util for bytes;

    /// @dev : maximum supply of subdomains
    uint256 public immutable maxSupply;

    /// @dev : namehash of 'boredensyachtclub.eth'
    bytes32 public immutable DomainHash;

    /// @dev : start time of mint
    uint256 public immutable startTime;

    /**
     * @dev Constructor
     * @param _resolver : default Resolver
     * @param _maxSupply : maximum supply of subdomains
     * @param _startTime : start time of mint
     */
    constructor(address _resolver, uint256 _maxSupply, uint256 _startTime) {
        Dev = msg.sender;
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        DefaultResolver = _resolver;
        DomainHash = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("boredensyachtclub"))
        );
        maxSupply = _maxSupply;
        startTime = _startTime;
        // Interface
        supportsInterface[type(iERC165).interfaceId] = true;
        supportsInterface[type(iERC173).interfaceId] = true;
        supportsInterface[type(iERC721Metadata).interfaceId] = true;
        supportsInterface[type(iERC721).interfaceId] = true;
        supportsInterface[type(iERC2981).interfaceId] = true;
    }

    /**
     * @dev EIP721: returns owner of token ID
     * @param id : token ID
     * @return : address of owner
     */
    function ownerOf(uint256 id) public view isValidToken(id) returns (address) {
        return _ownerOf[id];
    }

    /**
     * @dev returns namehash of token ID
     * @param id : token ID
     * @return : namehash of corresponding subdomain
     */
    function ID2Namehash(uint256 id) public view isValidToken(id) returns (bytes32) {
        return keccak256(abi.encodePacked(DomainHash, ID2Labelhash[id]));
    }

    /**
     * @dev mint() function for single sudomain
     */
    function mint() external payable {
        if (!active) {
            revert MintingPaused();
        }

        if (block.timestamp < startTime) {
            revert TooSoonToMint();
        }

        if (totalSupply >= maxSupply) {
            revert MintEnded();
        }

        if (msg.value < mintPrice) {
            revert InsufficientEtherSent(mintPrice, msg.value);
        }

        uint256 _id = totalSupply;
        bytes32 _labelhash = keccak256(abi.encodePacked(_id.toString()));
        ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, DefaultResolver, 0);
        ID2Labelhash[_id] = _labelhash;
        Namehash2ID[keccak256(abi.encodePacked(DomainHash, _labelhash))] = _id;
        unchecked {
            ++totalSupply;
            ++balanceOf[msg.sender];
        }
        _ownerOf[_id] = msg.sender;
        emit Transfer(address(0), msg.sender, _id);
    }

    /**
     * @dev : batchMint() function for sudomains
     * @param batchSize : number of subdomains to mint in the batch (maximum batchSize = 12)
     */
    function batchMint(uint256 batchSize) external payable {
        if (!active) {
            revert MintingPaused();
        }

        if (block.timestamp < startTime) {
            revert TooSoonToMint();
        }

        if (batchSize > 12 || totalSupply + batchSize > maxSupply) {
            // maximum batchSize = floor of [12, maxSupply - totalSupply]
            revert OversizedBatch();
        }

        if (msg.value < mintPrice * batchSize) {
            revert InsufficientEtherSent(mintPrice * batchSize, msg.value);
        }

        uint256 _id = totalSupply;
        uint256 _mint = _id + batchSize;
        bytes32 _labelhash;
        while (_id < _mint) {
            _labelhash = keccak256(abi.encodePacked(_id.toString()));
            ENS.setSubnodeRecord(DomainHash, _labelhash, msg.sender, DefaultResolver, 0);
            ID2Labelhash[_id] = _labelhash;
            Namehash2ID[keccak256(abi.encodePacked(DomainHash, _labelhash))] = _id;
            _ownerOf[_id] = msg.sender;
            emit Transfer(address(0), msg.sender, _id);
            unchecked {
                ++_id;
            }
        }
        unchecked {
            totalSupply = _mint;
            balanceOf[msg.sender] += batchSize;
        }
    }

    /**
     * @dev : generic _transfer function
     * @param from : address of sender
     * @param to : address of receiver
     * @param id : subdomain token ID
     */
    function _transfer(address from, address to, uint256 id, bytes memory data) internal {
        if (to == address(0)) {
            revert ZeroAddress();
        }

        if (_ownerOf[id] != from) {
            revert NotSubdomainOwner(_ownerOf[id], from, id);
        }

        if (msg.sender != _ownerOf[id] && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id]) {
            revert Unauthorized(msg.sender, from, id);
        }

        ENS.setSubnodeOwner(DomainHash, ID2Labelhash[id], to);
        unchecked {
            --balanceOf[from]; // subtract from owner
            ++(balanceOf[to]); // add to receiver
        }
        _ownerOf[id] = to; // change ownership
        delete getApproved[id]; // reset approved
        emit Transfer(from, to, id);
        if (to.code.length > 0) {
            try iERC721Receiver(to).onERC721Received(msg.sender, from, id, data) returns (bytes4 retval) {
                if (retval != iERC721Receiver.onERC721Received.selector) {
                    revert ERC721IncompatibleReceiver(to);
                }
            } catch {
                revert ERC721IncompatibleReceiver(to);
            }
        }
    }

    /**
     * @dev : transfer function
     * @param from : from address
     * @param to : to address
     * @param id : token ID
     */
    function transferFrom(address from, address to, uint256 id) external payable {
        _transfer(from, to, id, "");
    }

    /**
     * @dev : safeTransferFrom function with extra data
     * @param from : from address
     * @param to : to address
     * @param id : token ID
     * @param data : extra data
     */
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external payable {
        _transfer(from, to, id, data);
    }

    /**
     * @dev : safeTransferFrom function
     * @param from : from address
     * @param to : to address
     * @param id : token ID
     */
    function safeTransferFrom(address from, address to, uint256 id) external payable {
        _transfer(from, to, id, "");
    }

    /**
     * @dev : grants approval for a token ID
     * @param approved : operator address to be approved
     * @param id : token ID
     */
    function approve(address approved, uint256 id) external payable {
        if (msg.sender != _ownerOf[id]) {
            revert Unauthorized(msg.sender, _ownerOf[id], id);
        }

        getApproved[id] = approved;
        emit Approval(msg.sender, approved, id);
    }

    /**
     * @dev : sets Controller (for all tokens)
     * @param operator : operator address to be set as Controller
     * @param approved : bool to set
     */
    function setApprovalForAll(address operator, bool approved) external payable {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev : generate metadata path corresponding to token ID
     * @param id : token ID
     * @return : IPFS path to metadata directory
     */
    function tokenURI(uint256 id) external view isValidToken(id) returns (string memory) {
        return string.concat("ipfs://", metaIPFS, "/", id.toString(), ".json");
    }

    /**
     * @dev : royalty payment to Dev (or multi-sig)
     * @param id : token ID
     * @param _salePrice : sale price
     * @return : ether amount to be paid as royalty to Dev (or multi-sig)
     */
    function royaltyInfo(uint256 id, uint256 _salePrice) external view returns (address, uint256) {
        id; //silence warning
        return (Dev, _salePrice / 100 * royalty);
    }

    // Contract Management

    /**
     * @dev : transfer contract ownership to new Dev
     * @param newDev : new Dev
     */
    function transferOwnership(address newDev) external onlyDev {
        emit OwnershipTransferred(Dev, newDev);
        Dev = newDev;
    }

    /**
     * @dev : get owner of contract
     * @return : address of controlling dev or multi-sig wallet
     */
    function owner() external view returns (address) {
        return Dev;
    }

    /**
     * @dev : Toggle if contract is active or paused, only Dev can toggle
     */
    function toggleActive() external onlyDev {
        active = !active;
    }

    /**
     * @dev : sets Default Resolver
     * @param _resolver : resolver address
     */
    function setDefaultResolver(address _resolver) external onlyDev {
        DefaultResolver = _resolver;
    }

    /**
     * @dev : sets OpenSea contractURI
     * @param _contractURI : URI value
     */
    function setContractURI(string calldata _contractURI) external onlyDev {
        contractURI = _contractURI;
    }

    //
    /**
     * @dev EIP2981 royalty standard
     * @param _royalty : royalty (1 = 1 %)
     */
    function setRoyalty(uint256 _royalty) external onlyDev {
        royalty = _royalty;
    }
}
