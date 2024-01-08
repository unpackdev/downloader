// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract PartyApesV2 is ERC721, Ownable, ERC721Burnable {
    
    using Strings for uint256;
    mapping (uint256 => string) private _tokenURIs;    
    mapping(uint256 => uint256) private assignOrders;

    string private _baseURIextended;
    address public beneficiary;
    address public USDC;
    uint256 public mintFee;                 // USDC has 6 decimal, please careful, when setting the fee
    uint256 public maxToken = 460;
    uint256 public apesRemainingToAssign = 0;
    uint256 mintedCount = 0;
    uint256[] mintedNumber;
    uint256 _randomNonce = 0;

    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);

    constructor(address _owner, uint256 _mintFee, string memory _tokenURIPrefix, address _beneficiary, address _usdc) ERC721("PartyApesV2", "pApesV2")  {
        transferOwnership(_owner);
        mintFee = _mintFee;
        _baseURIextended = _tokenURIPrefix;
        beneficiary = _beneficiary;
        USDC = _usdc;
        apesRemainingToAssign = maxToken;
    }

    function mint() external {
        require(apesRemainingToAssign > 0, "No remainig apes");
        require(IERC20(USDC).balanceOf(caller()) >= mintFee, "Mint:: Insufficient Balance");
        require(transferMintFee() == true, "Mint:: Transfer Failed");        
        uint256 _randomIndex = _random() % apesRemainingToAssign;
        uint256 apesIndex = _fillAssignOrder(--apesRemainingToAssign, _randomIndex);
        require(!_exists(apesIndex), "Mint: token already minted");
        _safeMint(apesIndex);
    }

    function _safeMint(uint256 _id) internal {
        _mint(caller(), _id);
        _setTokenURI(_id, string(abi.encodePacked(_baseURI(), _id)));
        mintedCount++;
        mintedNumber.push(_id);
        
    }

    function totalSupply() public view virtual returns (uint256) {
        return mintedCount;
    }

    function _random() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(_msgSender())))) / block.timestamp) + block.number))) / apesRemainingToAssign;
    }

    function caller() internal view returns(address) {
        return msg.sender;
    }

    function transferMintFee() internal returns(bool) {
        return IERC20(USDC).transferFrom(caller(), beneficiary, mintFee);
    }

    function changeMintFee(uint256 _newFee) external onlyOwner {
        mintFee = _newFee;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "_setTokenURI: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "tokenURI: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    function returnAllMinted() external view onlyOwner returns (uint256[] memory) {
        return mintedNumber;
    }

    function _fillAssignOrder(uint256 orderA, uint256 orderB) internal returns(uint256) {
        uint256 temp = orderA;
        if (assignOrders[orderA] > 0) temp = assignOrders[orderA];
        assignOrders[orderA] = orderB;
        if (assignOrders[orderB] > 0) assignOrders[orderA] = assignOrders[orderB];
        assignOrders[orderB] = temp;
        return assignOrders[orderA];
    }

    function updateBeneficiary(address payable _newBeneficiary) external onlyOwner {
        require(
            _newBeneficiary != address(0),
            "UpdateBeneficiary:: New Beneficiary can not be Zero Address"
        );
        address _oldBeneficiary = beneficiary;
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(_oldBeneficiary, _newBeneficiary);
    }
}