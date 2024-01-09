// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";
import "./Counters.sol";

import "./ERC721Tradable.sol";

/**
 * @title ARA NFTs
 * Base contract to create and distribute rewards to the ARA community
 */
contract ARA is ERC721Tradable {
    using Address for address;
    using Counters for Counters.Counter;

    // ============================== Variables ===================================
    address ownerAddress;

    // Count of tokenID
    Counters.Counter private tokenIdCount;

    // Metadata setter and locker
    string private metadataTokenURI;
    bool private lock;

    // ============================== Constants ===================================
    /// @notice Price to mint the NFTs
    uint256 public constant price = 4e16;

    /// @notice Max tokens supply for this contract
    uint256 public constant maxSupply = 10000;

    /// @notice Max tokens per transactions
    uint256 public constant maxPerTx = 20;

    /// @notice Max number of tokens available during first round
    uint256 public constant roundOneSupply = 1000;

    /// @notice Max number of tokens available during second round
    uint256 public constant roundTwoSupply = 4000;

    /// @notice End of Sale period (in Unix second)
    uint256 public mintEndDate = 1643486400;    

    // ============================== Constructor ===================================

    /// @notice Constructor of the NFT contract
    /// Takes as argument the OpenSea contract to manage sells
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("ApeRacingAcademy NFTs", "ARANFTs", _proxyRegistryAddress)
    {
        metadataTokenURI = "https://aperacingacademy-metadata.herokuapp.com/metadata/";

        lock = false;        

        address[321] memory owners = [
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0xa684CfC51bf2d794cf197c35f3377F117BF10b6f,
            0x9CD368D315e7c5A16Ee27f558937aa236b4aA509,
            0x9CD368D315e7c5A16Ee27f558937aa236b4aA509,
            0x9CD368D315e7c5A16Ee27f558937aa236b4aA509,
            0x9CD368D315e7c5A16Ee27f558937aa236b4aA509,
            0x9CD368D315e7c5A16Ee27f558937aa236b4aA509,
            0x9CD368D315e7c5A16Ee27f558937aa236b4aA509,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xB6722ac207E297DDfa22efb8CF2308c949DB9491,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0xF13abD73FbB95effA1064E81951cE8E8b9f85e4E,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x326f54A215957F3DF5BC543384E84a7e6D97c854,
            0x326f54A215957F3DF5BC543384E84a7e6D97c854,
            0x326f54A215957F3DF5BC543384E84a7e6D97c854,
            0x715016a375285913D4B900ba616FDeE2B84adc67,
            0x715016a375285913D4B900ba616FDeE2B84adc67,
            0x715016a375285913D4B900ba616FDeE2B84adc67,
            0x89b3d1732848F06311794764977227fb1DE3E9e0,
            0x89b3d1732848F06311794764977227fb1DE3E9e0,
            0x89b3d1732848F06311794764977227fb1DE3E9e0,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0x8195fCB431ec1c21Fa88AfB4523590eD5a843C0f,
            0x1531D777f2fd79C43962f7d7d7DeA43dFa1F1f82,
            0x8DDFD27233772D507cACd8CC6104339f835810eA,
            0x4e1686BEdCF7B4f21B40a032cf6E7aFBbFaD947B,
            0xfAfd2cAf198738955759b1F8796b028362788218,
            0xfAfd2cAf198738955759b1F8796b028362788218,
            0xfAfd2cAf198738955759b1F8796b028362788218,
            0x34b053eF850f952c08bB2b35aD2efe6aF65905c4,
            0xc220245C3c6daf514059899d9abbEc8C3f5F6b45,
            0xc220245C3c6daf514059899d9abbEc8C3f5F6b45,
            0xc220245C3c6daf514059899d9abbEc8C3f5F6b45,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0x93107B05Ff39f13386eB5914DB1C89AA50a9686F,
            0x7ddBaeFa8c2B776D8D824e8e9E55423710A3A331,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xd84d2c87117f63200733B17fC4059184FFCE8bDD,
            0xc5516E6A36E4b04c08058b5b15e52Afb0449D839,
            0x8Db37586B2CA5dBB973880d742CDEAF230C95F6b,
            0x1B01946011B570016a1E3DfC158C6E6D831b662F,
            0x1B01946011B570016a1E3DfC158C6E6D831b662F,
            0x1B01946011B570016a1E3DfC158C6E6D831b662F,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0xCbD6f15627ec214334e7A2B549261B3eed1B276D,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xb8bc7c5d14Fecb0b38966588D9DC042e3540b323,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xB1a149b2741F97Ea1d18e95b7C01500ED9FEc28b,
            0xF2BAB210FFF4a51B135eef656888195ea4fE2658,
            0x27Bd30CAA43632079c2eF59FD418A019CAd82576,
            0x27Bd30CAA43632079c2eF59FD418A019CAd82576,
            0x27Bd30CAA43632079c2eF59FD418A019CAd82576,
            0xAd565B3B1713bc9F99297F7654522bd3f109603F,
            0xAd565B3B1713bc9F99297F7654522bd3f109603F,
            0xAd565B3B1713bc9F99297F7654522bd3f109603F,
            0x8053a1E8522659c7f06D97B2E3732C79FB3A8E84,
            0x8053a1E8522659c7f06D97B2E3732C79FB3A8E84,
            0x8053a1E8522659c7f06D97B2E3732C79FB3A8E84,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xD8AEcA57968cd97D8f622950C36Ae04d86D735C2,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0x639E25c229Ee7a272f3aAC41dBfADB4ae0382651,
            0x639E25c229Ee7a272f3aAC41dBfADB4ae0382651,
            0x639E25c229Ee7a272f3aAC41dBfADB4ae0382651,
            0x639E25c229Ee7a272f3aAC41dBfADB4ae0382651,
            0x639E25c229Ee7a272f3aAC41dBfADB4ae0382651,
            0x639E25c229Ee7a272f3aAC41dBfADB4ae0382651,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xB1a149b2741F97Ea1d18e95b7C01500ED9FEc28b,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0x369d78d707909bFE5168891Cf024fc979Aea84C6,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0xF9C1e03c61BEaE7A2059371E503cBBb358983662,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x09bC3EC3b527a05ff994cc0A3E95b7b490007d74,
            0x09bC3EC3b527a05ff994cc0A3E95b7b490007d74,
            0x09bC3EC3b527a05ff994cc0A3E95b7b490007d74,
            0xDDcB509Fe6E15ec45a35492686947afF08BF58E1,
            0x9f5EB697C22a1E0bb3f36F3CC01718890eBd7a70,
            0x97D64bc9b8Ab086eC54981486001Aad6a2FD04Bc,
            0x97D64bc9b8Ab086eC54981486001Aad6a2FD04Bc,
            0x97D64bc9b8Ab086eC54981486001Aad6a2FD04Bc,
            0x66F02e34Ce51397D9eCEe0bec87E09Ef9d67993e,
            0x66F02e34Ce51397D9eCEe0bec87E09Ef9d67993e,
            0x66F02e34Ce51397D9eCEe0bec87E09Ef9d67993e,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0xf4b20EE9FC63AC1a23B6576fAe3aEbA0eCAcaFb5,
            0x882551f14bE4f028A46886beE2E3D65D405eBd54,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0x3fC3fAc93DfDF1E30E24901A6995a73ea6470CA3,
            0xB1a149b2741F97Ea1d18e95b7C01500ED9FEc28b,
            0xB1a149b2741F97Ea1d18e95b7C01500ED9FEc28b,
            0xB1a149b2741F97Ea1d18e95b7C01500ED9FEc28b,
            0xc5516E6A36E4b04c08058b5b15e52Afb0449D839,
            0xeb77045939E3FaFB19eCa0389f343fB19a052DFe,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0x210Fa5a3360E7a1196115CCa19DE877c9F1176cD,
            0x8A662257c29f101D10f8C804F5b7aA6F2b33da2b,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0x678e9f801b8b36f940578cc69D704Cd2b36Ea93a,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0xF66F1663A2d8059b9C4d1D5260d7d2E5d7fEBD69,
            0x32eF07d66DcB3167f1d195c08dbF634EEAF616DD,
            0x32eF07d66DcB3167f1d195c08dbF634EEAF616DD,
            0x32eF07d66DcB3167f1d195c08dbF634EEAF616DD,
            0xaf86DeC847b771d8F3cCA4Bf591b42a4fDe55571,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x97b2E43Ede1a70869c51c95e6b7DACF2b4f9EaE5,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0x1Fa7E1CDe42c480E5AFeA18Caef18aE7d8965963,
            0xb99826b4e4CbEd0e194A2cc35E932Ac4b6068eD6,
            0xb99826b4e4CbEd0e194A2cc35E932Ac4b6068eD6,
            0xb99826b4e4CbEd0e194A2cc35E932Ac4b6068eD6,
            0xaf86DeC847b771d8F3cCA4Bf591b42a4fDe55571,
            0xE693ce48bCFa8f885369F94EcAB82707C359E067,
            0xE693ce48bCFa8f885369F94EcAB82707C359E067,
            0xE693ce48bCFa8f885369F94EcAB82707C359E067,
            0xE693ce48bCFa8f885369F94EcAB82707C359E067,
            0xE693ce48bCFa8f885369F94EcAB82707C359E067,
            0xE693ce48bCFa8f885369F94EcAB82707C359E067,
            0x8F71C40b8245dA586891FF83461666746ADdf8B1,
            0xa6713D4BDD10455F326C00d70422eBD03ee99f8a,
            0x8DDFD27233772D507cACd8CC6104339f835810eA,
            0xD28E640D3eBEAB2566CE0a60C772E243398Ec356,
            0xa5ceaf97FEBA032cC0767428c32dE9Be7b13c98B,
            0xBE943cCe81A762B28606bf67Fd80C41a0Db4FEf8,
            0x150497b7c5842a62a6dcE6ffA85563881c2d06F6,
            0x150497b7c5842a62a6dcE6ffA85563881c2d06F6,
            0x150497b7c5842a62a6dcE6ffA85563881c2d06F6,
            0x3fC3fAc93DfDF1E30E24901A6995a73ea6470CA3,
            0x150497b7c5842a62a6dcE6ffA85563881c2d06F6            
        ];

        for (uint256 i = 0; i < originalSupply; i++) {
            address owner = owners[i];
            emit Transfer(address(0), owner, i + 1);
            emit Transfer(address(0), owner, originalSupply + i + 1);
            emit Transfer(address(0), owner, 2 * originalSupply + i + 1);
        }

        for (uint256 i = 9850; i < 10000; i++) {
            address owner = 0xa9b2D3089324f1c24f998eEA60B5fD2B08b9d656;
            emit Transfer(address(0), owner, i + 1);
        }

        tokenIdCount._value = originalSupply * 3;
    }

    // ============================== Functions ===================================

    /// @notice Returns the url of the servor handling token metadata
    /// @dev Can be changed until the boolean `lock` is set to true
    function baseTokenURI() public view override returns (string memory) {
        return metadataTokenURI;
    }

    // ============================== Public functions ===================================

    /// Return the amount of token minted, taking into account for the boost
    /// @param amount of token the msg.sender paid for
    function nitroBoost(uint256 amount) internal view returns (uint256) {
        uint256 globalAmount = amount;
        if (tokenIdCount._value < roundOneSupply) {
            globalAmount = uint256((globalAmount * 150) / 100);
        } else if (tokenIdCount._value < roundTwoSupply) {
            globalAmount = uint256((globalAmount * 125) / 100);
        }
        return globalAmount;
    }

    /// @notice Mints `tokenId` and transfers it to message sender
    /// @param amount Number tokens to mint
    function mint(uint256 amount) external payable {
        require(msg.value >= price * amount, "Incorrect amount sent");
        require(amount <= maxPerTx, "Limit to 20 tokens per transactions");

        uint256 boostedAmount = nitroBoost(amount);
        for (uint256 i = 0; i < boostedAmount; i++) {
            if (tokenIdCount._value < 9850) {
                tokenIdCount.increment();
                _mint(msg.sender, tokenIdCount.current());
            }
        }
    }

    // ============================== Governor ===================================

    /// @notice Change the metadata server endpoint to final ipfs server
    /// @param ipfsTokenURI url pointing to ipfs server
    function serve_IPFS_URI(string memory ipfsTokenURI) external onlyOwner {
        require(!lock, "Metadata has been locked and cannot be changed anymore");
        metadataTokenURI = ipfsTokenURI;
    }

    /// @notice Lock the token URI, no one can change it anymore
    function lock_URI() external onlyOwner {
        lock = true;
    }

    /// @notice Prepare mutation
    function mutant_setter(uint256 launchDate) external onlyOwner {
        mintEndDate = launchDate;
    }

    /// @notice Recovers any ERC20 token (wETH, USDC) that could accrue on this contract
    /// @param tokenAddress Address of the token to recover
    /// @param to Address to send the ERC20 to
    /// @param amountToRecover Amount of ERC20 to recover
    function withdrawERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(to, amountToRecover);
    }

    /// @notice Recovers any ETH that could accrue on this contract
    /// @param to Address to send the ETH to
    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    /// @notice Makes this contract payable
    receive() external payable {}

    // ============================== Internal Functions ===================================

    /// @notice Mints a new token
    /// @param to Address of the future owner of the token
    /// @param tokenId Id of the token to mint
    /// @dev Checks that the totalSupply is respected, that
    function _mint(address to, uint256 tokenId) internal override {
        require(tokenId < maxSupply, "Reached minting limit");
        require(block.timestamp < mintEndDate, "End of Sale");
        super._mint(to, tokenId);
    }
}
