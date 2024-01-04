pragma solidity ^0.6.0;

import "./ERC721Burnable.sol";
import "./Operator.sol";

pragma solidity ^0.6.0;

contract HayekPlate is ERC721Burnable, Operator {
    using SafeMath for uint256;
    address public nftFeature;

    event FeatureAddrChanged(address indexed oldFeatureAddr, address indexed newFeatureAddr);
    event AirdropIssuerChanged(address indexed oldAirdropIssuer, address indexed newAirdropIssuer);
    event CoreProtocolChanged(address indexed oldCoreProtocol, address indexed newCoreProtocol);

    address public airdropIssuer;
    address public coreProtocol;

    constructor (address _nftFeature) public ERC721("Hayek-Money-NFT", "HayekNFT") {
        nftFeature = _nftFeature;
    }

    modifier onlyAirdropIssuer() {
        require(msg.sender == airdropIssuer, "Not airdropIssuer");
        _;
    }

    modifier onlyCoreProtocol() {
        require(msg.sender == coreProtocol, "Not coreProtocol");
        _;
    }

    function setAirdropIssuer(address _airdropIssuer) public onlyOperator {
        address oldAirdropIssuer = _airdropIssuer;
        airdropIssuer = _airdropIssuer;
        emit AirdropIssuerChanged(oldAirdropIssuer, airdropIssuer);
    }

    function setCoreProtocol(address _coreProtocol) public onlyOperator {
        address oldCoreProtocol = coreProtocol;
        coreProtocol = _coreProtocol;
        emit CoreProtocolChanged(oldCoreProtocol, coreProtocol);
    }

    function getOwnerAllNFT(address account) public view returns(uint256[] memory) {
        uint256 length = balanceOf(account);
        uint256[] memory allNFT = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            allNFT[i] = tokenOfOwnerByIndex(account, i);
        }
        return allNFT;
    }

    function setFeatureAddr(address _nftFeature) public onlyOperator {
        address oldNFTFeature = nftFeature;
        nftFeature = _nftFeature;
        emit FeatureAddrChanged(oldNFTFeature, nftFeature);
    }

    function getFeatureAddr() public view returns(address) {
        return nftFeature;
    }

    function setBaseURI(string memory baseURI_) public onlyOperator {
        _setBaseURI(baseURI_);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOperator {
        _setTokenURI(tokenId, _tokenURI);
    }

    function mint(address to, uint256 tokenId)
        public
        onlyOperator
    {
        _mint(to, tokenId);
    }

    function merge(address to, uint256 tokenId)
        public
        onlyCoreProtocol
    {
        _mint(to, tokenId);
    }

    function issueAirdrop(address to, uint256 tokenId)
        public
        onlyAirdropIssuer
    {
        _mint(to, tokenId);
    }

    function transfer(address to, uint256 tokenId)
        public
    {
        safeTransferFrom(msg.sender, to, tokenId);
    }

    function batchTransfer(address to, uint256[] memory tokenId)
        public
    {
        for (uint256 i = 0; i < tokenId.length; i++) {
            safeTransferFrom(msg.sender, to, tokenId[i]);
        }
    }
}