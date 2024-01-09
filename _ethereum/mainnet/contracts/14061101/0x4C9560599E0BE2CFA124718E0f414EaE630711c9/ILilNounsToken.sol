// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

//import "./IERC721.sol";
import "./ILilNounsDescriptor.sol";
import "./INounsSeeder.sol";
import "./INounsToken.sol";

interface ILilNounsToken {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(ILilNounsDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    event NounsTokenUpdated(INounsToken nounsToken);

    event NounsTokenLocked();

    // function mint() external returns (uint256);

    // function burn(uint256 tokenId) external;

    //function dataURI(uint256 tokenId) external returns (string memory);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(address descriptor) external;

    function lockDescriptor() external;

    function setSeeder(address seeder) external;

    function lockSeeder() external;

    function setNounsToken(address nounsToken) external;

    function lockNounsToken() external;
}
