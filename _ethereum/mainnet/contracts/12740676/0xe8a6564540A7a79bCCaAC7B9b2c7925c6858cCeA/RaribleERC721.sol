// SPDX-License-Identifier: MIT
// this is copied from MintableOwnableToken
// https://etherscan.io/address/0x987a4d3edbe363bc351771bb8abdf2a332a19131#code
// modified by TART-tokyo

pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./HasContractURI.sol";
import "./HasSecondarySaleFees.sol";
import "./SignerRole.sol";

contract RaribleERC721 is Ownable, ERC721Burnable, HasContractURI, HasSecondarySaleFees, SignerRole {
    event CreateERC721_v4(address indexed creator, string name, string symbol);

    constructor(
        address signer,
        string memory name,
        string memory symbol,
        string memory contractURI,
        address payable[] memory commonRoyaltyAddresses,
        uint256[] memory commonRoyalties
    )
    ERC721(name, symbol)
    HasContractURI(contractURI)
    SignerRole()
    HasSecondarySaleFees(commonRoyaltyAddresses, commonRoyalties)
    {
        grantRole(SIGNER_ROLE, signer);
        grantRole(SIGNER_ROLE, msg.sender);

        emit CreateERC721_v4(msg.sender, name, symbol);
    }

    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721, HasContractURI, HasSecondarySaleFees)
    returns (bool)
    {
        return
        AccessControlEnumerable.supportsInterface(interfaceId) ||
        ERC721.supportsInterface(interfaceId) ||
        HasContractURI.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
}
    
