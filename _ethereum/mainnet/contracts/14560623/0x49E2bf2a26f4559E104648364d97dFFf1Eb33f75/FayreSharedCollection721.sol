// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./IERC721Receiver.sol";

contract FayreSharedCollection721 is Ownable, ERC721URIStorage, ERC721Burnable, IERC721Receiver{
    struct MultichainClaimData {
        uint256 timestamp;
        address to;
        uint256 destinationNetworkId;
        address destinationContractAddress;
        string tokenURI;
    }

    event Mint(address indexed owner, uint256 indexed tokenId, string tokenURI);
    event MultichainTransferFrom(uint256 indexed timestamp, address indexed to, uint256 indexed tokenId, string tokenURI, uint256 destinationNetworkId, address destinationContractAddress);
    event MultichainClaim(uint256 indexed timestamp, address indexed to, uint256 indexed tokenId, string tokenURI);

    address public fayreMarketplace;
    mapping(address => bool) public isValidator;
    uint256 public validationChecksRequired;

    uint256 private _currentTokenId;
    uint256 private _networkId;
    mapping(bytes32 => bool) private _isMultichainHashProcessed;

    modifier onlyFayreMarketplace() {
        require(msg.sender == fayreMarketplace, "Only FayreMarketplace");
        _;
    }

    constructor(uint256 networkId_) ERC721("FayreSharedCollection721", "FAYRES721") {
        _networkId = networkId_;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function setFayreMarketplace(address newFayreMarketplace) external onlyOwner {
        fayreMarketplace = newFayreMarketplace;
    }

    function setAddressAsValidator(address validatorAddress) external onlyOwner {
        isValidator[validatorAddress] = true;
    }

    function unsetAddressAsValidator(address validatorAddress) external onlyOwner {
        isValidator[validatorAddress] = false;
    }

    function setValidationChecksRequired(uint256 newValidationChecksRequired) external onlyOwner {
        validationChecksRequired = newValidationChecksRequired;
    }

    function mint(address recipient, string memory tokenURI_) external onlyFayreMarketplace returns(uint256) {
        uint256 tokenId = _currentTokenId++;

        _mint(recipient, tokenId);

        _setTokenURI(tokenId, tokenURI_);

        emit Mint(recipient, tokenId, tokenURI_);

        return tokenId;
    }

    function multichainTransferFrom(address to, uint256 tokenId, uint256 destinationNetworkId, address destinationContractAddress) external {
        string memory tokenURI_ = tokenURI(tokenId);

        safeTransferFrom(msg.sender, address(this), tokenId);

        _burn(tokenId);

        emit MultichainTransferFrom(block.timestamp, to, tokenId, tokenURI_, destinationNetworkId, destinationContractAddress);
    }

    function multichainClaim(bytes calldata multichainClaimData_, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external returns(uint256) {
        bytes32 generatedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(multichainClaimData_)));

        uint256 validationChecks = 0;

        for (uint256 i = 0; i < v.length; i++)
            if (isValidator[ecrecover(generatedHash, v[i], r[i], s[i])])
                validationChecks++;

        require(validationChecks >= validationChecksRequired, "Not enough validation checks");
        require(!_isMultichainHashProcessed[generatedHash], "Message already processed");

        MultichainClaimData memory multichainClaimData = abi.decode(multichainClaimData_, (MultichainClaimData));

        require(multichainClaimData.destinationContractAddress == address(this), "Multichain destination address must be this contract");
        require(multichainClaimData.destinationNetworkId == _networkId, "Wrong destination network id");

        _isMultichainHashProcessed[generatedHash] = true;

        uint256 mintTokenId = _currentTokenId++;

        _mint(multichainClaimData.to, mintTokenId);

        _setTokenURI(mintTokenId, multichainClaimData.tokenURI);

        emit Mint(multichainClaimData.to, mintTokenId, multichainClaimData.tokenURI);

        emit MultichainClaim(multichainClaimData.timestamp, multichainClaimData.to, mintTokenId, multichainClaimData.tokenURI);
    
        return mintTokenId;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns(string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(_tokenId);
    }
}