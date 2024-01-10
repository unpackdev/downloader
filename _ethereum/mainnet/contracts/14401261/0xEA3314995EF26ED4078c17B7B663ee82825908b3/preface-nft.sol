// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./Strings.sol";

contract CaffeinatedCoder is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    // in Wei unit
    uint256 public mintPrice;
    address public withdrawWallet;
    string public tokenBaseURI;

    function initialize(
        string memory _tokenBaseURI,
        address _withdrawWallet
    ) initializer public {
        __ERC721_init("Caffeinated Coder", "CFC");
        __ERC721URIStorage_init();
        __Ownable_init();

        // Init variables
        mintPrice = 0.2 ether;
        tokenBaseURI = _tokenBaseURI;
        withdrawWallet = _withdrawWallet;
    }

    // @notice Minting to VIP by contract owner
    /// @param targetAddresses Addresses of VIP(s)
    function mintToVIPs(address[] memory targetAddresses) public onlyOwner {
        for (uint i = 0; i < targetAddresses.length; i++) {
            _mintToMember(targetAddresses[i]);
        }
    }

    // @notice Main function for minting to member
    // @param to Address of target member
    function _mintToMember(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Strings.toString(tokenId));
    }

    // @notice Burn function able to execute by smart contract / NFT owner
    // @param tokenId target Token ID
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(
            owner() == _msgSender() ||
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not NFT owner nor approved");
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
    internal
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        tokenBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Set withdrawal address
    /// @param wallet Address of withdrawal target
    function setWithdrawalWallet(address wallet) external onlyOwner {
        withdrawWallet = wallet;
    }

    /// @notice update NFT Token URI address
    /// @param tokenId NFT token ID
    /// @param uri token URI
    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }
}