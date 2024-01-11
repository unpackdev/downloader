// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC1155.sol";

error TWGVMP_FunctionLocked();

contract TheWolfGuildVestingMintPass is ERC1155, AccessControl, Ownable {
    bytes32 public constant TWG_CONTRACT_ROLE = keccak256("TWG_CONTRACT_ROLE");
    string private constant NAME = "The Wolf Guild (Vesting) Mint Pass";
    string private constant SYMBOL = "TWGVMP";

    constructor(string memory _uri) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Mock ERC721 name functionality
     * @return string Token name
     */
    function name() public pure returns (string memory) {
        return NAME;
    }

    /**
     * @notice Mock ERC721 symbol functionality
     * @return string Token symbol
     */
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    /**
     * @notice Set token URI for all tokens
     * @dev More details in ERC1155 contract
     * @param uri base metadata URI applied to token IDs
     */
    function setURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri);
    }

    /**
     * @notice Mint a token to a specified address
     * @param to Address to mint token to
     * @param id Token to mint
     */
    function mint(address to, uint256 id) public onlyRole(TWG_CONTRACT_ROLE) {
        _mint(to, id, 1, "");
    }

    /**
     * @notice Burn a token from a specified address
     * @param from Address to burn token from
     * @param id Token to burn
     */
    function burn(address from, uint256 id) public onlyRole(TWG_CONTRACT_ROLE) {
        _burn(from, id, 1);
    }

    /**
     * @inheritdoc ERC1155
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}