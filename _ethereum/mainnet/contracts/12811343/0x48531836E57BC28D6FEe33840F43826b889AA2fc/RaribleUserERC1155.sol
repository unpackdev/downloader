// SPDX-License-Identifier: MIT
// this is copied from RaribleUserToken
// https://rinkeby.etherscan.io/address/0xb7622dc2f054d46fcd4bb4d52ac6db3cd8464a6c#code
// modified by TART-tokyo

pragma solidity =0.8.6;

import "./ECDSA.sol";
import "./RaribleERC1155.sol";

contract RaribleUserERC1155 is RaribleERC1155 {

    struct Fee {
        address payable recipient;
        uint256 value;
    }

    string public tokenURIPrefix = "ipfs:/";
    mapping(uint256 => string) private tokenMetadataCidList;

    constructor(
        address creator,
        address signer,
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        address payable[] memory commonRoyaltyAddresses,
        uint256[] memory commonRoyalties
    )
    RaribleERC1155(
        creator,
        signer,
        _name,
        _symbol,
        "",
        contractURI,
        commonRoyaltyAddresses,
        commonRoyalties
    ) {}

    function mint(
        uint256 id,
        uint8 v,
        bytes32 r,
        bytes32 s,
        Fee[] memory fees,
        uint256 amount,
        string memory metadataCidStartsWithSlashIPFSSlash
    ) public virtual onlyOwner {
        require(!exists(id), "already minted");

        _setMetadataCid(id, metadataCidStartsWithSlashIPFSSlash);
        
        address payable[] memory royaltyAddresses = new address payable[](fees.length);
        uint256[] memory royalties = new uint256[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) { 
            royaltyAddresses[i] = fees[i].recipient;
            royalties[i] = fees[i].value;
        }

        _setRoyaltiesOf(id, royaltyAddresses, royalties);

        _mint(msg.sender, id, amount, "");
    }

    function exists(uint256 id) public view returns (bool) {
        return
        keccak256(abi.encodePacked(tokenMetadataCidList[id]))
        != keccak256(abi.encodePacked(""));
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "undefined token");

        return string(abi.encodePacked(tokenURIPrefix, tokenMetadataCidList[id]));
    }

    function setTokenURIPrefix(string memory newPrefix) external onlyOwner {
        tokenURIPrefix = newPrefix;
    }

    function setCommonRoyalty(
        address payable[] memory commonRoyaltyAddresses,
        uint256[] memory commonRoyaltiesWithTwoDecimals
    ) external onlyOwner {
        _setCommonRoyalties(commonRoyaltyAddresses, commonRoyaltiesWithTwoDecimals);
    }

    function setRoyaltyOf(
        uint256 id,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external onlyOwner {
        _setRoyaltiesOf(id, _royaltyAddresses, _royaltiesWithTwoDecimals);
    }

    function setBatchRoyaltyOf(
        uint256[] memory ids,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) { 
            _setRoyaltiesOf(ids[i], _royaltyAddresses, _royaltiesWithTwoDecimals);
        }
    }

    function _setMetadataCid(uint256 id, string memory tokenMetadataCid) internal {
        require(
            keccak256(abi.encodePacked(tokenMetadataCid)) != keccak256(abi.encodePacked("")),
            "empty cid"
        );

        tokenMetadataCidList[id] = tokenMetadataCid;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(RaribleERC1155)
    returns (bool)
    {
        return
        interfaceId == bytes4(keccak256('MINT_WITH_ADDRESS')) ||
        super.supportsInterface(interfaceId);
    }

}
