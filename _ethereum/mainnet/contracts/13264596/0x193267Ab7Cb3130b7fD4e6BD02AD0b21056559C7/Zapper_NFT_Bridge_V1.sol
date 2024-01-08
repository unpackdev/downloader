// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract bridges Zapper's NFTs from V1 to V2
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC1155Receiver.sol";

interface IZapper_NFT {
    function mint(uint256 id, uint256 quantity) external;

    function craftingRequirement() external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract Zapper_NFT_Bridge_V1 is ERC1155Receiver, Ownable {
    IZapper_NFT public Zapper_NFT_V1;

    IZapper_NFT public Zapper_NFT_V2;

    // Season 1 NFT burn address
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    // Maps the V1 NFT ID to the V2 NFT ID
    mapping(uint256 => uint256) public mintIDs;

    bool public paused;

    modifier pausable {
        require(!paused);
        _;
    }

    constructor(address V1_Address, address V2_Address) {
        Zapper_NFT_V1 = IZapper_NFT(V1_Address);
        Zapper_NFT_V2 = IZapper_NFT(V2_Address);
    }

    /**
     * @notice Bridges and crafts V2 Zapper NFTs from V1 NFTs
     * @dev This is irreversible as tokens are sent to the
     * burn address
     * @param id The ID of the V1 NFT being used in crafting
     * @param quantity The quantity of the V1 NFT being being
     * used in crafting
     */
    function bridgeAndCraft(uint256 id, uint256 quantity) external pausable {
        uint256 mintID = mintIDs[id];
        require(mintID != 0, "Invalid ID");

        uint256 craftingRequirement = Zapper_NFT_V2.craftingRequirement();
        require(
            quantity % craftingRequirement == 0,
            "Incorrect quantity for crafting"
        );

        Zapper_NFT_V1.safeTransferFrom(
            msg.sender,
            BURN_ADDRESS,
            id,
            quantity,
            new bytes(0)
        );

        uint256 mintQuantity = quantity / craftingRequirement;

        Zapper_NFT_V2.mint(mintID, mintQuantity);

        Zapper_NFT_V2.safeTransferFrom(
            address(this),
            msg.sender,
            mintID,
            mintQuantity,
            new bytes(0)
        );
    }

    function setMintIDs(uint256[] calldata fromIds, uint256[] calldata toIds)
        external
        onlyOwner
    {
        require(fromIds.length == toIds.length, "Mismatched array lengths");
        for (uint256 i = 0; i < fromIds.length; i++) {
            mintIDs[fromIds[i]] = toIds[i];
        }
    }

    function updateContracts(address V1_Address, address V2_Address)
        external
        onlyOwner
    {
        Zapper_NFT_V1 = IZapper_NFT(V1_Address);
        Zapper_NFT_V2 = IZapper_NFT(V2_Address);
    }

    function pause() external onlyOwner {
        paused = !paused;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}
