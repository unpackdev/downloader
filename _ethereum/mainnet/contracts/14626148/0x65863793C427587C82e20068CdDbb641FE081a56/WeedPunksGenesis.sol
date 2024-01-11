// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

import "./MerkleProof.sol";


contract WeedPunksGenesis is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    string public baseUri = "";
    uint256 public supply = 420;
    string public extension = ".json";  

    bool public greenlistLive;
    address payable public payoutAddress;
    bytes32 public greenlistMerkleRoot;

    struct Config {

        uint256 mintPrice;
        uint256 glPrice;
        uint256 maxMint;
     
        uint256 maxgreenlist;
       
        uint256 maxgreenlistPerTx;
        uint256 maxMintPerTx;
    }



    Config public config;
    
    mapping(address => uint256) mintedInWallet;
    mapping(address => bool) admins;

    event GreenlistLive(bool live);
   

    constructor() ERC721A("WeedPunksGenesis", "WPG") { 
        _pause(); 
        config.mintPrice = 0.042 ether;
        config.glPrice = 0.042 ether;
        config.maxMint = 10;
        config.maxgreenlist = 3;
  
        config.maxgreenlistPerTx = 3;
        config.maxMintPerTx = 3;
    }

        /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }


    function greenlistMint(uint256 count, bytes32[] calldata proof) external payable isValidMerkleProof(proof, greenlistMerkleRoot) nonReentrant notBots {
        require(greenlistLive, "Not live");
        require(count <= config.maxgreenlistPerTx, "Exceeds max");
        require(mintedInWallet[msg.sender] + count <= config.maxgreenlist, "Exceeds max");
        require(msg.value >= config.glPrice * count, "more eth required");
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);        
    }

    function mint(uint256 count) external payable nonReentrant whenNotPaused notBots {       
        require(count <= config.maxMintPerTx, "Exceeds max");
        require(mintedInWallet[msg.sender] + count <= config.maxMint, "Exceeds max");         
        require(msg.value >= config.mintPrice * count, "more eth required");
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);        
    }


    modifier notBots {        
        require(_msgSender() == tx.origin, "no bots");
        _;
    }

    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {        
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");
        require(total + count <= supply, "Exceeds Max Supply");
        _safeMint(to, count);
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Not approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setBaseUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external adminOrOwner {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function toggleGreenlistLive() external adminOrOwner {
        bool isLive = !greenlistLive;
        greenlistLive = isLive;
        emit GreenlistLive(isLive);
    }


    function setGreenlistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        greenlistMerkleRoot = merkleRoot;
    }


    function lowerMaxSupply(uint256 _newmax) external onlyOwner {
        require(_newmax < supply,"Can only lower supply");
        require(_newmax > totalSupply(),"Can't set below current");
        supply = _newmax;
        }



    function setConfig(Config memory _config) external adminOrOwner {
        config = _config;
    }

    function setpayoutAddress(address payable _payoutAddress) external adminOrOwner {
        payoutAddress = _payoutAddress;
    }
     
    function withdraw() external adminOrOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }
}