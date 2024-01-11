// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./IERC1155Receiver.sol";

contract FayreSharedCollection1155 is Ownable, ERC1155Burnable, IERC1155Receiver {
    struct MultichainClaimData {
        uint256 timestamp;
        address to;
        uint256 destinationNetworkId;
        address destinationContractAddress;
        uint256 amount;
        string tokenURI;
    }

    event Mint(address indexed owner, uint256 indexed tokenTypeId, uint256 amount, string tokenURI);
    event MultichainTransferFrom(uint256 indexed timestamp, address indexed to, uint256 indexed tokenTypeId, uint256 amount, string tokenURI, uint256 destinationNetworkId, address destinationContractAddress);
    event MultichainClaim(uint256 indexed timestamp, address indexed to, uint256 indexed tokenTypeId, uint256 amount, string tokenURI);

    address public fayreMarketplace;
    mapping(address => bool) public isValidator;
    uint256 public validationChecksRequired;
  
    uint256 private _currentTokenTypeId;
    mapping(uint256 => string) private _tokenTypesURIs;
    uint256 private _networkId;
    mapping(bytes32 => bool) private _isMultichainHashProcessed;

    modifier onlyFayreMarketplace() {
        require(msg.sender == fayreMarketplace, "Only FayreMarketplace");
        _;
    }

    constructor(uint256 networkId_) ERC1155("") { 
        _networkId = networkId_;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
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

    function mint(address recipient, string memory tokenURI, uint256 amount) external onlyFayreMarketplace returns(uint256) {
        require(amount > 0, "Amount needed");

        uint256 tokenTypeId = _currentTokenTypeId++;

        _mint(recipient, tokenTypeId, amount, "");

        _tokenTypesURIs[tokenTypeId] = tokenURI;

        emit Mint(recipient, tokenTypeId, amount, tokenURI);

        return tokenTypeId;
    }

    function multichainTransferFrom(address to, uint256 tokenTypeId, uint256 amount, uint256 destinationNetworkId, address destinationContractAddress) external {
        string memory tokenURI_ = uri(tokenTypeId);

        safeTransferFrom(msg.sender, address(this), tokenTypeId, amount, '');

        burn(msg.sender, tokenTypeId, amount);

        emit MultichainTransferFrom(block.timestamp, to, tokenTypeId, amount, tokenURI_, destinationNetworkId, destinationContractAddress);
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

        uint256 mintTokenTypeId = _currentTokenTypeId++;

        _mint(multichainClaimData.to, mintTokenTypeId, multichainClaimData.amount, "");

        _tokenTypesURIs[mintTokenTypeId] = multichainClaimData.tokenURI;

        emit Mint(multichainClaimData.to, mintTokenTypeId, multichainClaimData.amount, multichainClaimData.tokenURI);

        emit MultichainClaim(multichainClaimData.timestamp, multichainClaimData.to, mintTokenTypeId, multichainClaimData.amount, multichainClaimData.tokenURI);
    
        return mintTokenTypeId;
    }

    function uri(uint256 tokenTypeId) public view override returns (string memory) {
        return _tokenTypesURIs[tokenTypeId];
    }

    function burn(address account, uint256 id, uint256 value) public override {
        super.burn(account, id, value);

        delete _tokenTypesURIs[id]; 
    }
}