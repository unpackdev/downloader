// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./LibPart.sol";

contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    address vaultContractAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
    struct RoyaltyInformation {
        address payable receiver;
        uint96 percentageBasisPoints;
    }
    RoyaltyInformation royaltyInformation;

    constructor() public ERC721("Cryptonauts", "Cryptonauts") {}

    function contractURI() public view returns (string memory) {
        return "ipfs://QmVEkViW5R8VQLr4t4jGgA9hQpou9hzhS9wU2S46Mrdaxp";
    }

    function setRoyaltyDetails(address payable _defaultRoyaltyReceiver, uint96 _defaultPercentageBasisPoints)
        public
        onlyOwner
        returns (bool)
    {
        royaltyInformation.receiver = _defaultRoyaltyReceiver;
        royaltyInformation.percentageBasisPoints = _defaultPercentageBasisPoints;
        return true;
    }

    function getRoyaltyDetails() public view returns (address payable, uint96) {
        return (royaltyInformation.receiver, royaltyInformation.percentageBasisPoints);
    }

    function setVaultContract(address _vaultContract) public onlyOwner returns (bool) {
        require(vaultContractAddress == address(0), "VAULT IS ALREADY SET");
        vaultContractAddress = _vaultContract;
        return true;
    }

    function getVaultContract() public view returns (address) {
        return vaultContractAddress;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function burn(uint256 _tokenId) public returns (bool) {
        require(msg.sender == ownerOf(_tokenId) || msg.sender == vaultContractAddress, "NOT OWNER OR VAULT");

        _burn(_tokenId);
        return true;
    }

    function mintPrivileged(address _recipientAddress, string memory _tokenURI) public onlyOwner returns (uint256) {
        uint256 newUniqueId = tokenIds.current();

        _mint(_recipientAddress, newUniqueId);
        _setTokenURI(newUniqueId, _tokenURI);

        tokenIds.increment();

        return newUniqueId;
    }

    function bulkMintPrivileged(address[] memory _recipientAddresses, string[] memory _tokenURIs)
        public
        onlyOwner
        returns (uint256[] memory)
    {
        require(_recipientAddresses.length == _tokenURIs.length, "ARRAY SIZE MISMATCH");

        uint256[] memory newUniqueIds = new uint256[](_recipientAddresses.length);

        for (uint256 i = 0; i < _recipientAddresses.length; i++) {
            newUniqueIds[i] = mintPrivileged(_recipientAddresses[i], _tokenURIs[i]);
        }

        return newUniqueIds;
    }

    function totalSupply() public view returns (uint256) {
        return tokenIds.current();
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721) returns (bool) {
        if (_interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (_interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(_interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyInformation.receiver, (_salePrice * royaltyInformation.percentageBasisPoints) / 10000);
    }

    function getRaribleV2Royalties(uint256 _id) external view returns (LibPart.Part[] memory) {
        // We ignore the ID since we want to use a global royalty fee

        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyInformation.percentageBasisPoints;
        _royalties[0].account = royaltyInformation.receiver;
        return _royalties;
    }
}
