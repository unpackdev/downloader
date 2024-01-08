//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";

/// @title Eth Bot Statue NFT Contract
/// @author jaxcoder, ghostffcode
/// @notice
/// @dev ethbotstatue contract owned by greatestlarp contract
contract EthBotStatue is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public lastMinted = 0;

    string[] private uris;

    // this lets you look up a token by the uri (assuming there is only one of each uri for now)
    mapping(bytes32 => uint256) public uriToTokenId;

    constructor() ERC721("Eth Bot Statue", "ETHBOTSTAT") {
        uris = [
            "ethbot.json",
            "ethbot.json",
            "ethbot.json",
            "ethbot.json",
            "ethbot.json"
        ];
    }

    /// @dev the base uri for the assets
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/QmfSo9qSGfjQLFtkYSjHX1L1ayrFS1SiHYXcMiEpNjgviS/";
    }

    function contractURI() public view returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/QmRxiXjsRkfz86aBNAmLSCqSBmcWXYDGwW5M1VPELE1ZXT/ethbotstatue.json";
    }

    /// @dev what was the last token minted
    function lastMintedToken() external view returns (uint256 id) {
        id = _tokenIds.current();
    }

    /// @dev this is internal mint function
    /// @param to the user that is minting the token address
    /// @param tokenURI the uri for the token being minted
    function mintItem(address to, string memory tokenURI)
        private
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _mint(to, id);
        _setTokenURI(id, tokenURI);

        return id;
    }

    /// @dev public mint function
    /// @param user the users address who is minting
    function mint(address user) external onlyOwner returns (uint256 id) {
        id = _tokenIds.current();
        mintItem(user, uris[id]);
        lastMinted = id;

        return id;
    }
}
