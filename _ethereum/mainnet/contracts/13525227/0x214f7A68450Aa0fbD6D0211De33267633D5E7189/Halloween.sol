// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Strings.sol";

/**
 * @title Halloween2021
 * @author twitter.com/sujithsomraaj
 * @dev Distributed on Oct 31, 2021.
 */

contract Halloween2021 is ERC1155, AccessControl, Ownable {
    /// @dev minters only have the ability to mint new halloween tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private localuri;
    uint256 public totalMint = 0;

    ///@dev different types of Halloween Collections.
    uint256 public constant BONEANNOS = 1;
    uint256 public constant COLOMBONES = 2;
    uint256 public constant NAPOLEBONES = 3;
    uint256 public constant GAMBONES = 4;
    uint256 public constant CORLEBONES = 5;
    uint256 public constant RAMBONES = 6;
    uint256 public constant CONTRACT_KILLERS = 7;

    /// @dev sets the URI & ADMIN Role.
    constructor()
        ERC1155(
            "ipfs://QmPvpaeyH9Tz3Qai2oMSRFjccyLVo1LuxSdWu1jvse2RFu/{id}.json"
        )
    {
        localuri = "ipfs://QmPvpaeyH9Tz3Qai2oMSRFjccyLVo1LuxSdWu1jvse2RFu/";
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev mints new tokens.
     * @param user represents the wallet to receive newly minted tokens.
     * @param family represents the token family to mint.
     * @param amount represents the amount of tokens to be minted.
     * @return boolean representing the status of mint.
     */
    function mint(
        address user,
        uint256[] memory family,
        uint256[] memory amount
    ) public virtual onlyRole(MINTER_ROLE) returns (bool) {
        for (uint256 i = 0; i < family.length; i++) {
            totalMint += amount[i];
        }
        /// @dev caps the maximum mint limit to 10,000 NFTs
        require(totalMint <= 10000, "Error: max mint limit reached");
        require(family.length == amount.length, "Error: Invalid Arguments");
        _mintBatch(user, family, amount, "");
        return true;
    }

    /// @dev returns the token URI for opensea standards.
    /// @param _tokenID is the ID of token.
    function tokenURI(uint256 _tokenID) public view returns (string memory) {
        string memory hexstringtokenID;
        hexstringtokenID = uint2hexstr(_tokenID);

        return string(abi.encodePacked(localuri, hexstringtokenID, ".json"));
    }

    function uint2hexstr(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint256 mask = 15;
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            uint256 curr = (i & mask);
            bstr[--k] = curr > 9
                ? bytes1(uint8(55 + curr))
                : bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

    /// @dev overrides the supportsInterface function.
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
