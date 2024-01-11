// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*
 8888888b.  8888888888 888b     d888 888b    888        d8888 888b    888 88888888888 .d8888b.  
 888   Y88b 888        8888b   d8888 8888b   888       d88888 8888b   888     888    d88P  Y88b 
 888    888 888        88888b.d88888 88888b  888      d88P888 88888b  888     888    Y88b.      
 888   d88P 8888888    888Y88888P888 888Y88b 888     d88P 888 888Y88b 888     888     "Y888b.   
 8888888P"  888        888 Y888P 888 888 Y88b888    d88P  888 888 Y88b888     888        "Y88b. 
 888 T88b   888        888  Y8P  888 888  Y88888   d88P   888 888  Y88888     888          "888 
 888  T88b  888        888   "   888 888   Y8888  d8888888888 888   Y8888     888    Y88b  d88P 
 888   T88b 8888888888 888       888 888    Y888 d88P     888 888    Y888     888     "Y8888P"                                                                                                                                                                                                                                                                                            
 
 *************************************************************************
 * @title: Remnants                                       *
 * @author: @ghooost0x2a                                                 *
 * ERC721B2FA - Ultra Low Gas - 2 Factor Authentication                  *
 *************************************************************************
 * ERC721B2FA is based on ERC721B low gas contract by @squuebo_nft       *
 * and the LockRegistry/Guardian contracts by @OwlOfMoistness            *
 *************************************************************************
 *     :::::::              ::::::::      :::                            *
 *    :+:   :+: :+:    :+: :+:    :+:   :+: :+:                          *
 *    +:+  :+:+  +:+  +:+        +:+   +:+   +:+                         *
 *    +#+ + +:+   +#++:+       +#+    +#++:++#++:                        *
 *    +#+#  +#+  +#+  +#+    +#+      +#+     +#+                        *
 *    #+#   #+# #+#    #+#  #+#       #+#     #+#                        *
 *     #######             ########## ###     ###                        *
 *************************************************************************/

import "./ERC721B2FAEnumLite.sol";
import "./GuardianLiteB2FA.sol";
import "./Address.sol";
import "./Strings.sol";

contract ERC721B2FA_REMNANTS is ERC721B2FAEnumLite, GuardianLiteB2FA {
    using Address for address;
    using Strings for uint256;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    uint256 public MAX_SUPPLY = 42;
    string internal baseURI = "";
    string internal uriSuffix = ".json";
    string internal commonURI = "";

    address private withdrawalAddy;

    constructor() ERC721B2FAEnumLite("REMNANTS", "REM", 1) {}

    fallback() external payable {
        revert("Fallback FN!");
    }

    receive() external payable {}

    //getter fns
    function getWithdrawalAddy() external view onlyDelegates returns (address) {
        return withdrawalAddy;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (bytes(commonURI).length > 0) {
            return string(abi.encodePacked(commonURI));
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }

    //setter fns
    function setCommonURI(string calldata newCommonURI) external onlyDelegates {
        //dev: Set to "" to disable commonURI
        commonURI = newCommonURI;
    }

    function setBaseSuffixURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyDelegates {
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function setWithdrawalAddy(address addy) external onlyDelegates {
        withdrawalAddy = addy;
    }

    function setMaxSupply(uint256 new_max_supply) external onlyDelegates {
        MAX_SUPPLY = new_max_supply;
    }

    // Mint fns
    function ghostyMint(uint256 quantity, address[] calldata recipients)
        external
        onlyDelegates
    {
        minty(quantity, recipients);
    }

    // Internal fns
    function minty(uint256 quantity, address[] calldata recipients) internal {
        require(quantity > 0, "Can't mint 0 tokens!");
        require(
            quantity == recipients.length || recipients.length == 1,
            "Call data is invalid"
        ); // dev: Call parameters are no bueno
        uint256 totSup = totalSupply();
        require(quantity + totSup <= MAX_SUPPLY, "Max supply reached!");

        address mintTo;
        for (uint256 i; i < quantity; i++) {
            mintTo = recipients.length == 1 ? recipients[0] : recipients[i];
            //_safeMint(mintTo, totSup + i + _offset);
            _safeMint(mintTo, next());
        }
    }

    function withdraw() external onlyDelegates {
        uint256 contract_balance = address(this).balance;

        address payable w_addy = payable(withdrawalAddy);

        (bool success, ) = w_addy.call{value: (contract_balance)}("");
        require(success, "Withdrawal failed!");

        emit Withdrawn(w_addy, contract_balance);
    }
}
