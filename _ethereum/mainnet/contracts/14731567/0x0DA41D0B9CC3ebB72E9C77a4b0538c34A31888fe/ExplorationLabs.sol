// SPDX-License-Identifier: MIT

/*
............EXLABS.............
Building for future generations
..PROGRESSUS EST SACRIFICIUM...
...............................
**/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ExploreToken.sol";

contract ExplorationLabs is ERC721A, Pausable, Ownable, ReentrancyGuard {
    
    using ECDSA for bytes32;
    using Strings for uint256;
    enum SaleType { INACTIVE, PIONEER_PASS, PRESALE, GENERAL }

    SaleType saleType = SaleType.INACTIVE;

    string private baseTokenURI;

    uint256 public cost = 0.10 ether;
    uint256 public pioneerPassCost = 0.129 ether;
    uint256 public maxSupply = 5000;
    uint256 public preSaleMaxSupply = 4500;
    uint256 public pioneerPassMaxSupply = 500;
    uint256 public maxMintAmt = 20;
    uint256 public pioneerPassMaxMintAmt = 1;

    address private _signerAddress;
    bool private signerActive = true;
    address private paymentAddress;
    address private royaltyAddress;
    uint96 private royaltyBasisPoints = 500;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    
    address ExploreTokenAddr;
    IExploreToken public exploreToken;
    
    constructor(
        address signerAddress_
    ) ERC721A("ExplorationLabs", "EXL") {
        _signerAddress = signerAddress_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString())) : "";
    }

    function mint(uint256 _quantity, bytes calldata signature) external payable {
        require(saleType != SaleType.INACTIVE);
        require(tx.origin == msg.sender, "Must be called by a user");
        require(_quantity > 0, "Must mint at least 1");

        if(signerActive) {
            require(_signerAddress == keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(uint256(uint160(msg.sender)))
                )
            ).recover(signature), "Signer address mismatch");  
        }

        uint256 _maxMintAmt = maxMintAmt;
        uint256 _maxSupply = maxSupply;
        uint256 _cost = cost;

        if(saleType == SaleType.PIONEER_PASS) {
            _maxMintAmt = pioneerPassMaxMintAmt;
            _maxSupply = pioneerPassMaxSupply;
            _cost = pioneerPassCost;
        } else if(saleType == SaleType.PRESALE) {
            _maxSupply = preSaleMaxSupply;
        }

        require(_numberMinted(msg.sender) + _quantity <= _maxMintAmt, "Attempted to mint more than allowed per address");
        require(totalSupply() + _quantity <= _maxSupply, "Mint limit reached");
        require(msg.value >= _cost * _quantity, "Ether value sent is incorrect"); 

        _safeMint(msg.sender, _quantity);

        exploreToken.updateRewardOnMint(msg.sender);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Mint limit reached");

        _safeMint(msg.sender, _quantity);

        exploreToken.updateRewardOnMint(msg.sender);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function ownedTokensByAddress(address owner) external view returns (uint256[] memory) {
        uint256 totalTokensOwned = balanceOf(owner);
        uint256[] memory allTokenIds = new uint256[](totalTokensOwned);

        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIds[i] = (tokenOfOwnerByIndex(owner, i));
        }

        return allTokenIds;
    }

    function getMsg() public view returns(string memory) {
        return exploreToken.checkMsg();
    }

    function mintEXPReward() external {
		exploreToken.mintReward(msg.sender);
	}

    function transferFrom(address from, address to, uint256 tokenId) public override {
		exploreToken.updateReward(from, to);
		ERC721A.transferFrom(from, to, tokenId);
	}

    function setExploreTokenAddr (address exploreTokenaddress) external onlyOwner {
        ExploreTokenAddr = exploreTokenaddress;
        exploreToken = IExploreToken(ExploreTokenAddr);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPresaleMaxSupply(uint256 _presaleMaxSupply) external onlyOwner {
        preSaleMaxSupply = _presaleMaxSupply;
    }

    function setSignerActive(bool _signerActive) external onlyOwner {
        signerActive = _signerActive;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setPioneerPassCost(uint256 _newPioneerPassCost) external onlyOwner {
        pioneerPassCost = _newPioneerPassCost;
    }

    function setPioneerPassMaxSupply(uint256 _newPioneerPassMaxSupply) external onlyOwner {
        pioneerPassMaxSupply = _newPioneerPassMaxSupply;
    }

    function setPioneerPassMaxMintAmt(uint256 _newPioneerPassMaxMintAmt) external onlyOwner {
        pioneerPassMaxMintAmt = _newPioneerPassMaxMintAmt;
    }

    function getSaleType() external view returns (SaleType) {
        return saleType;
    }

    function inactiveSaleOpen() external onlyOwner {
        saleType = SaleType.INACTIVE;
    }

    function pioneerPassSaleOpen() external onlyOwner {
        saleType = SaleType.PIONEER_PASS;
    }

    function presaleOpen() external onlyOwner {
        saleType = SaleType.PRESALE;
    }

    function generalSaleOpen() external onlyOwner {
        saleType = SaleType.GENERAL;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPaymentAddress(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function getMissionStatement() external pure returns (string memory) {
        return "Building For Future Generations";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal whenNotPaused override(ERC721A) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(paymentAddress).call{
            value: address(this).balance
        }("");
        
        require(success, "Transfer failed");
    }
}
