// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BeatsOnTheBlockchain is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public MAX_BEATS_SUPPLY = 3333; // Love Always
    string private _contractURI;
    uint256 public beatPrice = 100000000000000000; 
    uint256 public MAX_MINT_AMOUNT = 25; 
    
    string public  baseImageURI;
    string public  animationCodeURI;
    string public  animationURI;

    ProxyRegistry private _proxyRegistry;
    Counters.Counter private _tokenIds;

    mapping(uint256 => bytes32) beatSeed;

    constructor(
        string memory _baseImageURI,
        string memory _animationURI,
        address openseaProxyRegistry_
    ) ERC721("Beats on the Blockchain ", "BOTB") {
        baseImageURI = _baseImageURI;
        animationURI = _animationURI;
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    function mintBeats(uint256 _amount) public payable nonReentrant {
        require(beatPrice.mul(_amount) == msg.value, "Ether value sent is not correct");
        require(_amount <= MAX_MINT_AMOUNT, "Cannot mint more than 25 at a time");
        require((_tokenIds.current() + _amount) <=  MAX_BEATS_SUPPLY, "Mint would exceed max supply of Beats");
        
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            beatSeed[tokenId] = bytes32(keccak256(abi.encodePacked(address(msg.sender), tokenId)));
        }
    }

    function setAnimationCodeURI(string memory newAnimationCodeURI) public onlyOwner {
        animationCodeURI = newAnimationCodeURI;
    }

    function setAnimationURI(string memory newAnimationURI) public onlyOwner {
        animationURI = newAnimationURI;
    }
    
    function setBaseImgURI(string memory newBaseImageURI) public onlyOwner {
        baseImageURI = newBaseImageURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        string memory seed = bytes32ToString(beatSeed[_tokenId]);
        return string(abi.encodePacked('data:application/json;utf8,{"name":"', uint2str(_tokenId), '","animation_url":"', animationURL(seed), '","image":"', baseImgURL(_tokenId), '.png"}'));
    }

    function animationURL(string memory _seed) internal view returns (string memory)
    {
        return string(abi.encodePacked(animationURI, _seed));
    }

    function baseImgURL(uint256  _tokenId) internal view returns (string memory)
    {
        return string(abi.encodePacked(baseImageURI, uint2str(_tokenId)));
    }
 
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes32[i / 2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }
    
    function toByte(uint8 _uint8) public pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function setOpenSeaRegistry(address proxyRegistryAddress)
        external
        onlyOwner
    {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}