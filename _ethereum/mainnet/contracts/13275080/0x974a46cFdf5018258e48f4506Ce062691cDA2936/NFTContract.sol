// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./NFTBase.sol";
import "./ChainLinkRandom.sol";
import "./ReentrancyGuard.sol";

contract NFTContract is NFTBase, ChainLinkRandom, ReentrancyGuard {
    bool internal revealed;

    constructor(
        address _VRFCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        string memory _blankURI,
        uint256 _supply,
        address _developer
    )
        public
        NFTBase(_blankURI, _supply, _developer)
        ChainLinkRandom(_VRFCoordinator, _LINKToken, _keyHash)
    {}

    /**
     * @dev reveal metadata of tokens.
     * @dev only can call one time, and only owner can call it.
     * @dev function will request to chainlink oracle and receive random number.
     * @dev contract will get this number by fulfillRandomness function.
     * @dev You should transfer 2 LINK token to contract, before call this function
     */
    function reveal() public onlyOwner {
        require(!revealed, "You have already generated a random seed");
        require(bytes(baseURI()).length > 0, "You should set baseURI first");
        revealed = true;
        _generateRandomSeed();
    }

    /**
     * @dev query metadata id of token
     * @notice only know after owner owner create `seed`
     * @param tokenId The id of token you want to query
     */
    function metadataOf(uint256 tokenId) internal view returns (string memory) {
        if (seed == 0) return "";

        uint256[] memory metaIds = new uint256[](DSA_SUPPLY);

        for (uint256 i = 0; i < DSA_SUPPLY; i++) {
            metaIds[i] = i;
        }

        // shuffle meta id
        for (uint256 i = beginRandomIndex; i < DSA_SUPPLY; i++) {
            uint256 j = shuffleId(DSA_SUPPLY, i, beginRandomIndex);
            (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
        }

        return metaIds[tokenId].toString();
    }

    /**
     * @dev query tokenURI of token Id
     * @dev before reveal will return default URI
     * @dev after reveal return token URI of this token on IPFS
     * @param tokenId The id of token you want to query
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistant token"
        );

        if (tokenId < beginRandomIndex)
            return
                string(abi.encodePacked(celebTokenBaseURI, tokenId.toString()));

        // before reveal, nobody know what happened. Return _blankURI
        if (seed == 0) {
            return blankURI;
        }

        // after reveal, you can know your know.
        return string(abi.encodePacked(baseURI(), metadataOf(tokenId)));
    }

    /**
     * @dev mint token in sale period
     */
    function mintTokenOnSale(uint256 numberToken)
        external
        payable
        nonReentrant
        canMintOnSale(numberToken)
        mintable(numberToken)
    {
        _mintToken(_msgSender(), numberToken);
    }

    /**
     * @dev mint token in pre sale period
     */
    function mintTokenOnPreSale(uint256 numberToken)
        external
        payable
        nonReentrant
        mintable(numberToken)
    {
        _mintPreSale(_msgSender(), numberToken);
    }
}
