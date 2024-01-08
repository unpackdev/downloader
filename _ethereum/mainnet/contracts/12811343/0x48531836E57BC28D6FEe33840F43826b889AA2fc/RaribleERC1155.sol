// SPDX-License-Identifier: MIT
// this is copied from RaribleUserToken
// https://rinkeby.etherscan.io/address/0xb7622dc2f054d46fcd4bb4d52ac6db3cd8464a6c#code
// modified by TART-tokyo

pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./HasContractURI.sol";
import "./HasSecondarySaleFees.sol";
import "./SignerRole.sol";

contract RaribleERC1155 is Ownable, ERC1155Burnable, HasContractURI, HasSecondarySaleFees, SignerRole {
    event CreateERC1155_v1(address indexed creator, string name, string symbol);

    string public name;
    string public symbol;

    constructor(
        address creator,
        address signer,
        string memory _name,
        string memory _symbol,
        string memory tokenURI,
        string memory contractURI,
        address payable[] memory commonRoyaltyAddresses,
        uint256[] memory commonRoyaltiesWithTwoDecimals
    )
    ERC1155(tokenURI)
    HasContractURI(contractURI)
    SignerRole()
    HasSecondarySaleFees(commonRoyaltyAddresses, commonRoyaltiesWithTwoDecimals)
    {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, creator);
        _setupRole(SIGNER_ROLE, creator);
        _setupRole(SIGNER_ROLE, signer);
        renounceRole(SIGNER_ROLE, msg.sender);

        emit CreateERC1155_v1(creator, name, symbol);
    }

    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC1155, HasContractURI, HasSecondarySaleFees)
    returns (bool)
    {
        return
        AccessControlEnumerable.supportsInterface(interfaceId) ||
        ERC1155.supportsInterface(interfaceId) ||
        HasContractURI.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
}
    
