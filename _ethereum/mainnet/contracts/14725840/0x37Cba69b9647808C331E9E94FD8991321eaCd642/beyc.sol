//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract BeycNFT is ERC721, Ownable, RoyaltiesV2Impl {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnable;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    mapping(address=>uint256) public walletMints;
    
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() payable ERC721('Bored Elon Yacht Club', 'BEYC') {
        mintPrice = 0.015 ether;
        totalSupply=0;
        maxSupply=500;
        maxPerWallet=10;
        isPublicMintEnable=true;
        withdrawWallet=payable(msg.sender);
    }

    // Pause Unpause Minte
    function setIsPublicMintEnabled(bool _isPublicMintEnable) external onlyOwner {
        isPublicMintEnable = _isPublicMintEnable;
    }

    // baseTokenUri functions
    function setBaseTokenUri(string calldata _baseTokenUri) public onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'Token does not exist');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(_tokenId)));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{ value: address(this).balance}('');
        require(success, 'withdraw failed');
    }

    function mint(uint256 _quantity) public payable {
        require(isPublicMintEnable, 'minting not enabled');
        require(msg.value == _quantity * mintPrice, 'wrong mint value');
        require(totalSupply + _quantity <= maxSupply, 'sold out');        
        require(walletMints[msg.sender] + _quantity <= maxPerWallet, 'exceed max per wallet');

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 newTokenId=totalSupply+1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }

    function updateMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice=_newMintPrice;
    }

    function setTotalSupply(uint256 _newMaxSupply) public onlyOwner {
        require(maxSupply>=totalSupply, 'could not be less than current mints');
        maxSupply=_newMaxSupply;
    }

    function setMaxMintsPerWallet(uint256 _newMaxPerWallet) public onlyOwner {
        maxPerWallet=_newMaxPerWallet;
    }

    // Rarible Royalties
    function setRoyalties(uint256 _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
        }
        return (address(0), 0);

    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
